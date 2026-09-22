# Compila y corre el ejemplo de esta presentacion con Verilator,
# generando ondas .fst para verlas con Surfer.
#
# Uso:
#   make adders       - compila y corre half/full/ripple_carry_adder
#   make wave-adders  - corre adders y abre adders_tb.fst en Surfer
#   make view         - abre el waveform.fst incluido, sin simular
#   make clean        - borra binarios y ondas generadas
#
# Nota: el proyecto vive bajo una ruta con espacios (iCloud Drive), y el
# Makefile que genera Verilator internamente no soporta eso -- por eso
# --Mdir apunta fuera de esta carpeta, a $(BUILD_DIR).

BUILD_DIR  := $(HOME)/verilator_builds
LZ4_PREFIX := /opt/homebrew/opt/lz4

VLFLAGS := --binary --timing -sv --trace-fst \
           -Wno-IEEEMAYDEPRECATE -Wno-TIMESCALEMOD -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND \
           -Wno-CASEINCOMPLETE -Wno-LATCH -Wno-UNOPTFLAT \
           -CFLAGS "-I$(LZ4_PREFIX)/include" -LDFLAGS "-L$(LZ4_PREFIX)/lib -llz4"

ADDERS_SRCS := half_adder.sv full_adder.sv ripple_carry_adder.sv adders_tb.sv

.PHONY: adders wave-adders view clean

adders:
	verilator $(VLFLAGS) --top-module adders_tb --Mdir $(BUILD_DIR)/adders_tb $(ADDERS_SRCS) -o sim_adders_tb
	$(BUILD_DIR)/adders_tb/sim_adders_tb

wave-adders: adders
	surfer adders_tb.fst

view:
	surfer waveform.fst

clean:
	rm -rf $(BUILD_DIR)/adders_tb *.fst
