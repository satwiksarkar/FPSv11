#include "Inventory.h"

Inventory::Inventory(QObject *parent)
    : QObject(parent)
    , m_foodPacks(1) // Start with 1 Food Pack and 1 Bandage for instant testing
    , m_bandages(1)
    , m_medkits(0)
{
}

int Inventory::foodPacks() const
{
    return m_foodPacks;
}

int Inventory::bandages() const
{
    return m_bandages;
}

int Inventory::medkits() const
{
    return m_medkits;
}

int Inventory::totalItems() const
{
    return m_foodPacks + m_bandages + m_medkits;
}

int Inventory::count(ItemType type) const
{
    switch (type) {
    case ItemType::FoodPack: return m_foodPacks;
    case ItemType::Bandage:  return m_bandages;
    case ItemType::Medkit:   return m_medkits;
    }
    return 0;
}

QString Inventory::itemTypeName(ItemType type)
{
    switch (type) {
    case ItemType::FoodPack: return QStringLiteral("Food Pack");
    case ItemType::Bandage:  return QStringLiteral("Bandage");
    case ItemType::Medkit:   return QStringLiteral("Medkit");
    }
    return QStringLiteral("Unknown");
}

int Inventory::itemHealAmount(ItemType type)
{
    switch (type) {
    case ItemType::FoodPack: return GameConfig::HEAL_FOOD_PACK;
    case ItemType::Bandage:  return GameConfig::HEAL_BANDAGE;
    case ItemType::Medkit:   return GameConfig::HEAL_MEDKIT;
    }
    return 0;
}

void Inventory::addItem(ItemType type, int count)
{
    if (count <= 0) return;

    switch (type) {
    case ItemType::FoodPack:
        m_foodPacks += count;
        break;
    case ItemType::Bandage:
        m_bandages += count;
        break;
    case ItemType::Medkit:
        m_medkits += count;
        break;
    }

    emit itemAdded(type, count);
    emit inventoryChanged();
}

bool Inventory::useItem(ItemType type, HealthSystem *targetHealth)
{
    if (!targetHealth || targetHealth->isDead() || targetHealth->health() >= targetHealth->maxHealth()) {
        return false;
    }

    if (count(type) <= 0) {
        return false;
    }

    int healAmount = itemHealAmount(type);
    switch (type) {
    case ItemType::FoodPack:
        m_foodPacks--;
        break;
    case ItemType::Bandage:
        m_bandages--;
        break;
    case ItemType::Medkit:
        m_medkits--;
        break;
    }

    targetHealth->heal(healAmount);
    emit itemUsed(type, healAmount);
    emit inventoryChanged();
    return true;
}

bool Inventory::useFoodPack(HealthSystem *targetHealth)
{
    return useItem(ItemType::FoodPack, targetHealth);
}

bool Inventory::useBandage(HealthSystem *targetHealth)
{
    return useItem(ItemType::Bandage, targetHealth);
}

bool Inventory::useMedkit(HealthSystem *targetHealth)
{
    return useItem(ItemType::Medkit, targetHealth);
}

void Inventory::reset()
{
    m_foodPacks = 1;
    m_bandages = 1;
    m_medkits = 0;
    emit inventoryChanged();
}
