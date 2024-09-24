import numpy as np
import gmsh


def bb_physical_group(name, dim, bottom_left, top_right, tag=-1, eps=1e-7):
    bl = [x - eps for x in bottom_left]
    tr = [x + eps for x in top_right]
    entities = gmsh.model.getEntitiesInBoundingBox(*bl, *tr, dim)
    gmsh.model.addPhysicalGroup(dim, [tag for _, tag in entities], tag=tag, name=name)


# LPBF316L, 600 C, 10 dpa
#   void size: 3.9e-5 mm
#   void density: 7.9e11 mm^-3
#   cell side length: 2e-4 mm

d = 2e-4
d2 = np.sqrt(3) / 2 * d
a = 6 * d2
b = 4.5 * d
r = 2.5e-5

sa = 2 * d2
sb = 1.5 * d

cell_centroids = np.array(
    [
        [0, 0, 0],
        [sa, 0, 0],
        [2 * sa, 0, 0],
        [3 * sa, 0, 0],
        [0.5 * sa, sb, 0],
        [1.5 * sa, sb, 0],
        [2.5 * sa, sb, 0],
        [0, 2 * sb, 0],
        [sa, 2 * sb, 0],
        [2 * sa, 2 * sb, 0],
        [3 * sa, 2 * sb, 0],
        [0.5 * sa, 3 * sb, 0],
        [1.5 * sa, 3 * sb, 0],
        [2.5 * sa, 3 * sb, 0],
    ]
)

void_centroids = np.array(
    [
        [0, d, 0],
        [0.5 * d2, 0.75 * d, 0],
        [d2, 0.5 * d, 0],
        [d2, 0, 0],
        [d2, -0.5 * d, 0],
        [0.5 * d2, -0.75 * d, 0],
        [0, -d, 0],
        [-0.5 * d2, -0.75 * d, 0],
        [-d2, -0.5 * d, 0],
        [-d2, 0, 0],
        [-d2, 0.5 * d, 0],
        [-0.5 * d2, 0.75 * d, 0],
    ]
)

centroids = []
for cell_centroid in cell_centroids:
    centroids.append(void_centroids + cell_centroid)
centroids = np.concatenate(centroids)
centroids = np.unique(centroids.round(decimals=6), axis=0)

gmsh.initialize()
gmsh.option.setNumber("General.Verbosity", 0)

base = gmsh.model.occ.addRectangle(0, 0, 0, a, b, 0)
voids = []
for centroid in centroids:
    void = gmsh.model.occ.addDisk(*centroid, r, r)
    voids.append((2, void))

gmsh.model.occ.cut([(2, base)], voids, tag=1000)
gmsh.model.occ.synchronize()
gmsh.model.mesh.setSize(gmsh.model.getEntities(0), 2e-5)
gmsh.model.mesh.setRecombine(2, 1000)
gmsh.model.addPhysicalGroup(2, [1000], name="all")
bb_physical_group("top", 1, [0, b, 0], [a, b, 0], 1001)
bb_physical_group("bottom", 1, [0, 0, 0], [a, 0, 0], 1002)
bb_physical_group("left", 1, [0, 0, 0], [0, b, 0], 1003)
bb_physical_group("right", 1, [a, 0, 0], [a, b, 0], 1004)

gmsh.model.mesh.generate(2)
gmsh.write("hex.msh")
gmsh.finalize()
