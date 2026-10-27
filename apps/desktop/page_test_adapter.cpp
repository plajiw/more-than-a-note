#include "page_test_adapter.h"

#include "notebook_store.h"

#include <QUuid>
#include <QVariantMap>

#include <algorithm>
#include <exception>
#include <new>
#include <utility>

using namespace mtn::model;

PageTestAdapter::PageTestAdapter(NotebookStore* store, QObject* parent)
    : QObject(parent), store_(store) {
    Q_ASSERT(store_);
    connect(store_, &NotebookStore::selectionChanged, this, &PageTestAdapter::syncSelection);
}

void PageTestAdapter::setDemoEnabled(bool enabled) {
    if (demoEnabled_ == enabled) return;
    demoEnabled_ = enabled;
    syncSelection();
    emit stateChanged();
}

void PageTestAdapter::setError(const QString& message) {
    if (error_ == message) return;
    error_ = message;
    emit errorChanged();
}

void PageTestAdapter::syncSelection() {
    const QString wanted = demoEnabled_ ? store_->activePageId() : QString{};
    if (wanted == pageId_) return;
    session_.reset();
    pageId_ = wanted;
    objects_.clear();
    setError({});
    if (!wanted.isEmpty()) {
        try {
            PageContent page{wanted.toStdString(), {}};
            session_ = std::make_unique<PageSession>(std::move(page));
        } catch (const std::exception&) {
            pageId_.clear();
            setError(QStringLiteral("Não foi possível iniciar a página de teste."));
        }
    }
    emit stateChanged();
}

void PageTestAdapter::refresh() {
    try {
        QVariantList snapshot;
        if (session_) {
            const auto& page = session_->page();
            snapshot.reserve(static_cast<qsizetype>(page.objects.size()));
            for (const auto& object : page.objects) {
                QVariantMap item{
                    {"id", QString::fromStdString(object.common.id)},
                    {"xPt", object.common.transform.translation.x},
                    {"yPt", object.common.transform.translation.y},
                    {"zOrder", static_cast<qlonglong>(object.common.z_order)},
                    {"readingOrder", static_cast<qlonglong>(object.common.reading_order)},
                    {"locked", object.common.locked}
                };
                if (const auto* text = std::get_if<TextContainer>(&object.payload)) {
                    item.insert("kind", "text");
                    item.insert("widthPt", text->width_pt);
                    QString preview;
                    for (const auto& paragraph : text->document.paragraphs) {
                        if (!preview.isEmpty()) preview += QLatin1Char(' ');
                        for (const auto& run : paragraph.runs) {
                            // The snapshot is for a small preview, never a copy of
                            // a potentially large rich-text document into QML.
                            preview += QString::fromUtf8(run.utf8.data(),
                                static_cast<qsizetype>(std::min<std::size_t>(run.utf8.size(), 256)));
                            if (preview.size() >= 128) break;
                        }
                        if (preview.size() >= 128) break;
                    }
                    item.insert("preview", preview.left(128));
                } else {
                    item.insert("kind", "other");
                }
                snapshot.append(item);
            }
        }
        objects_ = std::move(snapshot);
        setError({});
    } catch (const std::bad_alloc&) {
        objects_.clear();
        setError(QStringLiteral("Memória insuficiente para mostrar a prévia."));
    }
    emit stateChanged();
}

bool PageTestAdapter::applied(HistoryResult result) {
    if (result == HistoryResult::Applied) {
        refresh();
        return true;
    }
    switch (result) {
    case HistoryResult::NothingToDo: setError(QStringLiteral("Nada para desfazer ou refazer.")); break;
    case HistoryResult::Locked: setError(QStringLiteral("Objeto bloqueado.")); break;
    case HistoryResult::BudgetExceeded: setError(QStringLiteral("Limite de memória do histórico atingido.")); break;
    case HistoryResult::OutOfMemory: setError(QStringLiteral("Memória insuficiente.")); break;
    default: setError(QStringLiteral("Comando inválido para a página.")); break;
    }
    return false;
}

bool PageTestAdapter::createTextAt(double xPt, double yPt, const QString& text) {
    if (!session_) return false;
    try {
        PageObject object;
        object.common.id = QUuid::createUuid().toString(QUuid::WithoutBraces).toStdString();
        object.common.page_id = session_->page().page_id;
        object.common.transform.translation = {xPt, yPt};
        const auto count = session_->page().objects.size();
        object.common.z_order = static_cast<std::int64_t>(count);
        object.common.reading_order = static_cast<std::int64_t>(count);
        TextContainer container;
        RichParagraph paragraph;
        paragraph.runs.push_back({text.toUtf8().toStdString(), {}});
        container.document.paragraphs.push_back(std::move(paragraph));
        object.payload = std::move(container);
        PageCommand command;
        command.label = "Create test text";
        command.changes.emplace_back(CreateObject{object.common.id, count, std::move(object)});
        return applied(session_->execute(std::move(command)));
    } catch (const std::bad_alloc&) {
        setError(QStringLiteral("Memória insuficiente."));
        return false;
    }
}

bool PageTestAdapter::moveObject(const QString& id, double xPt, double yPt) {
    if (!session_) return false;
    try {
        const auto objectId = id.toStdString();
        for (const auto& object : session_->page().objects) {
            if (object.common.id != objectId) continue;
            auto transform = object.common.transform;
            transform.translation = {xPt, yPt};
            PageCommand command;
            command.label = "Move test object";
            command.changes.emplace_back(SetTransform{objectId, transform});
            return applied(session_->execute(std::move(command)));
        }
    } catch (const std::bad_alloc&) {
        setError(QStringLiteral("Memória insuficiente."));
        return false;
    }
    setError(QStringLiteral("Objeto não encontrado na página de teste."));
    return false;
}

bool PageTestAdapter::undo() {
    return session_ && applied(session_->undo());
}

bool PageTestAdapter::redo() {
    return session_ && applied(session_->redo());
}
