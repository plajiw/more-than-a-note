#include "page_editor_adapter.h"

#include "notebook_store.h"
#include "page_repository.h"

#include <QCryptographicHash>
#include <QPointF>
#include <QUuid>
#include <QVariant>

#include <algorithm>
#include <cmath>
#include <exception>
#include <new>
#include <utility>

using namespace mtn::model;

namespace {
constexpr double pxPerPt = 4.0 / 3.0;
constexpr int maxVisualInkPoints = 50'000;

std::string slotId(const QString& pageId, int slot) {
    QByteArray seed = pageId.toUtf8();
    seed.append(slot == 0 ? "/text/1" : "/text/2");
    QByteArray hash = QCryptographicHash::hash(seed, QCryptographicHash::Sha256).left(16);
    hash[6] = static_cast<char>((static_cast<unsigned char>(hash[6]) & 0x0f) | 0x50);
    hash[8] = static_cast<char>((static_cast<unsigned char>(hash[8]) & 0x3f) | 0x80);
    return QUuid::fromRfc4122(hash).toString(QUuid::WithoutBraces).toStdString();
}

const PageObject* findObject(const PageContent& page, const std::string& id) {
    const auto it = std::find_if(page.objects.begin(), page.objects.end(),
                                 [&](const PageObject& object) { return object.common.id == id; });
    return it == page.objects.end() ? nullptr : &*it;
}

QString plainText(const TextContainer& container) {
    QString value;
    bool first = true;
    for (const auto& paragraph : container.document.paragraphs) {
        if (!first) value += QLatin1Char('\n');
        first = false;
        for (const auto& run : paragraph.runs)
            value += QString::fromUtf8(run.utf8.data(), static_cast<qsizetype>(run.utf8.size()));
    }
    return value;
}

RichTextDocument textDocument(const QString& text) {
    RichTextDocument document;
    const auto lines = text.split(QLatin1Char('\n'), Qt::KeepEmptyParts);
    document.paragraphs.reserve(static_cast<std::size_t>(lines.size()));
    for (const QString& line : lines) {
        RichParagraph paragraph;
        if (!line.isEmpty()) paragraph.runs.push_back({line.toUtf8().toStdString(), {}});
        document.paragraphs.push_back(std::move(paragraph));
    }
    return document;
}

QString storageError(PageStorageStatus status) {
    switch (status) {
    case PageStorageStatus::OutOfMemory: return QStringLiteral("Memória insuficiente para a página.");
    case PageStorageStatus::TooLarge: return QStringLiteral("A página excede o limite desta prova.");
    case PageStorageStatus::UnsupportedContent: return QStringLiteral("Conteúdo ou versão ainda não suportado.");
    case PageStorageStatus::InvalidContent: return QStringLiteral("Conteúdo inválido; nada foi gravado.");
    default: return QStringLiteral("Não foi possível gravar a página.");
    }
}
} // namespace

PageEditorAdapter::PageEditorAdapter(NotebookStore* store, QObject* parent)
    : QObject(parent), store_(store) {
    Q_ASSERT(store_);
    connect(store_, &NotebookStore::selectionChanged, this, &PageEditorAdapter::syncSelection);
}

void PageEditorAdapter::setEnabled(bool enabled) {
    if (enabled_ == enabled) return;
    enabled_ = enabled;
    syncSelection();
}

void PageEditorAdapter::setError(const QString& message) {
    error_ = message;
    emit stateChanged();
}

void PageEditorAdapter::syncSelection() {
    const QString wanted = enabled_ ? store_->activePageId() : QString{};
    if (wanted == pageId_) return;
    pageId_ = wanted;
    session_.reset();
    undoIds_.clear();
    redoIds_.clear();
    text_[0].clear();
    text_[1].clear();
    inkStrokes_.clear();
    inkCount_ = 0;
    error_.clear();
    if (!wanted.isEmpty()) {
        try {
            auto db = store_->activeDatabase();
            auto loaded = loadPageContent(db, wanted);
            if (loaded.status == PageStorageStatus::Ok ||
                loaded.status == PageStorageStatus::LegacyEmpty) {
                session_ = std::make_unique<PageSession>(std::move(loaded.page));
                rebuildVisual();
            } else {
                error_ = storageError(loaded.status);
            }
        } catch (const std::exception&) {
            error_ = QStringLiteral("Não foi possível abrir o conteúdo da página.");
        }
    }
    emit stateChanged();
    emit pageLoaded();
}

void PageEditorAdapter::rebuildVisual() {
    text_[0].clear();
    text_[1].clear();
    inkStrokes_.clear();
    inkCount_ = 0;
    if (!session_) return;
    const auto& page = session_->page();
    const auto firstId = slotId(pageId_, 0);
    const auto secondId = slotId(pageId_, 1);
    int points = 0;
    for (const auto& object : page.objects) {
        if (const auto* text = std::get_if<TextContainer>(&object.payload)) {
            if (object.common.id == firstId) text_[0] = plainText(*text);
            else if (object.common.id == secondId) text_[1] = plainText(*text);
        } else if (const auto* stroke = std::get_if<InkStroke>(&object.payload)) {
            ++inkCount_;
            if (points + static_cast<int>(stroke->points.size()) > maxVisualInkPoints ||
                object.common.transform.rotation_degrees != 0 ||
                object.common.transform.scale_x != 1 || object.common.transform.scale_y != 1) {
                error_ = QStringLiteral("Alguns traços excedem os limites visuais desta prova.");
                continue;
            }
            QVariantList samples;
            samples.reserve(static_cast<qsizetype>(stroke->points.size()));
            for (const auto& point : stroke->points) {
                samples.append(QPointF((point.position.x + object.common.transform.translation.x) * pxPerPt,
                                       (point.position.y + object.common.transform.translation.y) * pxPerPt));
            }
            inkStrokes_.append(QVariant(samples));
            points += static_cast<int>(stroke->points.size());
        }
    }
}

