#ifndef TILEMAPINSTANCING_H
#define TILEMAPINSTANCING_H

#include <QQuick3DInstancing>
#include <QColor>
#include <QtQml/qqmlregistration.h>
#include "LevelManager.h"

/**
 * @brief The TileMapInstancing class converts 2D tile grid data into GPU-instanced 3D voxel blocks.
 * 
 * Subclasses QQuick3DInstancing to supply instance tables directly to Qt Quick 3D Model elements.
 * Generates stacked voxel columns with deterministic per-instance color variation to satisfy
 * retro Minecraft aesthetics without flat appearance.
 */
class TileMapInstancing : public QQuick3DInstancing
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(LevelManager* levelManager READ levelManager WRITE setLevelManager NOTIFY levelManagerChanged)
    Q_PROPERTY(int tileType READ tileType WRITE setTileType NOTIFY tileTypeChanged)
    Q_PROPERTY(int blockHeight READ blockHeight WRITE setBlockHeight NOTIFY blockHeightChanged)
    Q_PROPERTY(QColor baseColor READ baseColor WRITE setBaseColor NOTIFY baseColorChanged)
    Q_PROPERTY(int instanceCount READ instanceCount NOTIFY instanceCountChanged)

public:
    explicit TileMapInstancing(QQuick3DObject *parent = nullptr);

    LevelManager* levelManager() const;
    void setLevelManager(LevelManager *mgr);

    int tileType() const;
    void setTileType(int type);

    int blockHeight() const;
    void setBlockHeight(int height);

    QColor baseColor() const;
    void setBaseColor(const QColor &color);

    int instanceCount() const;

signals:
    void levelManagerChanged();
    void tileTypeChanged();
    void blockHeightChanged();
    void baseColorChanged();
    void instanceCountChanged();

protected:
    QByteArray getInstanceBuffer(int *instanceCount) override;

private:
    LevelManager *m_levelManager;
    int m_tileType;
    int m_blockHeight;
    QColor m_baseColor;
    int m_cachedInstanceCount;
};

#endif // TILEMAPINSTANCING_H
