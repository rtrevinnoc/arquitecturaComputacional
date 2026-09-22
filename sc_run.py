#!/usr/bin/env python3
"""Compila y corre el testbench de esta carpeta con SiliconCompiler,
usando Verilator como motor de simulacion y generando una onda .fst
para verla con Surfer.

Uso:
    python3 sc_run.py            - compila y corre half/full/ripple_carry_adder
    python3 sc_run.py --wave     - igual, y ademas abre la onda en Surfer
    python3 sc_run.py --view     - abre el waveform.fst incluido, sin simular
"""
import argparse
import os
import subprocess

from siliconcompiler import Design, Sim, Flowgraph
from siliconcompiler.tools.verilator import compile as verilator_compile
from siliconcompiler.tools.verilator.compile import CompileTask
from siliconcompiler.tools.execute.exec_input import ExecInputTask

HERE = os.path.dirname(os.path.abspath(__file__))

# En macOS con Homebrew, --trace-fst de Verilator necesita liblz4, que no
# vive en una ruta de include/link por defecto. En Linux (apt/dnf) no hace
# falta nada de esto.
LZ4_PREFIXES = ("/opt/homebrew/opt/lz4", "/usr/local/opt/lz4")

VERILATOR_WARNINGS_OFF = [
    "-Wno-WIDTHEXPAND", "-Wno-WIDTHTRUNC", "-Wno-CASEINCOMPLETE",
    "-Wno-UNOPTFLAT", "-Wno-TIMESCALEMOD", "-Wno-IEEEMAYDEPRECATE", "-Wno-LATCH",
]

TOPMODULE = "adders_tb"


class AddersDesign(Design):
    """half_adder + full_adder + ripple_carry_adder (4 bits)."""

    def __init__(self):
        super().__init__()
        self.set_name("adders")
        self.set_dataroot("adders", HERE)
        with self.active_dataroot("adders"):
            with self.active_fileset("rtl"):
                self.set_topmodule("ripple_carry_adder")
                self.add_file("half_adder.sv")
                self.add_file("full_adder.sv")
                self.add_file("ripple_carry_adder.sv")
            with self.active_fileset("testbench.verilator.v"):
                self.set_topmodule(TOPMODULE)
                self.add_file("adders_tb.sv")


def _configure_verilator_task(project):
    task = CompileTask.find_task(project)
    task.set_verilator_main(True)
    task.add_commandline_option(["--trace-fst", *VERILATOR_WARNINGS_OFF])
    for lz4_prefix in LZ4_PREFIXES:
        if os.path.isdir(lz4_prefix):
            task.add_verilator_cincludes(f"{lz4_prefix}/include")
            task.add_verilator_ldflags([f"-L{lz4_prefix}/lib", "-llz4"])
            break


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wave", action="store_true", help="abrir la onda en Surfer al terminar")
    parser.add_argument("--view", action="store_true",
                        help="abrir el waveform.fst incluido, sin simular")
    args = parser.parse_args()

    if args.view:
        subprocess.call(["surfer", os.path.join(HERE, "waveform.fst")])
        return

    project = Sim()
    project.set_design(AddersDesign())
    project.add_fileset("testbench.verilator.v")
    project.add_fileset("rtl")

    flow = Flowgraph("adders_sim")
    flow.node("compile", verilator_compile.CompileTask())
    flow.node("simulate", ExecInputTask())
    flow.edge("compile", "simulate")
    project.set_flow(flow)

    _configure_verilator_task(project)

    project.run()
    project.summary()

    if args.wave:
        fst = project.find_result(step="simulate", index="0", directory=".",
                                  filename=f"{TOPMODULE}.fst")
        if fst:
            project.show(fst)
        else:
            print(f"No se encontro la onda {TOPMODULE}.fst")


if __name__ == "__main__":
    main()
