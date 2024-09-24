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

N = 50
NRVE = 50
RVE_id = 0
rng = np.random.default_rng(42)

gmsh.initialize()

while RVE_id < NRVE:
    print("trying...", end="")
    centroids = []
    while len(centroids) < N:
        p = rng.random(2) * np.array([a, b])
        if centroids:
            if np.any(np.linalg.norm(np.array(centroids) - p, axis=-1) < 3 * r):
                continue
        centroids.append(p)

    gmsh.clear()
    gmsh.option.setNumber("General.Verbosity", 0)

    base = gmsh.model.occ.addRectangle(0, 0, 0, a, b, 0)
    voids = []
    for centroid in centroids:
        void = gmsh.model.occ.addDisk(*centroid, 0, r, r)
        voids.append((2, void))

    try:
        gmsh.model.occ.cut([(2, base)], voids, tag=100)
    except:
        print("OCC cut failed")
        continue
    gmsh.model.occ.synchronize()
    gmsh.model.mesh.setSize(gmsh.model.getEntities(0), 2e-5)
    gmsh.model.mesh.setRecombine(2, 100)
    gmsh.model.addPhysicalGroup(2, [100], name="all")
    bb_physical_group("top", 1, [0, b, 0], [a, b, 0], 101)
    bb_physical_group("bottom", 1, [0, 0, 0], [a, 0, 0], 102)
    bb_physical_group("left", 1, [0, 0, 0], [0, b, 0], 103)
    bb_physical_group("right", 1, [a, 0, 0], [a, b, 0], 104)

    gmsh.model.mesh.generate(2)

    elems = gmsh.model.mesh.getElementTypes(2)
    if len(elems) != 1:
        print("Meshing failed")
        continue
    elif elems[0] != 3:
        print("Meshing failed")
        continue
    else:
        print("success")

    gmsh.write("random-{:02d}.msh".format(RVE_id))

    RVE_id += 1

gmsh.finalize()
