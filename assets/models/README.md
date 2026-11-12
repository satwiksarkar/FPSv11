# 3D Models Architecture (assets/models/)

In accordance with the project specification and retro Minecraft/pixel-art aesthetic requirements:

1. **Primitive-Based Voxel Modeling**:
   - All 3D environment blocks, structures, props, and entities in this college laboratory project are dynamically constructed using the Qt Quick 3D built-in `#Cube` primitive model mesh.
   - This approach ensures 100% portability, eliminates external `.obj`/`.gltf` asset pack licensing issues, and fulfills the educational objective of demonstrating Qt Quick 3D component hierarchy and transformations.

2. **Hierarchical Box Models**:
   - **Player Sniper Rifle**: Assembled from scaled cubes (`scale: Qt.vector3d(...)`) representing the wooden stock, dark metal receiver, rifled barrel, and optical scope rings.
   - **Enemy Sniper**: Assembled from articulated box nodes:
     - Head box (`0.5 x 0.5 x 0.5`) with front eye-visor
     - Torso box (`0.7 x 0.7 x 0.4`)
     - Articulated arm boxes and leg boxes
   - **Reinforced Door**: Large block (`1.8 x 2.2 x 0.3`) with iron band cross-bracing and a brass sliding bolt.
   - **Flora & Environment**: Voxel tree trunks, foliage crowns, desert ruins, cacti, ice spires, and mountain horizon blocks.

3. **Performance Optimization**:
   - Built-in primitive meshes leverage hardware GPU vertex caching.
   - Nearest-neighbor texture filtering keeps pixel edges crisp without needing high-polygon meshes.
