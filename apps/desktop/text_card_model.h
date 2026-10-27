#pragma once

#include <QAbstractListModel>
#include <QVariantList>

// Stable list of text cards for the editor's Repeater. Each sync changes only
// the rows that differ, so a command never recreates the delegates it does
// not touch and editing keeps focus, caret and IME state.
class TextCardModel final : public QAbstractListModel {
    Q_OBJECT

public:
    enum Role { CardDataRole = Qt::UserRole + 1 };

    using QAbstractListModel::QAbstractListModel;

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Cards are maps with an "id"; their relative order is the page order.
    void sync(const QVariantList& cards);

private:
    QVariantList cards_;
};
