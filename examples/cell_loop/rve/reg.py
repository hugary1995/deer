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
b = 4.58 * d
r = 2.5e-5
s = 1.35e-4

gmsh.initialize()
gmsh.option.setNumber("General.Verbosity", 0)

base = gmsh.model.occ.addRectangle(0, 0, 0, a, b, 0)
voids = []
for x in np.arange(s / 3, a, s):
    for y in np.arange(s / 2.5, b, s):
        void = gmsh.model.occ.addDisk(x, y, 0.0, r, r)
        voids.append((2, void))

gmsh.model.occ.cut([(2, base)], voids, tag=100)
gmsh.model.occ.synchronize()
gmsh.model.mesh.setSize(gmsh.model.getEntities(0), 2e-5)
gmsh.model.mesh.setRecombine(2, 100)
gmsh.model.addPhysicalGroup(2, [100], name="all")
bb_physical_group("top", 1, [0, b, 0], [a, b, 0], 101)
bb_physical_group("bottom", 1, [0, 0, 0], [a, 0, 0], 102)
bb_physical_group("left", 1, [0, 0, 0], [0, b, 0], 103)
bb_physical_group("right", 1, [a, 0, 0], [a, b, 0], 104)

gmsh.model.mesh.generate(2)
gmsh.write("reg.msh")
gmsh.finalize()