bool PageEditorAdapter::persist(const std::string& objectId) {
    if (!session_) return false;
    auto db = store_->activeDatabase();
    const auto* object = findObject(session_->page(), objectId);
    const PageStorageStatus status = object
        ? savePageObject(db, *object)
        : deletePageObject(db, pageId_, QString::fromStdString(objectId));
    if (status == PageStorageStatus::Ok) return true;
    const QString message = storageError(status);
    pageId_.clear();
    syncSelection();
    setError(message);
    return false;
}

bool PageEditorAdapter::commit(PageCommand command, const std::string& objectId) {
    if (!session_) return false;
    const auto result = session_->execute(std::move(command));
    if (result != HistoryResult::Applied) {
        setError(result == HistoryResult::BudgetExceeded
                     ? QStringLiteral("Limite do histórico atingido.")
                     : QStringLiteral("Não foi possível aplicar a edição."));
        return false;
    }
    if (!persist(objectId)) return false;
    undoIds_.push_back(objectId);
    redoIds_.clear();
    error_.clear();
    emit stateChanged();
    return true;
}

bool PageEditorAdapter::saveText(int slot, const QString& text) {
    if (!session_ || slot < 0 || slot > 1) return false;
    try {
        const QString normalized = QString(text).replace("\r\n", "\n").replace('\r', '\n');
        if (normalized.size() > 1'000'000) {
            setError(QStringLiteral("Texto longo demais para esta prova."));
            return false;
        }
        if (normalized == text_[slot]) return true;
        const std::string id = slotId(pageId_, slot);
        const PageObject* existing = findObject(session_->page(), id);
        if (existing && !std::holds_alternative<TextContainer>(existing->payload)) {
            setError(QStringLiteral("ID de texto ocupado por outro objeto."));
            return false;
        }
        PageCommand command;
        command.label = "Edit text";
        if (normalized.isEmpty()) {
            if (!existing) return true;
            command.changes.emplace_back(DeleteObject{id});
        } else if (existing) {
            TextContainer container = std::get<TextContainer>(existing->payload);
            container.document = textDocument(normalized);
            command.changes.emplace_back(SetPayload{id, std::move(container)});
        } else {
            PageObject object;
            object.common.id = id;
            object.common.page_id = session_->page().page_id;
            object.common.transform.translation = {45, slot == 0 ? 120.0 : 258.0};
            object.common.z_order = static_cast<std::int64_t>(session_->page().objects.size());
            object.common.reading_order = object.common.z_order;
            object.common.accessible_description = slot == 0 ? "Primeira caixa de texto" : "Segunda caixa de texto";
            TextContainer container;
            container.document = textDocument(normalized);
            object.payload = std::move(container);
            command.changes.emplace_back(CreateObject{id, session_->page().objects.size(), std::move(object)});
        }
        if (!commit(std::move(command), id)) return false;
        text_[slot] = normalized;
        emit stateChanged();
        return true;
    } catch (const std::bad_alloc&) {
        setError(QStringLiteral("Memória insuficiente para editar o texto."));
        return false;
    }
}

bool PageEditorAdapter::addInk(const QVariantList& points) {
    if (!session_ || points.isEmpty() || points.size() > maxVisualInkPoints) return false;
    try {
        InkStroke stroke;
        stroke.color = "#9B6336FF";
        stroke.points.reserve(static_cast<std::size_t>(points.size()));
        for (const QVariant& point : points) {
            if (!point.canConvert<QPointF>()) return false;
            const QPointF pixel = point.toPointF();
            if (!std::isfinite(pixel.x()) || !std::isfinite(pixel.y())) return false;
            stroke.points.push_back({{pixel.x() / pxPerPt, pixel.y() / pxPerPt}, {}, {}, {}, {}});
        }
        PageObject object;
        object.common.id = QUuid::createUuid().toString(QUuid::WithoutBraces).toStdString();
        object.common.page_id = session_->page().page_id;
        object.common.z_order = static_cast<std::int64_t>(session_->page().objects.size());
        object.common.reading_order = object.common.z_order;
        object.payload = std::move(stroke);
        PageCommand command;
        command.label = "Add mouse ink";
        const std::string id = object.common.id;
        command.changes.emplace_back(CreateObject{id, session_->page().objects.size(), std::move(object)});
        if (!commit(std::move(command), id)) return false;
        ++inkCount_;
        inkStrokes_.append(QVariant(points));
        emit stateChanged();
        return true;
    } catch (const std::bad_alloc&) {
        setError(QStringLiteral("Memória insuficiente para a tinta."));
        return false;
    }
}

bool PageEditorAdapter::undo() {
    if (!session_ || undoIds_.empty()) return false;
    const std::string id = undoIds_.back();
    if (session_->undo() != HistoryResult::Applied) return false;
    if (!persist(id)) return false;
    undoIds_.pop_back();
    redoIds_.push_back(id);
    error_.clear();
    rebuildVisual();
    emit stateChanged();
    emit pageLoaded();
    return true;
}

bool PageEditorAdapter::redo() {
    if (!session_ || redoIds_.empty()) return false;
    const std::string id = redoIds_.back();
    if (session_->redo() != HistoryResult::Applied) return false;
    if (!persist(id)) return false;
    redoIds_.pop_back();
    undoIds_.push_back(id);
    error_.clear();
    rebuildVisual();
    emit stateChanged();
    emit pageLoaded();
    return true;
}
