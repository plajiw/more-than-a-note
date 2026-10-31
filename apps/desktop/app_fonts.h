#pragma once

// Registers the bundled fonts (":/fonts/*.ttf") and makes Inter the default
// interface font, so the app, the tests and the evidence captures all draw
// with the same typefaces. Call after QGuiApplication exists and before QML
// loads.
void installInterfaceFonts();
