#include "text_card_model.h"

#include <QSet>

namespace {
QString cardId(const QVariant& card) { return card.toMap().value("id").toString(); }
} // namespace

int TextCardModel::rowCount(const QModelIndex& parent) const {
    return parent.isValid() ? 0 : static_cast<int>(cards_.size());
}

QVariant TextCardModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() >= cards_.size() || role != CardDataRole) return {};
    return cards_[index.row()];
}

QHash<int, QByteArray> TextCardModel::roleNames() const {
    return {{CardDataRole, "cardData"}};
}

void TextCardModel::sync(const QVariantList& cards) {
    QSet<QString> wanted;
    for (const QVariant& card : cards) wanted.insert(cardId(card));
    for (int row = static_cast<int>(cards_.size()) - 1; row >= 0; --row) {
        if (wanted.contains(cardId(cards_[row]))) continue;
        beginRemoveRows({}, row, row);
        cards_.removeAt(row);
        endRemoveRows();
    }
    for (int row = 0; row < cards.size(); ++row) {
        const QString id = cardId(cards[row]);
        if (row < cards_.size() && cardId(cards_[row]) == id) {
            if (cards_[row] != cards[row]) {
                cards_[row] = cards[row];
                emit dataChanged(index(row), index(row), {CardDataRole});
            }
            continue;
        }
        bool later = false;
        for (int other = row + 1; other < cards_.size() && !later; ++other)
            later = cardId(cards_[other]) == id;
        if (later) {
            // Page order changed; a reset is rare and keeps the model correct.
            beginResetModel();
            cards_ = cards;
            endResetModel();
            return;
        }
        beginInsertRows({}, row, row);
        cards_.insert(row, cards[row]);
        endInsertRows();
    }
}
