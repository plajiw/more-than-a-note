#include "page_repository.h"
#include "notebook_schema.h"
#include "content_codec.h"

#include <QCoreApplication>
#include <QCryptographicHash>
#include <QFile>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QTemporaryDir>

#include <iostream>

using namespace mtn::model;

#define CHECK(condition) do { if (!(condition)) { \
    std::cerr << "Check failed: " #condition " at line " << __LINE__ << '\n'; \
    return 1; \
} } while (false)

namespace {
constexpr auto pageId = "33333333-3333-4333-8333-333333333333";
constexpr auto textId = "55555555-5555-4555-8555-555555555555";
constexpr auto inkId = "66666666-6666-4666-8666-666666666666";

bool loadFixture(QSqlDatabase& db) {
    QFile file(QStringLiteral(MTN_V1_FIXTURE_PATH));
    if (!file.open(QIODevice::ReadOnly)) return false;
    for (const QByteArray& line : file.readAll().split('\n')) {
        const auto sql = line.trimmed();
        if (sql.isEmpty()) continue;
        QSqlQuery query(db);
        if (!query.exec(QString::fromUtf8(sql))) return false;
    }
    return true;
}

QByteArray hashFile(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return {};
    return QCryptographicHash::hash(file.readAll(), QCryptographicHash::Sha256);
}

PageObject makeText() {
    PageObject object;
    object.common.id = textId;
    object.common.page_id = pageId;
    object.common.transform.translation = {45.5, 123.25};
    object.common.accessible_description = "Texto da aula";
    TextContainer text;
    RichParagraph paragraph;
    paragraph.runs.push_back({"Composição — שלום", {}});
    text.document.paragraphs.push_back(std::move(paragraph));
    object.payload = std::move(text);
    return object;
}

PageObject makeInk() {
    PageObject object;
    object.common.id = inkId;
    object.common.page_id = pageId;
    object.common.z_order = 1;
    object.common.reading_order = 1;
    object.common.transform.translation = {7, 9};
    InkStroke stroke;
    stroke.color = "#9B6336FF";
    stroke.points.push_back({{1, 2}, 0.5, 0.0, {}, {}});
    stroke.points.push_back({{10, 12}, 0.8, 16.0, {}, {}});
    object.payload = std::move(stroke);
    return object;
}
} // namespace

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    QTemporaryDir directory;
    CHECK(directory.isValid());
    const QString path = directory.filePath("notebook.sqlite");
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "page-repository");
        db.setDatabaseName(path);
        CHECK(db.open());
        CHECK(QSqlQuery(db).exec("PRAGMA foreign_keys = ON"));
        CHECK(loadFixture(db));
        const QByteArray initialHash = hashFile(path);
        auto loaded = loadPageContent(db, pageId);
        CHECK(loaded.status == PageStorageStatus::LegacyEmpty);
        CHECK(loaded.page.objects.empty());
        CHECK(hashFile(path) == initialHash);

        const auto text = makeText();
        CHECK(savePageObject(db, text) == PageStorageStatus::Ok);
        CHECK(inspectNotebookSchema(db) == NotebookSchemaStatus::ReadyV4);
        loaded = loadPageContent(db, pageId);
        CHECK(loaded.status == PageStorageStatus::Ok);
        CHECK(loaded.page.objects.size() == 1);
        CHECK(loaded.page.objects.front().common.transform.translation.x == 45.5);
        CHECK(std::get<TextContainer>(loaded.page.objects.front().payload)
                  .document.paragraphs.front().runs.front().utf8 == "Composição — שלום");

        const auto ink = makeInk();
        CHECK(savePageObject(db, ink) == PageStorageStatus::Ok);
        loaded = loadPageContent(db, pageId);
        CHECK(loaded.status == PageStorageStatus::Ok);
        CHECK(loaded.page.objects.size() == 2);
        const auto& loadedInk = std::get<InkStroke>(loaded.page.objects.back().payload);
        CHECK(loadedInk.points.size() == 2);
        CHECK(loadedInk.points[1].position.x == 10);
        CHECK(loadedInk.points[1].pressure == 0.8);
        CHECK(loadedInk.color == "#9B6336FF");

        auto changedText = text;
        changedText.common.transform.translation.x = 80;
        auto& changedContainer = std::get<TextContainer>(changedText.payload);
        changedContainer.width_pt = 320;
        changedContainer.fixed_width = true;
        auto& richParagraph = changedContainer.document.paragraphs.front();
        richParagraph.kind = ParagraphKind::Heading2;
        richParagraph.runs.front().style.bold = true;
        richParagraph.runs.front().style.font_family = "IBM Plex Serif";
        richParagraph.runs.front().style.font_size_pt = 22;
        richParagraph.runs.front().style.color = "#2868BDFF";
        richParagraph.runs.front().style.link = "https://example.org/aula";
        CHECK(savePageObject(db, changedText) == PageStorageStatus::Ok);
        QSqlQuery versionQuery(db);
        CHECK(versionQuery.exec("SELECT payload_version FROM page_objects WHERE kind = 'text'"));
        CHECK(versionQuery.next() && versionQuery.value(0).toInt() == 2);
        versionQuery.finish();
        loaded = loadPageContent(db, pageId);
        CHECK(loaded.status == PageStorageStatus::Ok);
        CHECK(loaded.page.objects.size() == 2);
        CHECK(loaded.page.objects.front().common.transform.translation.x == 80);
        CHECK(std::get<TextContainer>(loaded.page.objects.front().payload).width_pt == 320);
        const auto& persistedStyle = std::get<TextContainer>(loaded.page.objects.front().payload)
                                         .document.paragraphs.front().runs.front().style;
        CHECK(std::get<TextContainer>(loaded.page.objects.front().payload)
                  .document.paragraphs.front().kind == ParagraphKind::Heading2);
        CHECK(persistedStyle.bold && persistedStyle.font_family == "IBM Plex Serif");
        CHECK(persistedStyle.font_size_pt == 22 && persistedStyle.color == "#2868BDFF");
        CHECK(persistedStyle.link == "https://example.org/aula");
        CHECK(std::get<TextContainer>(loaded.page.objects.front().payload).fixed_width);
        CHECK(std::get<InkStroke>(loaded.page.objects.back().payload).points[1].position.x == 10);
        db.close();
        CHECK(db.open());
        CHECK(QSqlQuery(db).exec("PRAGMA foreign_keys = ON"));
        loaded = loadPageContent(db, pageId);
        CHECK(loaded.status == PageStorageStatus::Ok && loaded.page.objects.size() == 2);
        CHECK(loaded.page.objects.front().common.transform.translation.x == 80);
        CHECK(std::get<TextContainer>(loaded.page.objects.front().payload).width_pt == 320);

        auto wrongPage = makeText();
        wrongPage.common.page_id = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
        CHECK(savePageObject(db, wrongPage) == PageStorageStatus::MissingPage);
        CHECK(QSqlQuery(db).exec("INSERT INTO pages VALUES ("
                                 "'44444444-4444-4444-8444-444444444444', "
                                 "'22222222-2222-4222-8222-222222222222', 'Outra página', 1)"));
        auto crossPage = makeText();
        crossPage.common.page_id = "44444444-4444-4444-8444-444444444444";
        CHECK(savePageObject(db, crossPage) == PageStorageStatus::SqlError);
        CHECK(loadPageContent(db, pageId).page.objects.size() == 2);
        CHECK(loadPageContent(db, crossPage.common.page_id.c_str()).page.objects.empty());
        auto badInk = makeInk();
        std::get<InkStroke>(badInk.payload).points.front().pressure = 2.0;
        CHECK(savePageObject(db, badInk) == PageStorageStatus::InvalidContent);
        auto invalidText = makeText();
        std::get<TextContainer>(invalidText.payload).width_pt = -1;
        CHECK(savePageObject(db, invalidText) == PageStorageStatus::InvalidContent);
        CHECK(loadPageContent(db, pageId).page.objects.size() == 2);

        CHECK(deletePageObject(db, pageId, textId) == PageStorageStatus::Ok);
        loaded = loadPageContent(db, pageId);
        CHECK(loaded.status == PageStorageStatus::Ok);
        CHECK(loaded.page.objects.size() == 1 && loaded.page.objects.front().common.id == inkId);

        QSqlQuery corrupt(db);
        corrupt.prepare("UPDATE page_objects SET payload = X'00' WHERE id = ?");
        corrupt.addBindValue(inkId);
        CHECK(corrupt.exec());
        loaded = loadPageContent(db, pageId);
        CHECK(loaded.status == PageStorageStatus::InvalidContent);
        CHECK(loaded.page.objects.empty());

        CHECK(QSqlQuery(db).exec("PRAGMA user_version = 5"));
        const QByteArray futureHash = hashFile(path);
        CHECK(loadPageContent(db, pageId).status == PageStorageStatus::UnsupportedContent);
        CHECK(savePageObject(db, text) == PageStorageStatus::UnsupportedContent);
        CHECK(hashFile(path) == futureHash);
        db.close();
    }
    QSqlDatabase::removeDatabase("page-repository");

    const QString secondPath = directory.filePath("unmodified.sqlite");
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "invalid-page-repository");
        db.setDatabaseName(secondPath);
        CHECK(db.open());
        CHECK(loadFixture(db));
        auto bad = makeText();
        bad.common.transform.scale_x = 0;
        CHECK(savePageObject(db, bad) == PageStorageStatus::InvalidContent);
        CHECK(inspectNotebookSchema(db) == NotebookSchemaStatus::LegacyV1);
        db.close();
    }
    QSqlDatabase::removeDatabase("invalid-page-repository");

    const QString legacyPath = directory.filePath("legacy-v2.sqlite");
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "legacy-v2-repository");
        db.setDatabaseName(legacyPath);
        CHECK(db.open());
        CHECK(QSqlQuery(db).exec("PRAGMA foreign_keys = ON"));
        CHECK(loadFixture(db));
        CHECK(migrateNotebookSchema(db) == NotebookSchemaStatus::MigratedV2);
        const auto original = makeText();
        const auto blob = encode_text_v1(std::get<TextContainer>(original.payload).document);
        CHECK(blob.status == CodecStatus::Ok);
        QSqlQuery insert(db);
        insert.prepare("INSERT INTO page_objects(id, page_id, kind, z_order, reading_order, "
                       "tx, ty, payload) VALUES (?, ?, 'text', 0, 0, ?, ?, ?)");
        insert.addBindValue(textId);
        insert.addBindValue(pageId);
        insert.addBindValue(45.5);
        insert.addBindValue(123.25);
        insert.addBindValue(QByteArray(reinterpret_cast<const char*>(blob.bytes.data()),
                                       static_cast<qsizetype>(blob.bytes.size())));
        CHECK(insert.exec());
        const QByteArray beforeRead = hashFile(legacyPath);
        auto legacy = loadPageContent(db, pageId);
        CHECK(legacy.status == PageStorageStatus::Ok && legacy.page.objects.size() == 1);
        CHECK(std::get<TextContainer>(legacy.page.objects[0].payload).width_pt == 240);
        CHECK(hashFile(legacyPath) == beforeRead);
        auto resized = legacy.page.objects[0];
        resized.common.transform.translation.x = 90;
        auto& container = std::get<TextContainer>(resized.payload);
        container.width_pt = 315;
        container.fixed_width = true;
        CHECK(savePageObject(db, resized) == PageStorageStatus::Ok);
        CHECK(inspectNotebookSchema(db) == NotebookSchemaStatus::ReadyV4);
        db.close();
        CHECK(db.open());
        legacy = loadPageContent(db, pageId);
        CHECK(legacy.status == PageStorageStatus::Ok && legacy.page.objects.size() == 1);
        CHECK(legacy.page.objects[0].common.id == textId);
        CHECK(legacy.page.objects[0].common.transform.translation.x == 90);
        CHECK(std::get<TextContainer>(legacy.page.objects[0].payload).width_pt == 315);
        CHECK(std::get<TextContainer>(legacy.page.objects[0].payload).fixed_width);
        CHECK(std::get<TextContainer>(legacy.page.objects[0].payload)
                  .document.paragraphs[0].runs[0].utf8 == "Composição — שלום");
        db.close();
    }
    QSqlDatabase::removeDatabase("legacy-v2-repository");
    return 0;
}
