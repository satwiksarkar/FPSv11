#ifndef INVENTORY_H
#define INVENTORY_H

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>
#include "HealthSystem.h"
#include "GameConfig.h"

/**
 * @brief The Inventory class provides a minimalist 3-counter item container.
 * 
 * Complies with Precedence Rule 1: Stores only Food Pack, Bandage, and Medkit counts.
 * No inventory grid, no item database, no drag-and-drop.
 */
class Inventory : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum class ItemType {
        FoodPack = 0,
        Bandage = 1,
        Medkit = 2
    };
    Q_ENUM(ItemType)

    Q_PROPERTY(int foodPacks READ foodPacks NOTIFY inventoryChanged)
    Q_PROPERTY(int bandages READ bandages NOTIFY inventoryChanged)
    Q_PROPERTY(int medkits READ medkits NOTIFY inventoryChanged)
    Q_PROPERTY(int foodPackCount READ foodPacks NOTIFY inventoryChanged)
    Q_PROPERTY(int bandageCount READ bandages NOTIFY inventoryChanged)
    Q_PROPERTY(int medkitCount READ medkits NOTIFY inventoryChanged)
    Q_PROPERTY(int totalItems READ totalItems NOTIFY inventoryChanged)

    explicit Inventory(QObject *parent = nullptr);

    int foodPacks() const;
    int bandages() const;
    int medkits() const;
    int totalItems() const;

    Q_INVOKABLE int count(ItemType type) const;
    Q_INVOKABLE void addItem(ItemType type, int count = 1);
    Q_INVOKABLE bool useItem(ItemType type, HealthSystem *targetHealth);

    Q_INVOKABLE bool useFoodPack(HealthSystem *targetHealth);
    Q_INVOKABLE bool useBandage(HealthSystem *targetHealth);
    Q_INVOKABLE bool useMedkit(HealthSystem *targetHealth);

    Q_INVOKABLE void reset();

    static QString itemTypeName(ItemType type);
    static int itemHealAmount(ItemType type);

signals:
    void inventoryChanged();
    void itemAdded(ItemType type, int count);
    void itemUsed(ItemType type, int healAmount);

private:
    int m_foodPacks;
    int m_bandages;
    int m_medkits;
};

#endif // INVENTORY_H
