/***************************************************************************
* Material didactico: core_full -- top-level para el Arty A7-100T
* Module: TopArtyA7.sv
*
* Envuelve ProcessorCoreFull con memoria de instrucciones y de datos (las
* mismas InstructionMemory_full/DataMemory_full que usa el testbench
* capstone, core_full_tb.sv) y lo conecta a la placa:
*
*   - btn[0]: reset (activo en alto). Deja el nucleo en pausa en el PC 0.
*   - btn[1]: ejecuta UNA instruccion (paso a paso).
*   - btn[2]: alterna ejecucion automatica LENTA (~6 instrucciones/s).
*   - btn[3]: alterna ejecucion automatica RAPIDA (al ritmo del UART).
*     Al energizar / programar la FPGA arranca en modo rapido: el programa
*     corre completo y se detiene en el `jal x0,0` final.
*   - sw[3:0]: indice de registro a mostrar (x0-x15) via el puerto de
*     depuracion debug_reg_addr_i/debug_reg_data_o.
*   - led[3:0] + led{0..3}_r: byte completo (8 bits) del registro elegido
*     -- led[3:0] el nibble bajo, led{0..3}_r el nibble alto.
*   - led3_b: parpadeo de ~1.5 Hz para confirmar que la FPGA esta viva.
*   - uart_rxd_out (pin D10, USB-UART de la placa, 115200 8N1): una linea de
*     texto por instruccion ejecutada, p. ej.
*         PC=0000 I=00A00093 x01=0000000A
*
* Reloj del nucleo: 100 MHz / 8 = 12.5 MHz (el monociclo no cierra timing a
* 100 MHz), pasado por un BUFGCE_1 que solo deja pasar un pulso por cada
* instruccion. Como el banco de registros escribe en el flanco de BAJADA a
* mitad del ciclo, el reloj reposa en alto (BUFGCE_1) y un "paso" es un
* pulso bajo: bajada (escribe registro) + subida (actualiza PC y memoria).
* Antes de cada paso se captura la salida de retiro, que es combinacional y
* describe la instruccion que esta a punto de completarse.
***************************************************************************/
module TopArtyA7 #(
    parameter int UART_CLKS_PER_BIT = 868,   // 100 MHz / 115200 baud
    parameter int DEBOUNCE_BITS     = 20     // ~10 ms a 100 MHz
)
(
    input  logic       CLK100MHZ,
    input  logic [3:0] btn,
    input  logic [3:0] sw,
    output logic [3:0] led,
    output logic       led0_r, led1_r, led2_r, led3_r,
    output logic       led3_b,
    output logic       uart_rxd_out
);

    logic clk100;
    assign clk100 = CLK100MHZ;

    // ---- botones --------------------------------------------------------
    logic rst_btn, b1_rise, b2_rise, b3_rise;
    Debounce #(.N(DEBOUNCE_BITS)) db0 (.clk_i(clk100), .in_i(btn[0]), .level_o(rst_btn), .rise_o());
    Debounce #(.N(DEBOUNCE_BITS)) db1 (.clk_i(clk100), .in_i(btn[1]), .level_o(),        .rise_o(b1_rise));
    Debounce #(.N(DEBOUNCE_BITS)) db2 (.clk_i(clk100), .in_i(btn[2]), .level_o(),        .rise_o(b2_rise));
    Debounce #(.N(DEBOUNCE_BITS)) db3 (.clk_i(clk100), .in_i(btn[3]), .level_o(),        .rise_o(b3_rise));

    // Reset de encendido: mantiene el nucleo en reset unos ciclos tras configurar.
    logic [7:0] por_cnt  = 8'd0;
    logic       por_done = 1'b0;
    always_ff @(posedge clk100)
        if (!por_done) begin
            por_cnt <= por_cnt + 8'd1;
            if (&por_cnt) por_done <= 1'b1;
        end

    logic reset;
    assign reset = rst_btn | ~por_done;

    // ---- reloj del nucleo (100 MHz / 8, con compuerta) ----------------------
    logic [2:0] clk_div = 3'd0;
    always_ff @(posedge clk100)
        clk_div <= clk_div + 3'd1;

    logic core_ce = 1'b0;
    logic clk;
    BUFGCE_1 core_clk_bufg (.I(clk_div[2]), .CE(core_ce), .O(clk));

    // ---- memorias y nucleo --------------------------------------------------
    logic [31:0] instr_addr, instr_data;
    logic        write_enable;
    logic [31:0] write_data;
    logic [3:0]  write_data_strobe;
    logic [31:0] address;
    logic [31:0] read_data;

    logic        retire_valid;
    logic [31:0] retire_pc, retire_instruction, retire_rd_value;
    logic        retire_reg_write;
    logic [4:0]  retire_rd;

    logic [31:0] debug_reg_data;

    InstructionMemory_full #(.PROGRAM_FILE("program_fpga.hex"), .NUM_WORDS(32)) imem
    (
        .instruction_data_o   (instr_data),
        .instruction_address_i(instr_addr)
    );

    DataMemory_full #(.XLEN(32), .MEM_BYTES(256)) dmem
    (
        .read_data_o          (read_data),
        .clk_i                (clk),
        .write_enable_i       (write_enable),
        .write_data_i         (write_data),
        .write_data_strobe_i  (write_data_strobe),
        .address_i            (address)
    );

    ProcessorCoreFull core
    (
        .clk_i                 (clk),
        .reset_i               (reset),
        .instruction_address_o (instr_addr),
        .instruction_data_i    (instr_data),
        .read_data_i           (read_data),
        .write_enable_o        (write_enable),
        .write_data_o          (write_data),
        .write_data_strobe_o   (write_data_strobe),
        .address_o             (address),
        .retire_valid_o        (retire_valid),
        .retire_pc_o           (retire_pc),
        .retire_instruction_o  (retire_instruction),
        .retire_reg_write_o    (retire_reg_write),
        .retire_rd_o           (retire_rd),
        .retire_rd_value_o     (retire_rd_value),
        .debug_reg_addr_i      ({1'b0, sw}),
        .debug_reg_data_o      (debug_reg_data)
    );

    // ---- traza por UART -----------------------------------------------------
    logic snap, trace_busy;
    TraceUart #(.CLKS_PER_BIT(UART_CLKS_PER_BIT)) trace
    (
        .clk_i         (clk100),
        .snap_i        (snap),
        .pc_i          (retire_pc),
        .instruction_i (retire_instruction),
        .reg_write_i   (retire_reg_write),
        .rd_i          (retire_rd),
        .rd_value_i    (retire_rd_value),
        .busy_o        (trace_busy),
        .tx_o          (uart_rxd_out)
    );

    // ---- control de ejecucion (dominio de 100 MHz) -------------------------
    // mode: 0 = pausa, 1 = automatico lento, 2 = automatico rapido
    logic [1:0]  mode     = 2'd2;
    logic        halted   = 1'b0;
    logic        step_req = 1'b0;
    logic        step_go  = 1'b0;
    logic [23:0] slow_cnt = 24'd0;

    logic want_step;
    assign want_step = b1_rise
                     | (!halted && ((mode == 2'd2) || (mode == 2'd1 && slow_cnt == 24'd0)));

    always_ff @(posedge clk100) begin
        slow_cnt <= slow_cnt + 24'd1;
        snap     <= 1'b0;

        // modo / halt
        if (rst_btn) begin
            mode   <= 2'd0;
            halted <= 1'b0;
        end else begin
            if (b2_rise) mode <= (mode == 2'd1) ? 2'd0 : 2'd1;
            if (b3_rise) mode <= (mode == 2'd2) ? 2'd0 : 2'd2;
        end

        // peticion de paso (pegajosa hasta que se atiende)
        if (want_step) step_req <= 1'b1;

        // Con el reloj en reposo (alto) se captura la instruccion actual y se
        // programa el pulso: CE alto en los conteos 6-7 deja pasar una bajada
        // y su subida, y se baja en el conteo 7.
        if (step_req && !step_go && !trace_busy && clk_div == 3'd4) begin
            snap     <= 1'b1;
            step_go  <= 1'b1;
            step_req <= 1'b0;
            if (retire_instruction == 32'h0000006F) halted <= 1'b1;   // jal x0,0
        end
        if (step_go && clk_div == 3'd5) begin
            core_ce <= 1'b1;
            step_go <= 1'b0;
        end
        if (clk_div == 3'd7) core_ce <= 1'b0;

        if (reset) begin
            step_req <= 1'b0;
            step_go  <= 1'b0;
            core_ce  <= 1'b0;
            snap     <= 1'b0;
        end
    end

    // ---- indicadores --------------------------------------------------------
    assign led    = debug_reg_data[3:0];
    assign led0_r = debug_reg_data[4];
    assign led1_r = debug_reg_data[5];
    assign led2_r = debug_reg_data[6];
    assign led3_r = debug_reg_data[7];

    logic [25:0] heartbeat_counter = 26'd0;
    always_ff @(posedge clk100)
        heartbeat_counter <= heartbeat_counter + 26'd1;
    assign led3_b = heartbeat_counter[25];

endmodule
