import pandas as pd
import numpy as np
from matplotlib import pyplot as plt
import meshio
import trimesh

SMALL_SIZE = 8
MEDIUM_SIZE = 10
BIGGER_SIZE = 12

plt.rc("font", size=SMALL_SIZE)  # controls default text sizes
plt.rc("axes", titlesize=BIGGER_SIZE)  # fontsize of the axes title
plt.rc("axes", labelsize=BIGGER_SIZE)  # fontsize of the x and y labels
plt.rc("xtick", labelsize=BIGGER_SIZE)  # fontsize of the tick labels
plt.rc("ytick", labelsize=BIGGER_SIZE)  # fontsize of the tick labels
plt.rc("legend", fontsize=SMALL_SIZE)  # legend fontsize
plt.rc("figure", titlesize=BIGGER_SIZE)  # fontsize of the figure title

ntex = 1
nrve = 20


def porosity(filename, V):
    mesh = meshio.read(filename)
    mesh = trimesh.Trimesh(mesh.points, mesh.cells[0].data)
    return (V - mesh.area) / V


if __name__ == "__main__":
    d = 2e-4
    d2 = np.sqrt(3) / 2 * d
    a = 6 * d2
    b = 4.5 * d
    V = a * b
    t0 = 500

    for tex in range(ntex):

        fig, ax = plt.subplots(1, 2, figsize=(12, 5))

        hex = pd.read_csv("output/hex-{:02d}.csv".format(tex))
        hexi = hex["time"] > t0
        ax[0].plot(
            hex["time"][hexi] / 3600,
            hex["avg_disp"][hexi] / a * 100,
            "r-",
            linewidth=2,
            label="hex [{:.2%}]".format(porosity("output/hex-{:02d}.e".format(tex), V)),
        )
        ax[1].plot(
            hex["time"][hexi] / 3600,
            hex["disp_rate"][hexi] / a * 100 * 3600,
            "r-",
            linewidth=2,
        )

        reg = pd.read_csv("output/reg-{:02d}.csv".format(tex))
        regi = reg["time"] > t0
        ax[0].plot(
            reg["time"][regi] / 3600,
            reg["avg_disp"][regi] / a * 100,
            "b-",
            linewidth=2,
            label="reg [{:.2%}]".format(porosity("output/reg-{:02d}.e".format(tex), V)),
        )
        ax[1].plot(
            reg["time"][regi] / 3600,
            reg["disp_rate"][regi] / a * 100 * 3600,
            "b-",
            linewidth=2,
        )

        for rve in range(nrve):
            data = pd.read_csv("output/random-{:02d}-{:02d}.csv".format(tex, rve))
            datai = data["time"] > t0
            ax[0].plot(
                data["time"][datai] / 3600,
                data["avg_disp"][datai] / a * 100,
                "k--",
                label="random {} [{:.2%}]".format(
                    rve, porosity("output/random-{:02d}-{:02d}.e".format(tex, rve), V)
                ),
            )
            ax[1].plot(
                data["time"][datai] / 3600,
                data["disp_rate"][datai] / a * 100 * 3600,
                "k--",
                label="random {}".format(rve),
            )

        ax[0].set_xlabel("Time (hr)")
        ax[0].set_ylabel("Strain (%)")
        ax[0].legend()

        ax[1].set_xlabel("Time (hr)")
        ax[1].set_ylabel("Strain rate (%/hr)")
        ax[1].set_xscale("log")
        ax[1].set_yscale("log")

        fig.tight_layout()
        fig.savefig("comparison.png")
