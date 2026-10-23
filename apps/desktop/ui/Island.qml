import QtQuick

// A panel "island": a surface that floats on the window base with a small gap
// (Theme.space.island) around it and a subtle radius. Clipping is rectangular,
// so content keeps a small inset to leave the rounded corners visible.
Rectangle {
    radius: Theme.radius.island
    color: Theme.color.surface
    border.width: 1
    border.color: Theme.color.borderSubtle
    clip: true
}
