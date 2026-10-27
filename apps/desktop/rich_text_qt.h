#pragma once

#include "rich_text.h"

#include <QTextDocument>

#include <optional>

// Qt is an editing/rendering surface. The model DTO remains the only persisted
// representation; arbitrary Qt HTML is never stored in a notebook.
bool populateQtDocument(QTextDocument& target, const mtn::model::RichTextDocument& source);
std::optional<mtn::model::RichTextDocument> captureQtDocument(const QTextDocument& source);
