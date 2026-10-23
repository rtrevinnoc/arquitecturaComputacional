# Compila y corre los ejemplos de esta presentacion con Verilator,
# generando ondas para verlas con Surfer.
#
# Uso:
#   make adders       - compila y corre half/full/ripple_carry_adder (adders/)
#   make wave-adders  - corre adders y abre adders/adders_tb.fst en Surfer
#   make view         - abre adders/waveform.fst incluido, sin simular
#   make alu8         - compila y corre alu8_tb (alu8/), reporta PASS/FAIL
#   make wave-alu8    - corre alu8 y abre alu8/alu8_tb.vcd en Surfer
#   make view-alu8    - abre alu8/waveform.vcd incluido, sin simular
#   make core-min     - compila y corre core_min_tb: nucleo RV32I minimo (add/sub/addi)
#   make wave-core-min   - corre core-min y abre la onda en Surfer
#   make clean        - borra binarios y ondas generadas
#
# Nota: el proyecto vive bajo una ruta con espacios (iCloud Drive), y el
# Makefile que genera Verilator internamente no soporta eso -- por eso
# --Mdir apunta fuera de esta carpeta, a $(BUILD_DIR).

BUILD_DIR  := $(HOME)/verilator_builds
LZ4_PREFIX := /opt/homebrew/opt/lz4

ADDERS_DIR   := adders
ALU8_DIR     := alu8
CORE_MIN_DIR := core_min

VLFLAGS := --binary --timing -sv --trace-fst \
           -Wno-IEEEMAYDEPRECATE -Wno-TIMESCALEMOD -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND \
           -Wno-CASEINCOMPLETE -Wno-LATCH -Wno-UNOPTFLAT \
           -CFLAGS "-I$(LZ4_PREFIX)/include" -LDFLAGS "-L$(LZ4_PREFIX)/lib -llz4"

# alu8/ es Verilog puro (sin SystemVerilog), por eso no lleva -sv: asi
# el flujo de compilacion valida lo mismo que exige Silicluster v3.
ALU8_VLFLAGS := --binary --timing --trace-fst \
           -Wno-IEEEMAYDEPRECATE -Wno-TIMESCALEMOD -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND \
           -Wno-CASEINCOMPLETE -Wno-LATCH -Wno-UNOPTFLAT \
           -CFLAGS "-I$(LZ4_PREFIX)/include" -LDFLAGS "-L$(LZ4_PREFIX)/lib -llz4"

ADDERS_SRCS := $(ADDERS_DIR)/half_adder.sv $(ADDERS_DIR)/full_adder.sv \
               $(ADDERS_DIR)/ripple_carry_adder.sv $(ADDERS_DIR)/adders_tb.sv
ALU8_SRCS   := $(ALU8_DIR)/alu8.v $(ALU8_DIR)/alu8_tb.v

CORE_MIN_SRCS   := $(CORE_MIN_DIR)/risc_v_32_i_pkg.sv $(CORE_MIN_DIR)/ArithmeticLogicUnit.sv \
                    $(CORE_MIN_DIR)/ImmediateSignExtend.sv $(CORE_MIN_DIR)/RegisterFile.sv \
                    $(CORE_MIN_DIR)/CoreControlUnit_min.sv $(CORE_MIN_DIR)/InstructionMemory_min.sv \
                    $(CORE_MIN_DIR)/ProcessorCoreMin.sv $(CORE_MIN_DIR)/core_min_tb.sv

.PHONY: adders wave-adders view alu8 wave-alu8 view-alu8 \
        core-min wave-core-min clean

adders:
	verilator $(VLFLAGS) --top-module adders_tb --Mdir $(BUILD_DIR)/adders_tb $(ADDERS_SRCS) -o sim_adders_tb
	cd $(ADDERS_DIR) && $(BUILD_DIR)/adders_tb/sim_adders_tb

wave-adders: adders
	surfer $(ADDERS_DIR)/adders_tb.fst

view-adders:
	surfer $(ADDERS_DIR)/waveform.fst

alu8:
	verilator $(ALU8_VLFLAGS) --top-module alu8_tb --Mdir $(BUILD_DIR)/alu8_tb $(ALU8_SRCS) -o sim_alu8_tb
	cd $(ALU8_DIR) && $(BUILD_DIR)/alu8_tb/sim_alu8_tb

wave-alu8: alu8
	surfer $(ALU8_DIR)/alu8_tb.vcd

view-alu8:
	surfer $(ALU8_DIR)/waveform.vcd

core-min:
	verilator $(VLFLAGS) --top-module core_min_tb --Mdir $(BUILD_DIR)/core_min_tb $(CORE_MIN_SRCS) -o sim_core_min_tb
	cd $(CORE_MIN_DIR) && $(BUILD_DIR)/core_min_tb/sim_core_min_tb

wave-core-min: core-min
	surfer $(CORE_MIN_DIR)/core_min_tb.fst

clean:
	rm -rf $(BUILD_DIR)/adders_tb $(BUILD_DIR)/alu8_tb $(BUILD_DIR)/core_min_tb \
	       $(ADDERS_DIR)/adders_tb.fst $(ALU8_DIR)/alu8_tb.fst $(ALU8_DIR)/alu8_tb.vcd \
	       $(CORE_MIN_DIR)/core_min_tb.fst
