#!/usr/bin/env python3
"""Compila y corre el testbench de esta carpeta con SiliconCompiler,
usando Verilator como motor de simulacion y generando una onda .fst
para verla con Surfer.

Corre core_min_tb: el nucleo RV32I minimo (ProcessorCoreMin) que
ejecuta add/sub/addi de principio a fin.

Uso:
    python3 sc_run.py            - compila y corre core_min_tb
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

TOPMODULE = "core_min_tb"


class CoreMinDesign(Design):
    """Nucleo RV32I minimo: ALU, control, inmediato, banco de registros,
    memoria de instrucciones y el datapath que los conecta."""

    def __init__(self):
        super().__init__()
        self.set_name("core_min")
        self.set_dataroot("core_min", HERE)
        with self.active_dataroot("core_min"):
            with self.active_fileset("rtl"):
                self.set_topmodule("ProcessorCoreMin")
                self.add_file("risc_v_32_i_pkg.sv")
                self.add_file("ArithmeticLogicUnit.sv")
                self.add_file("ImmediateSignExtend.sv")
                self.add_file("RegisterFile.sv")
                self.add_file("CoreControlUnit_min.sv")
                self.add_file("InstructionMemory_min.sv")
                self.add_file("ProcessorCoreMin.sv")
            with self.active_fileset("testbench.verilator.v"):
                self.set_topmodule(TOPMODULE)
                self.add_file("core_min_tb.sv")


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
    project.set_design(CoreMinDesign())
    project.add_fileset("testbench.verilator.v")
    project.add_fileset("rtl")

    flow = Flowgraph("core_min_sim")
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
