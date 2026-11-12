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
  (`ProcessorCoreMin.sv`), corriendo `program_add_sub_addi.hex`.
- **`core_min2/`**: segundo paso -- extiende `core_min/` hasta branches y
  saltos. Agrega la ALU completa (los 10 R-type y 9 I-type, ya decodificados
  por `CoreControlUnit_min2.sv`), `ComparatorUnit.sv` (branches y,
  reutilizado, `slt`/`sltu`/`slti`/`sltiu`) y el mux de PC que toma
  `jal`/`jalr`/branch tomado. Fuera de alcance todavía, decodificados como
  no-op segura: `lui`/`auipc`, loads/stores (no hay memoria de datos en
  este bloque) y `fence`/`ecall`/`ebreak`. Tres testbenches, uno por bloque
  pedagógico, cada uno con su propio programa `.hex`
  (`core_min2_alu_tb.sv`, `core_min2_branch_tb.sv`, `core_min2_jump_tb.sv`).
- **`core_full/`**: núcleo RV32I base **completo** -- las 34 instrucciones
  de `core_min2/` más `lui`/`auipc` (`CoreControlUnit_full.sv`), memoria de
  datos byte-direccionable (`DataMemory_full.sv`, `LoadAndStoreUnit.sv`:
  `lb/lh/lw/lbu/lhu/sb/sh/sw`) y `fence`/`ecall`/`ebreak` decodificadas
  como no-op. Seis testbenches -- `alu`, `branch`, `jump`, `upper`, `mem`
  y `full`, que suma un arreglo de enteros en memoria. Incluye un top-level
  para la placa **Arty A7-100T** (`core_full/fpga/`) con LEDs, switches,
  ejecución paso a paso y traza de instrucciones por UART (ver
  [Núcleo completo en FPGA](#núcleo-completo-en-fpga-arty-a7-100t)).

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
quieren instalar nada todavía), `make view-alu` (sumadores) y `make view-alu8`
(ALU) abren las ondas incluidas en el repo sin necesidad de simular ni
de WSL.

Verificar instalación (dentro de WSL):

```bash
verilator --version
surfer --version
```

### openFPGALoader

Para cargar el bitstream en la Arty A7-100T sin Vivado (ver
[Núcleo completo en FPGA](#núcleo-completo-en-fpga-arty-a7-100t)).

**Linux (Ubuntu/Debian):**

```bash
sudo apt install openfpgaloader
```

**macOS:**

```bash
brew install openfpgaloader
```

Verificar instalación:

```bash
openFPGALoader --version
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
python3 core_min/sc_run.py --view
```

Alternativa con Verilator directo:

```bash
make core-min
make wave-core-min
make view-core-min
make clean
```

### Núcleo RV32I hasta branches y saltos (`core_min2/`)

```bash
python3 core_min2/sc_run.py                 # jal/jalr (default)
python3 core_min2/sc_run.py --tb alu        # ALU completa
python3 core_min2/sc_run.py --tb branch     # los 6 branches
python3 core_min2/sc_run.py --tb jump       # jal/jalr
python3 core_min2/sc_run.py --wave          # cualquiera + Surfer
python3 core_min2/sc_run.py --tb branch --view   # onda incluida de branch, sin simular
python3 core_min2/sc_run.py --tb jump --view     # onda incluida de jump, sin simular
```

Alternativa con Verilator directo:

```bash
make core-min2-all   # los 3 bloques en secuencia
make core-min2-alu
make core-min2-branch
make core-min2-jump
make wave-core-min2-alu
make wave-core-min2-branch
make wave-core-min2-jump
make view-core-min2-branch
make view-core-min2-jump
make clean
```

`make core-min` compila y corre `core_min_tb`, que ejecuta
`program_add_sub_addi.hex` sobre `ProcessorCoreMin` y verifica el banco de
registros al final (`PASS`/`FAIL` por registro).

### Núcleo RV32I base completo (`core_full/`)

```bash
python3 core_full/sc_run.py                 # completo (default)
python3 core_full/sc_run.py --tb alu        # ALU completa
python3 core_full/sc_run.py --tb branch     # los 6 branches
python3 core_full/sc_run.py --tb jump       # jal/jalr
python3 core_full/sc_run.py --tb upper      # lui/auipc
python3 core_full/sc_run.py --tb mem        # loads/stores
python3 core_full/sc_run.py --wave          # cualquiera + Surfer
python3 core_full/sc_run.py --view          # onda incluida, sin simular
```

Alternativa con Verilator directo:

```bash
make core-full-all      # los 6 bloques, en secuencia
make core-full-alu
make core-full-branch
make core-full-jump
make core-full-upper
make core-full-mem
make core-full           # suma de un arreglo de enteros en memoria
make wave-core-full-alu  # (y el resto de wave-core-full-<bloque>)
make clean
```

### Núcleo completo en FPGA (Arty A7-100T)

`core_full/fpga/` envuelve el núcleo en `TopArtyA7.sv` y lo corre en una
Arty A7-100T (`xc7a100tcsg324-1`). El bitstream ya compilado está en
[`core_full/fpga/TopArtyA7.bit`](core_full/fpga/TopArtyA7.bit).

**Cargarlo** (placa conectada por micro-USB):

Con [openFPGALoader](https://github.com/trellis-fpga/openFPGALoader) (no requiere Vivado):

```bash
openFPGALoader -b arty_a7_100t core_full/fpga/TopArtyA7.bit
```

Con Vivado 2025.1:

```bash
vivado -mode batch -source core_full/fpga/program_fpga.tcl
```

**Recompilarlo** (si cambias RTL, el `.xdc` o el programa):

```bash
mkdir -p core_full/fpga/build && cd core_full/fpga/build
vivado -mode batch -source ../build_fpga.tcl      # genera TopArtyA7.bit aquí
vivado -mode batch -source ../program_fpga.tcl -tclargs TopArtyA7.bit
```

El núcleo (monociclo, camino crítico ~16 ns) corre a 12.5 MHz (100 MHz / 8) y
solo recibe un pulso de reloj por instrucción, así que se puede ejecutar paso
a paso y ver cada instrucción.

#### Controles

| Control | Función |
|---|---|
| `BTN0` | Reset: el PC vuelve a 0 y el núcleo queda en **pausa** |
| `BTN1` | Ejecuta **una** instrucción |
| `BTN2` | Alterna ejecución automática **lenta** (~6 instrucciones/s) |
| `BTN3` | Alterna ejecución automática **rápida** (al ritmo de la consola) |
| `SW[3:0]` | Registro a mostrar en los LEDs, x0 a x15 (`SW0` es el bit menos significativo) |

Al configurar la FPGA arranca en modo rápido: el programa corre completo y se
detiene en un `jal x0,0` (salto a sí mismo) puesto al final. Después de un
reset los registros **conservan** los valores de la corrida anterior hasta
que el programa los sobrescribe (el reset solo regresa el PC a 0).

#### Leer los LEDs

Los 8 LEDs muestran el **byte bajo** del registro elegido con `SW[3:0]`, en
binario (encendido = 1):

| Bit | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| Valor | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 |
| LED | LD4 | LD5 | LD6 | LD7 | LD0 (rojo) | LD1 (rojo) | LD2 (rojo) | LD3 (rojo) |

Los LD4-LD7 verdes son el nibble bajo y el canal rojo de los LEDs RGB LD0-LD3
el nibble alto. Ejemplo, x3 = 150 = `1001 0110`: LD3 y LD0 (rojos) y LD6 y LD5
(verdes) encendidos. El canal azul de LD3 parpadea a ~1.5 Hz como "latido" de
la FPGA, no es parte del valor. Solo se ven 8 bits: valores mayores a 255 se
truncan en los LEDs (la consola siempre muestra los 32 bits).

#### Consola serie (traza de instrucciones)

El USB-UART de la placa aparece como un puerto COM (Windows), `/dev/ttyUSB*`
(Linux) o `/dev/cu.usbserial-*` (macOS; el FTDI expone dos puertos, el UART
es el segundo). Ábranlo a **115200 baudios, 8N1, sin control de flujo** con
PuTTY, Tera Term, `screen /dev/ttyUSB1 115200` o:

```bash
pip install pyserial
python -m serial.tools.miniterm COM3 115200
```

Cada instrucción ejecutada imprime una línea:

```
PC=0038 I=005181B3 x03=00000096
    |       |        |    └ valor escrito (hex, 32 bits)
    |       |        └ registro destino (decimal); `x--=--------` si no escribe (sw, branch)
    |       └ instrucción (hex)
    └ dirección de la instrucción
```

Con el programa por defecto (suma del arreglo {10, 20, 30, 40, 50}):

```
PC=0000 I=00A00093 x01=0000000A      addi x1,x0,10
PC=0004 I=00102023 x--=--------      sw   x1,0(x0)
...
PC=0034 I=00012283 x05=0000000A      lw   x5,0(x2)       <- inicio del lazo
PC=0038 I=005181B3 x03=0000000A      add  x3,x3,x5
PC=003C I=00410113 x02=00000004      addi x2,x2,4
PC=0040 I=FFF20213 x04=00000004      addi x4,x4,-1
PC=0044 I=FE0218E3 x--=--------      bne  x4,x0,-16      <- salta a 0034
...
PC=0048 I=00302A23 x--=--------      sw   x3,20(x0)
PC=004C I=01402303 x06=00000096      lw   x6,20(x0)
PC=0050 I=0000006F x00=00000054      jal  x0,0           <- halt
```

(La última línea escribe en x0, que siempre vale 0; el valor mostrado es el
PC+4 de enlace de `jal` y se descarta.)

#### Uso

Con `BTN0` (reset) y `BTN1` (paso a paso) avanzan una instrucción a la vez;
cada pulsación de `BTN1` imprime una línea en la consola.

Con `SW = 0011` (x3) los LEDs muestran la suma acumulada durante el lazo: 10,
30, 60, 100 y 150 (`0x96`). Con `SW = 0100` (x4) se ve el contador bajar de 5
a 0; con `SW = 0010` (x2, el puntero) subir de 4 en 4 hasta 20; con
`SW = 0101` (x5) cada elemento leído. Al terminar, `SW = 0011` (x3) y
`SW = 0110` (x6) muestran ambos 150: la suma en registro y la leída de vuelta
desde memoria.

En la consola, `bne` decide el branch con el comparador: después de `PC=0044`
el PC regresa a `0034` cuatro veces y a la quinta pasa a `0048`.

Para correr otro programa: editen una copia de `program_rv32i_full.hex` (p.
ej. otros valores del arreglo), rellénenla hasta 32 palabras con `0000006F`
(el núcleo se detiene en el primer `jal x0,0`; sin ese relleno seguiría
ejecutando basura después del final), guárdenla como
`core_full/fpga/program_fpga.hex` y recompilen.

Notas de diseño: el banco de registros escribe en el flanco de **bajada** del
reloj, a mitad del ciclo, por eso un "paso" es un pulso bajo del reloj
(`BUFGCE_1`, que reposa en alto) y la traza se captura *antes* del pulso, con
la instrucción todavía sin completar. `TraceUart.sv` (transmisor 115200 8N1) y
`Debounce.sv` (antirrebote de botones) son módulos pequeños y legibles.
