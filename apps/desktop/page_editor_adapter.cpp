#include "page_editor_adapter.h"

#include "notebook_store.h"
#include "notebook_schema.h"
#include "page_repository.h"
#include "rich_text_qt.h"

#include <QPointF>
#include <QPointer>
#include <QQuickTextDocument>
#include <QSqlQuery>
#include <QTextBlock>
#include <QTextBlockFormat>
#include <QTextCharFormat>
#include <QTextCursor>
#include <QTextList>
#include <QTextListFormat>
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
constexpr std::size_t recentSessionLimit = 4;
constexpr qint64 coalesceWindowMs = 1000;
constexpr double duplicateOffsetPt = 16;

constexpr double pageWidthPt = 595.2755905512;
constexpr double marginPt = 24;
constexpr double minWidthPt = 120;
constexpr double maxWidthPt = 500;

bool validTextGeometry(double xPt, double yPt, double widthPt, bool infinite) {
    return std::isfinite(xPt) && std::isfinite(yPt) && std::isfinite(widthPt) &&
           xPt >= marginPt && yPt >= marginPt && widthPt >= minWidthPt &&
           widthPt <= maxWidthPt &&
           (infinite || xPt + widthPt <= pageWidthPt - marginPt + 0.0001);
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

// Every object an entry touches, in first-seen order.
std::vector<std::string> touchedIds(const PageCommand& command) {
    std::vector<std::string> ids;
    for (const auto& change : command.changes) {
        const std::string& id = std::visit([](const auto& edit) -> const std::string& { return edit.id; },
                                           change);
        if (std::find(ids.begin(), ids.end(), id) == ids.end()) ids.push_back(id);
    }
    return ids;
}

// Objects whose content (not just position) an entry changes; their editors
// must reload what they show.
std::vector<std::string> contentIds(const PageCommand& command) {
    std::vector<std::string> ids;
    for (const auto& change : command.changes) {
        if (std::holds_alternative<SetTransform>(change)) continue;
        const std::string& id = std::visit([](const auto& edit) -> const std::string& { return edit.id; },
                                           change);
        if (std::find(ids.begin(), ids.end(), id) == ids.end()) ids.push_back(id);
    }
    return ids;
}

bool createsOnly(const PageCommand& command, const std::string& id) {
    if (command.changes.size() != 1) return false;
    const auto* create = std::get_if<CreateObject>(&command.changes.front());
    return create && create->id == id;
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
    connect(store_, &NotebookStore::aboutToChangeSelection, this, [this] {
        if (session_) emit flushRequested();
    });
    connect(store_, &NotebookStore::selectionChanged, this, &PageEditorAdapter::syncSelection);
}

QString PageEditorAdapter::undoLabel() const {
    const auto* command = session_ ? session_->next_undo() : nullptr;
    return command ? QString::fromStdString(command->label) : QString{};
}

QString PageEditorAdapter::redoLabel() const {
    const auto* command = session_ ? session_->next_redo() : nullptr;
    return command ? QString::fromStdString(command->label) : QString{};
}

void PageEditorAdapter::setEnabled(bool enabled) {
    if (enabled_ == enabled) return;
    if (!enabled && session_) emit flushRequested();
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
    // The database is the source of truth and every entry is already
    // persisted, so a recent page can resume its history where it stopped.
    if (session_ && !pageId_.isEmpty()) {
        recentSessions_.insert(recentSessions_.begin(), {pageId_, std::move(session_)});
        if (recentSessions_.size() > recentSessionLimit) recentSessions_.pop_back();
    }
    std::unique_ptr<PageSession> resumed;
    for (auto it = recentSessions_.begin(); it != recentSessions_.end(); ++it) {
        if (it->pageId != wanted) continue;
        resumed = std::move(it->session);
        recentSessions_.erase(it);
        break;
    }
    pageId_ = wanted;
    session_.reset();
    mergeKey_.clear();
    revisions_.clear();
    textCards_.clear();
    inkStrokes_.clear();
    inkCount_ = 0;
    error_.clear();
    infiniteCanvas_ = false;
    if (!wanted.isEmpty()) {
        try {
            auto db = store_->activeDatabase();
            auto loaded = loadPageContent(db, wanted);
            if (loaded.status == PageStorageStatus::Ok ||
                loaded.status == PageStorageStatus::LegacyEmpty) {
                session_ = resumed && resumed->page() == loaded.page
                    ? std::move(resumed) : std::make_unique<PageSession>(std::move(loaded.page));
                if (loaded.status == PageStorageStatus::Ok) {
                    QSqlQuery settings(db);
                    settings.prepare("SELECT canvas_kind FROM page_settings WHERE page_id = ?");
                    settings.addBindValue(wanted);
                    if (settings.exec() && settings.next())
                        infiniteCanvas_ = settings.value(0).toInt() == 1;
                }
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

bool PageEditorAdapter::setInfiniteCanvas(bool infinite) {
    if (!session_) return false;
    if (infiniteCanvas_ == infinite) return true;
    auto db = store_->activeDatabase();
    const auto schema = inspectNotebookSchema(db);
    if (schema != NotebookSchemaStatus::ReadyV4 &&
        migrateNotebookSchemaV4(db) != NotebookSchemaStatus::MigratedV4) {
        setError(QStringLiteral("Não foi possível atualizar o formato do caderno."));
        return false;
    }
    if (!db.transaction()) return false;
    QSqlQuery query(db);
    query.prepare("UPDATE page_settings SET canvas_kind = ? WHERE page_id = ?");
    query.addBindValue(infinite ? 1 : 0);
    query.addBindValue(pageId_);
    if (!query.exec() || query.numRowsAffected() != 1 || !db.commit()) {
        db.rollback();
        setError(QStringLiteral("Não foi possível salvar o tipo de página."));
        return false;
    }
    infiniteCanvas_ = infinite;
    error_.clear();
    emit stateChanged();
    return true;
}

void PageEditorAdapter::rebuildVisual() {
    textCards_.clear();
    inkStrokes_.clear();
    inkCount_ = 0;
    if (!session_) {
        textCardModel_.sync({});
        return;
    }
    const auto& page = session_->page();
    int points = 0;
    for (const auto& object : page.objects) {
        if (const auto* text = std::get_if<TextContainer>(&object.payload)) {
            textCards_.append(QVariantMap{
                {"id", QString::fromStdString(object.common.id)},
                {"xPt", object.common.transform.translation.x},
                {"yPt", object.common.transform.translation.y},
                {"widthPt", text->width_pt},
                {"fixedWidth", text->fixed_width},
                {"text", plainText(*text)},
                {"revision", revisions_.value(QString::fromStdString(object.common.id))}
            });
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
    textCardModel_.sync(textCards_);
}

void PageEditorAdapter::dropSessionAfterFailure(const QString& message) {
    // Memory and database may now disagree; reload the page from disk and
    // forget its history instead of offering steps that no longer apply.
    const QString page = pageId_;
    session_.reset();
    recentSessions_.erase(std::remove_if(recentSessions_.begin(), recentSessions_.end(),
                                         [&](const CachedSession& entry) { return entry.pageId == page; }),
                          recentSessions_.end());
    pageId_.clear();
    syncSelection();
    setError(message);
}

bool PageEditorAdapter::persist(const PageCommand& command) {
    if (!session_) return false;
    std::vector<const PageObject*> upserts;
    QStringList deletions;
    for (const auto& id : touchedIds(command)) {
        if (const auto* object = findObject(session_->page(), id)) upserts.push_back(object);
        else deletions.append(QString::fromStdString(id));
    }
    auto db = store_->activeDatabase();
    const auto status = savePageChanges(db, pageId_, upserts, deletions);
    if (status == PageStorageStatus::Ok) return true;
    dropSessionAfterFailure(storageError(status));
    return false;
}

bool PageEditorAdapter::commit(PageCommand command, const QString& mergeKey) {
    if (!session_) return false;
    const bool merge = !mergeKey.isEmpty() && mergeKey == mergeKey_ &&
                       mergeClock_.isValid() && mergeClock_.elapsed() < coalesceWindowMs;
    const auto ids = contentIds(command);
    const auto result = merge ? session_->execute_merged(std::move(command))
                              : session_->execute(std::move(command));
    if (result != HistoryResult::Applied) {
        setError(result == HistoryResult::BudgetExceeded
                     ? QStringLiteral("Limite do histórico atingido.")
                     : QStringLiteral("Não foi possível aplicar a edição."));
        return false;
    }
    if (!persist(*session_->next_undo())) return false;
    mergeKey_ = mergeKey;
    mergeClock_.restart();
    for (const auto& id : ids) ++revisions_[QString::fromStdString(id)];
    error_.clear();
    rebuildVisual();
    emit stateChanged();
    emit pageLoaded();
    return true;
}

QString PageEditorAdapter::createTextAt(double xPt, double yPt) {
    if (!session_ || !std::isfinite(xPt) || !std::isfinite(yPt)) return {};
    try {
        const QString id = QUuid::createUuid().toString(QUuid::WithoutBraces);
        PageObject object;
        object.common.id = id.toStdString();
        object.common.page_id = session_->page().page_id;
        object.common.transform.translation = {
            infiniteCanvas_ ? std::max(xPt, marginPt) :
                              std::clamp(xPt, marginPt, pageWidthPt - marginPt - 240),
            std::max(yPt, marginPt)};
        object.common.z_order = static_cast<std::int64_t>(session_->page().objects.size());
        object.common.reading_order = object.common.z_order;
        object.common.accessible_description = "Caixa de texto";
        object.payload = TextContainer{};
        PageCommand command;
        command.label = "Criar caixa de texto";
        command.selection_after = "caret:0:0";
        command.changes.emplace_back(CreateObject{object.common.id,
                                                    session_->page().objects.size(), std::move(object)});
        return commit(std::move(command)) ? id : QString{};
    } catch (const std::bad_alloc&) {
        setError(QStringLiteral("Memória insuficiente para criar a caixa."));
        return {};
    }
}

bool PageEditorAdapter::saveText(const QString& id, const QString& text) {
    if (!session_) return false;
    try {
        const QString normalized = QString(text).replace("\r\n", "\n").replace('\r', '\n');
        if (normalized.size() > 1'000'000) {
            setError(QStringLiteral("Texto longo demais para esta prova."));
            return false;
        }
        const std::string objectId = id.toStdString();
        const PageObject* existing = findObject(session_->page(), objectId);
        if (!existing || !std::holds_alternative<TextContainer>(existing->payload)) {
            setError(QStringLiteral("Caixa de texto não encontrada."));
            return false;
        }
        if (normalized == plainText(std::get<TextContainer>(existing->payload))) return true;
        PageCommand command;
        command.label = "Editar texto";
        TextContainer container = std::get<TextContainer>(existing->payload);
        container.document = textDocument(normalized);
        command.changes.emplace_back(SetPayload{objectId, std::move(container)});
        return commit(std::move(command));
    } catch (const std::bad_alloc&) {
        setError(QStringLiteral("Memória insuficiente para editar o texto."));
        return false;
    }
}

bool PageEditorAdapter::loadRichText(const QString& id, QObject* quickDocument) {
    const auto* object = session_ ? findObject(session_->page(), id.toStdString()) : nullptr;
    auto* wrapper = qobject_cast<QQuickTextDocument*>(quickDocument);
    if (!object || !std::holds_alternative<TextContainer>(object->payload) ||
        !wrapper || !wrapper->textDocument()) return false;
    // The page history is the only undo stack; a second one inside the
    // document would diverge from it after the first commit.
    wrapper->textDocument()->setUndoRedoEnabled(false);
    const bool loaded = populateQtDocument(*wrapper->textDocument(),
                                           std::get<TextContainer>(object->payload).document);
    wrapper->textDocument()->setModified(false);
    return loaded;
}

bool PageEditorAdapter::saveRichText(const QString& id, QObject* quickDocument,
                                     const QString& selectionBefore,
                                     const QString& selectionAfter, const QString& kind) {
    return saveRichTextDocuments({QVariantMap{{"id", id},
                                              {"document", QVariant::fromValue(quickDocument)},
                                              {"selectionBefore", selectionBefore},
                                              {"selectionAfter", selectionAfter},
                                              {"kind", kind}}});
}

bool PageEditorAdapter::saveRichTextDocuments(const QVariantList& entries) {
    if (!session_) return false;
    try {
        struct Captured {
            std::string id;
            RichTextDocument document;
            QVariantMap entry;
        };
        std::vector<Captured> captured;
        std::vector<QPointer<QQuickTextDocument>> wrappers;
        captured.reserve(static_cast<std::size_t>(entries.size()));
        wrappers.reserve(static_cast<std::size_t>(entries.size()));
        for (const QVariant& entry : entries) {
            const QVariantMap map = entry.toMap();
            const std::string id = map.value("id").toString().toStdString();
            auto* wrapper = qobject_cast<QQuickTextDocument*>(map.value("document").value<QObject*>());
            const auto* object = findObject(session_->page(), id);
            if (!wrapper || !wrapper->textDocument() || !object ||
                !std::holds_alternative<TextContainer>(object->payload)) {
                setError(QStringLiteral("Caixa de texto não encontrada."));
                return false;
            }
            auto document = captureQtDocument(*wrapper->textDocument());
            if (!document) {
                setError(QStringLiteral("O texto contém formatação ou conteúdo não suportado."));
                return false;
            }
            captured.push_back({id, std::move(*document), map});
            wrappers.emplace_back(wrapper);
        }
        for (auto& [id, document, entry] : captured) {
            const auto* object = findObject(session_->page(), id);
            if (!object) return false;
            const auto& current = std::get<TextContainer>(object->payload);
            if (current.document == document) continue;
            TextContainer changed = current;
            changed.document = std::move(document);
            PageCommand command;
            command.label = entry.value("kind").toString() == "format" ? "Formatar texto" : "Digitar";
            command.selection_before = entry.value("selectionBefore").toString().toStdString();
            command.selection_after = entry.value("selectionAfter").toString().toStdString();
            command.changes.emplace_back(SetPayload{id, std::move(changed)});
            if (!commit(std::move(command))) return false;
        }
        for (const auto& wrapper : wrappers)
            if (wrapper && wrapper->textDocument()) wrapper->textDocument()->setModified(false);
        return true;
    } catch (const std::bad_alloc&) {
        setError(QStringLiteral("Memória insuficiente para editar o texto."));
        return false;
    }
}

QVariantMap PageEditorAdapter::richFormatAt(QObject* quickDocument, int position) const {
    auto* wrapper = qobject_cast<QQuickTextDocument*>(quickDocument);
    if (!wrapper || !wrapper->textDocument()) return {};
    QTextDocument* document = wrapper->textDocument();
    QTextCursor cursor(document);
    cursor.setPosition(std::clamp(position, 0, document->characterCount() - 1));
    const auto format = cursor.charFormat();
    const auto block = cursor.block();
    QString family = QStringLiteral("IBM Plex Serif");
    if (format.hasProperty(QTextFormat::FontFamilies)) {
        const auto names = format.fontFamilies().toStringList();
        if (!names.isEmpty()) family = names.first();
    }
    QString listKind = QStringLiteral("none");
    if (const auto* list = block.textList())
        listKind = list->format().style() == QTextListFormat::ListDecimal
            ? QStringLiteral("numbered") : QStringLiteral("bullet");
    return {{"bold", format.fontWeight() >= QFont::Bold},
            {"italic", format.fontItalic()},
            {"underline", format.fontUnderline()},
            {"family", family},
            {"size", format.fontPointSize() > 0 ? format.fontPointSize() : 16.0},
            {"color", format.foreground().style() == Qt::SolidPattern
                          ? format.foreground().color().name(QColor::HexRgb) : QStringLiteral("#282B2E")},
            {"heading", block.blockFormat().headingLevel()},
            {"list", listKind},
            {"link", format.anchorHref()}};
}

bool PageEditorAdapter::applyRichBlockFormat(QObject* quickDocument, int start, int end,
                                              const QString& kind, const QString& value) {
    auto* wrapper = qobject_cast<QQuickTextDocument*>(quickDocument);
    if (!wrapper || !wrapper->textDocument()) return false;
    QTextDocument* document = wrapper->textDocument();
    const int last = document->characterCount() - 1;
    if (start < 0 || end < start || end > last) return false;
    QTextCursor cursor(document);
    cursor.setPosition(start);
    cursor.setPosition(end, QTextCursor::KeepAnchor);
    if (kind == "link" || kind == "unlink") {
        if (start == end) return false;
        if (kind == "link" && !(value.startsWith("https://") ||
                                  value.startsWith("http://") || value.startsWith("mailto:")))
            return false;
        QTextCharFormat format;
        format.setAnchor(kind == "link");
        format.setAnchorHref(kind == "link" ? value : QString{});
        cursor.mergeCharFormat(format);
        return true;
    }
    if (kind == "heading" || kind == "body") {
        const int level = kind == "body" ? 0 : value.toInt();
        if (level < 0 || level > 3) return false;
        QTextBlockFormat format;
        format.setHeadingLevel(level);
        cursor.mergeBlockFormat(format);
        QTextCharFormat chars;
        chars.setFontWeight(level ? QFont::Bold : QFont::Normal);
        chars.setFontPointSize(level == 1 ? 26 : level == 2 ? 22 : level == 3 ? 18 : 16);
        for (QTextBlock block = document->findBlock(start); block.isValid() &&
             block.position() <= end; block = block.next()) {
            QTextCursor paragraphCursor(block);
            if (block.length() > 1) {
                paragraphCursor.setPosition(block.position() + block.length() - 1,
                                            QTextCursor::KeepAnchor);
                paragraphCursor.mergeCharFormat(chars);
            } else {
                paragraphCursor.setCharFormat(chars);
            }
        }
        return true;
    }
    if (kind == "bullet" || kind == "numbered") {
        QTextListFormat format;
        format.setStyle(kind == "bullet" ? QTextListFormat::ListDisc :
                                           QTextListFormat::ListDecimal);
        format.setIndent(1);
        cursor.createList(format);
        return true;
    }
    if (kind == "no-list") {
        for (QTextBlock block = document->findBlock(start); block.isValid() &&
             block.position() <= end; block = block.next()) {
            if (auto* list = block.textList()) list->remove(block);
        }
        return true;
    }
    return false;
}

bool PageEditorAdapter::moveText(const QString& id, double xPt, double yPt, bool coalesce) {
    if (!session_) return false;
    const auto* object = findObject(session_->page(), id.toStdString());
    if (!object || !std::holds_alternative<TextContainer>(object->payload)) return false;
    const auto& container = std::get<TextContainer>(object->payload);
    if (!validTextGeometry(xPt, yPt, container.width_pt, infiniteCanvas_)) return false;
    if (object->common.transform.translation.x == xPt &&
        object->common.transform.translation.y == yPt) return true;
    PageTransform transform = object->common.transform;
    transform.translation = {xPt, yPt};
    PageCommand command;
    command.label = "Mover caixa de texto";
    command.selection_before = command.selection_after = "object";
    command.changes.emplace_back(SetTransform{id.toStdString(), transform});
    return commit(std::move(command), coalesce ? QStringLiteral("move:") + id : QString{});
}

bool PageEditorAdapter::resizeText(const QString& id, double widthPt, bool coalesce) {
    if (!session_) return false;
    const auto* object = findObject(session_->page(), id.toStdString());
    if (!object || !std::holds_alternative<TextContainer>(object->payload)) return false;
    const auto& current = std::get<TextContainer>(object->payload);
    if (!validTextGeometry(object->common.transform.translation.x,
                           object->common.transform.translation.y, widthPt,
                           infiniteCanvas_)) return false;
    if (current.width_pt == widthPt && current.fixed_width) return true;
    TextContainer changed = current;
    changed.width_pt = widthPt;
    changed.fixed_width = true;
    PageCommand command;
    command.label = "Ajustar largura";
    command.selection_before = command.selection_after = "object";
    command.changes.emplace_back(SetPayload{id.toStdString(), std::move(changed)});
    return commit(std::move(command), coalesce ? QStringLiteral("resize:") + id : QString{});
}

bool PageEditorAdapter::discardEmptyText(const QString& id) {
    if (!session_) return false;
    const auto* object = findObject(session_->page(), id.toStdString());
    if (!object || !std::holds_alternative<TextContainer>(object->payload) ||
        !plainText(std::get<TextContainer>(object->payload)).isEmpty()) return false;
    // A box created and left empty leaves no trace in the history.
    if (const auto* top = session_->next_undo(); top && createsOnly(*top, id.toStdString())) {
        if (session_->undo_and_forget() != HistoryResult::Applied) return false;
        PageCommand removal;
        removal.changes.emplace_back(DeleteObject{id.toStdString()});
        if (!persist(removal)) return false;
        mergeKey_.clear();
        rebuildVisual();
        emit stateChanged();
        emit pageLoaded();
        return true;
    }
    PageCommand command;
    command.label = "Excluir caixa de texto";
    command.selection_before = "object";
    command.changes.emplace_back(DeleteObject{id.toStdString()});
    return commit(std::move(command));
}

QString PageEditorAdapter::duplicateText(const QString& id) {
    if (!session_) return {};
    const auto* source = findObject(session_->page(), id.toStdString());
    if (!source || !std::holds_alternative<TextContainer>(source->payload)) return {};
    try {
        PageObject copy = *source;
        const QString copyId = QUuid::createUuid().toString(QUuid::WithoutBraces);
        copy.common.id = copyId.toStdString();
        const double width = std::get<TextContainer>(copy.payload).width_pt;
        auto& at = copy.common.transform.translation;
        at.x = infiniteCanvas_ ? at.x + duplicateOffsetPt
                               : std::clamp(at.x + duplicateOffsetPt, marginPt,
                                            std::max(marginPt, pageWidthPt - marginPt - width));
        at.y += duplicateOffsetPt;
        const auto count = static_cast<std::int64_t>(session_->page().objects.size());
        copy.common.z_order = count;
        copy.common.reading_order = count;
        PageCommand command;
        command.label = "Duplicar caixa de texto";
        command.selection_after = "object";
        command.changes.emplace_back(CreateObject{copy.common.id, session_->page().objects.size(),
                                                  std::move(copy)});
        return commit(std::move(command)) ? copyId : QString{};
    } catch (const std::bad_alloc&) {
        setError(QStringLiteral("Memória insuficiente para duplicar a caixa."));
        return {};
    }
}

bool PageEditorAdapter::deleteText(const QString& id) {
    if (!session_) return false;
    const auto* object = findObject(session_->page(), id.toStdString());
    if (!object || !std::holds_alternative<TextContainer>(object->payload)) return false;
    PageCommand command;
    command.label = "Excluir caixa de texto";
    command.selection_before = "object";
    command.changes.emplace_back(DeleteObject{id.toStdString()});
    return commit(std::move(command));
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
        command.label = "Desenhar traço";
        const std::string id = object.common.id;
        command.changes.emplace_back(CreateObject{id, session_->page().objects.size(), std::move(object)});
        return commit(std::move(command));
    } catch (const std::bad_alloc&) {
        setError(QStringLiteral("Memória insuficiente para a tinta."));
        return false;
    }
}

bool PageEditorAdapter::applyHistory(bool undo) {
    if (!session_) return false;
    // Pending typing is a step of its own and must land before we move.
    emit flushRequested();
    if (!session_ || !(undo ? session_->next_undo() : session_->next_redo())) return false;
    mergeKey_.clear();
    const auto result = undo ? session_->undo() : session_->redo();
    if (result != HistoryResult::Applied) {
        setError(QStringLiteral("Não foi possível desfazer ou refazer esta edição."));
        return false;
    }
    const PageCommand& applied = *(undo ? session_->next_redo() : session_->next_undo());
    if (!persist(applied)) return false;
    for (const auto& id : contentIds(applied)) ++revisions_[QString::fromStdString(id)];
    QString focus;
    for (const auto& id : touchedIds(applied))
        if (findObject(session_->page(), id)) { focus = QString::fromStdString(id); break; }
    const QString selection = QString::fromStdString(undo ? applied.selection_before
                                                          : applied.selection_after);
    error_.clear();
    rebuildVisual();
    emit stateChanged();
    emit pageLoaded();
    emit historyApplied(focus, selection, undo);
    return true;
}

bool PageEditorAdapter::undo() { return applyHistory(true); }

bool PageEditorAdapter::redo() { return applyHistory(false); }
