#include "app_fonts.h"

#include <QDirIterator>
#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>

void installInterfaceFonts() {
    QDirIterator fonts(":/fonts", {"*.ttf"}, QDir::Files);
    while (fonts.hasNext()) QFontDatabase::addApplicationFont(fonts.next());

    // Inter is the interface font everywhere, also for text that names no
    // family; the system font (Segoe UI, Cantarell…) stays only as fallback.
    // Vertical-only hinting keeps baselines sharp without widening lines.
    QFont uiFont = QGuiApplication::font();
    uiFont.setFamilies({QStringLiteral("Inter")});
    uiFont.setHintingPreference(QFont::PreferVerticalHinting);
    QGuiApplication::setFont(uiFont);
}
