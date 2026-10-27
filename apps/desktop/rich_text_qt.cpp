#include "rich_text_qt.h"

#include <QColor>
#include <QTextBlock>
#include <QTextBlockFormat>
#include <QTextCharFormat>
#include <QTextCursor>
#include <QTextFragment>
#include <QTextList>
#include <QTextListFormat>

#include <algorithm>

using namespace mtn::model;

namespace {
QColor fromRgba(const std::string& rgba) {
    QColor result(QStringLiteral("#") + QString::fromStdString(rgba.substr(1, 6)));
    result.setAlpha(QString::fromStdString(rgba.substr(7, 2)).toInt(nullptr, 16));
    return result;
}

QString toRgba(const QColor& color) {
    return QStringLiteral("#%1%2%3%4")
        .arg(color.red(), 2, 16, QLatin1Char('0'))
        .arg(color.green(), 2, 16, QLatin1Char('0'))
        .arg(color.blue(), 2, 16, QLatin1Char('0'))
        .arg(color.alpha(), 2, 16, QLatin1Char('0')).toUpper();
}

QTextCharFormat qtStyle(const TextStyle& style) {
    QTextCharFormat format;
    if (style.bold) format.setFontWeight(QFont::Bold);
    if (style.italic) format.setFontItalic(true);
    if (style.underline) format.setFontUnderline(true);
    if (style.color) format.setForeground(fromRgba(*style.color));
    if (style.highlight) format.setBackground(fromRgba(*style.highlight));
    if (style.link) {
        format.setAnchor(true);
        format.setAnchorHref(QString::fromStdString(*style.link));
    }
    if (style.font_family)
        format.setFontFamilies({QString::fromStdString(*style.font_family)});
    if (style.font_size_pt) format.setFontPointSize(*style.font_size_pt);
    return format;
}

TextStyle modelStyle(const QTextCharFormat& format) {
    TextStyle style;
    style.bold = format.fontWeight() >= QFont::Bold;
    style.italic = format.fontItalic();
    style.underline = format.fontUnderline();
    if (format.hasProperty(QTextFormat::ForegroundBrush) &&
        format.foreground().style() == Qt::SolidPattern)
        style.color = toRgba(format.foreground().color()).toStdString();
    if (format.hasProperty(QTextFormat::BackgroundBrush) &&
        format.background().style() == Qt::SolidPattern)
        style.highlight = toRgba(format.background().color()).toStdString();
    if (format.isAnchor() && !format.anchorHref().isEmpty())
        style.link = format.anchorHref().toUtf8().toStdString();
    if (format.hasProperty(QTextFormat::FontFamilies)) {
        const auto families = format.fontFamilies().toStringList();
        if (!families.isEmpty()) style.font_family = families.front().toStdString();
    }
    if (format.hasProperty(QTextFormat::FontPointSize) && format.fontPointSize() > 0)
        style.font_size_pt = format.fontPointSize();
    return style;
}
} // namespace

bool populateQtDocument(QTextDocument& target, const RichTextDocument& source) {
    if (validate_rich_text(source) != TextValidation::Valid) return false;
    target.clear();
    QTextCursor cursor(&target);
    cursor.beginEditBlock();
    QTextList* activeList = nullptr;
    ListKind activeKind = ListKind::None;
    std::uint8_t activeLevel = 0;
    for (std::size_t i = 0; i < source.paragraphs.size(); ++i) {
        const auto& paragraph = source.paragraphs[i];
        QTextBlockFormat blockFormat;
        blockFormat.setHeadingLevel(static_cast<int>(paragraph.kind));
        if (i > 0) cursor.insertBlock(blockFormat);
        else cursor.setBlockFormat(blockFormat);
        if (paragraph.list != ListKind::None) {
            if (activeList && activeKind == paragraph.list &&
                activeLevel == paragraph.list_level) {
                activeList->add(cursor.block());
            } else {
                QTextListFormat listFormat;
                listFormat.setStyle(paragraph.list == ListKind::Numbered
                    ? QTextListFormat::ListDecimal : QTextListFormat::ListDisc);
                listFormat.setIndent(paragraph.list_level);
                activeList = cursor.createList(listFormat);
            }
            activeKind = paragraph.list;
            activeLevel = paragraph.list_level;
        } else {
            activeList = nullptr;
            activeKind = ListKind::None;
        }
        for (const auto& run : paragraph.runs)
            cursor.insertText(QString::fromUtf8(run.utf8), qtStyle(run.style));
    }
    cursor.endEditBlock();
    target.setModified(false);
    return true;
}

std::optional<RichTextDocument> captureQtDocument(const QTextDocument& source) {
    RichTextDocument result;
    for (QTextBlock block = source.begin(); block.isValid(); block = block.next()) {
        RichParagraph paragraph;
        const int heading = block.blockFormat().headingLevel();
        if (heading < 0 || heading > 3) return std::nullopt;
        paragraph.kind = static_cast<ParagraphKind>(heading);
        if (const QTextList* list = block.textList()) {
            const auto style = list->format().style();
            if (style == QTextListFormat::ListDecimal ||
                style == QTextListFormat::ListLowerAlpha ||
                style == QTextListFormat::ListUpperAlpha)
                paragraph.list = ListKind::Numbered;
            else
                paragraph.list = ListKind::Bullet;
            const int level = list->format().indent();
            if (level < 1 || level > 8) return std::nullopt;
            paragraph.list_level = static_cast<std::uint8_t>(level);
        }
        for (auto it = block.begin(); !it.atEnd(); ++it) {
            const QTextFragment fragment = it.fragment();
            if (!fragment.isValid()) continue;
            const QString value = fragment.text();
            if (value.contains(QChar::ObjectReplacementCharacter)) return std::nullopt;
            if (!value.isEmpty())
                paragraph.runs.push_back({value.toUtf8().toStdString(),
                                          modelStyle(fragment.charFormat())});
        }
        result.paragraphs.push_back(std::move(paragraph));
    }
    if (validate_rich_text(result) != TextValidation::Valid) return std::nullopt;
    return result;
}
