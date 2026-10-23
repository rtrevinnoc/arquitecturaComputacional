# Arquitectura Computacional — RTL y testbenches

## Contenido

Cada tema vive en su propia carpeta, con su RTL y su testbench juntos:

- **`adders/`**: half adder, full adder y un ripple-carry adder de 4 bits
  (`half_adder.sv`, `full_adder.sv`, `ripple_carry_adder.sv`, `adders_tb.sv`).
- **`alu8/`**: ALU de 8 bits (`alu8.v`, `alu8_tb.v`) en Verilog puro (sin
  SystemVerilog), pensada para el presupuesto de pines de un proyecto
  digital de Silicluster v3 (14 entradas / 14 salidas + clk + rst).
- **`core_min/`**: primer paso hacia un núcleo RV32I completo -- un
  datapath monociclo mínimo que ejecuta exactamente `add`, `sub` y `addi`:
  el ALU real (`ArithmeticLogicUnit.sv`), el decodificador
  (`CoreControlUnit_min.sv`), el generador de inmediato
  (`ImmediateSignExtend.sv`), el banco de registros (`RegisterFile.sv`),
  memoria de instrucciones (`InstructionMemory_min.sv`) y el núcleo
  (`ProcessorCoreMin.sv`), corriendo `program_add_sub_addi.hex`. Esta
  carpeta se ira ampliando en clases futuras hasta llegar a un RV32I
  completo.

## Instalación

```bash
pip install siliconcompiler
```

### Verilator + Surfer

**Linux (Ubuntu/Debian):**

```bash
sc-install -group digital-simulation
```

**macOS:**

```bash
brew install verilator
```

Surfer: <https://surfer-project.org>

**Windows:**

Instalar WSL: <https://learn.microsoft.com/windows/wsl/install>

Dentro de WSL (Ubuntu), seguir las instrucciones de Linux de arriba
(`pip install siliconcompiler` + `sc-install -group digital-simulation`).

Surfer (nativo, sin WSL): <https://gitlab.com/api/v4/projects/42073614/jobs/artifacts/main/raw/surfer_win.zip?job=windows_build>

Si ya tienen Surfer instalado pero no Verilator/siliconcompiler (o no
quieren instalar nada todavia), `make view-alu` (sumadores) y `make view-alu8`
(ALU) abren las ondas incluidas en el repo sin necesidad de simular ni
de WSL.

Verificar instalación (dentro de WSL):

```bash
verilator --version
surfer --version
```

## Ejecutar

### Sumadores (`adders/`)

```bash
python3 adders/sc_run.py
python3 adders/sc_run.py --wave
python3 adders/sc_run.py --view
```

Alternativa con Verilator directo:

```bash
make adders
make wave-adders
make view
make clean
```

### ALU de 8 bits (`alu8/`)

```bash
python3 alu8/sc_run.py
python3 alu8/sc_run.py --wave
python3 alu8/sc_run.py --view
```

Alternativa con Verilator directo:

```bash
make alu8
make wave-alu8
make view-alu8
make clean
```

`make alu8` (o `sc_run.py`) compila y corre `alu8_tb`, que imprime
`PASS`/`FAIL` por cada operación verificada.

### Núcleo RV32I mínimo (`core_min/`)

```bash
python3 core_min/sc_run.py
python3 core_min/sc_run.py --wave
```

Alternativa con Verilator directo:

```bash
make core-min
make wave-core-min
make clean
```

`make core-min` compila y corre `core_min_tb`, que ejecuta
`program_add_sub_addi.hex` sobre `ProcessorCoreMin` y verifica el banco de
registros al final (`PASS`/`FAIL` por registro).
