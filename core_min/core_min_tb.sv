/***************************************************************
* Material didactico: Implementacion de ADD/SUB/ADDI en Verilog
* Module: core_min_tb.sv
*
* Ejecuta program_add_sub_addi.hex sobre ProcessorCoreMin y
* verifica el contenido final del banco de registros via el
* puerto de depuracion (debug_reg_addr_i / debug_reg_data_o).
*
*   0x00: addi x1, x0, 5     -> x1 = 5
*   0x04: addi x2, x0, 10    -> x2 = 10
*   0x08: add  x3, x1, x2    -> x3 = 15
*   0x0C: sub  x4, x3, x1    -> x4 = 10
*   0x10: addi x5, x4, -3    -> x5 = 7
***************************************************************/
`timescale 1ns/1ps

module core_min_tb;

    logic clk;
    logic reset;
    int   errors;

    logic [31:0] instr_addr;
    logic [31:0] instr_data;
    logic [4:0]  debug_addr;
    logic [31:0] debug_data;

    logic        retire_valid;
    logic [31:0] retire_pc;
    logic [31:0] retire_instruction;
    logic        retire_reg_write;
    logic [4:0]  retire_rd;
    logic [31:0] retire_rd_value;

    InstructionMemory_min imem
    (
        .instruction_data_o   (instr_data),
        .instruction_address_i(instr_addr)
    );

    ProcessorCoreMin dut
    (
        .clk_i                 (clk),
        .reset_i               (reset),
        .instruction_address_o (instr_addr),
        .instruction_data_i    (instr_data),
        .retire_valid_o        (retire_valid),
        .retire_pc_o           (retire_pc),
        .retire_instruction_o  (retire_instruction),
        .retire_reg_write_o    (retire_reg_write),
        .retire_rd_o           (retire_rd),
        .retire_rd_value_o     (retire_rd_value),
        .debug_reg_addr_i      (debug_addr),
        .debug_reg_data_o      (debug_data)
    );

    always #5 clk = ~clk;

    task automatic check_reg(input logic [4:0] rnum, input logic [31:0] exp, input string name);
        debug_addr = rnum;
        #1;
        if (debug_data !== exp)
        begin
            $display("FAIL %s: x%0d = %0d (esperaba %0d)", name, rnum, debug_data, exp);
            errors++;
        end
        else
        begin
            $display("OK   %s: x%0d = %0d", name, rnum, debug_data);
        end
    endtask

    initial
    begin
        $dumpfile("core_min_tb.fst");
        $dumpvars(0, core_min_tb);
    end

    initial
    begin
        clk = 0;
        reset = 1;
        debug_addr = 0;
        errors = 0;

        @(negedge clk);
        reset = 0;

        repeat (5) @(negedge clk);

        if (retire_valid)
            $display("Ultima instruccion retirada: PC=0x%08h instr=0x%08h rd=x%0d valor=%0d",
                      retire_pc, retire_instruction, retire_rd, retire_rd_value);

        check_reg(1, 32'd5,  "x1 (addi x1, x0, 5)");
        check_reg(2, 32'd10, "x2 (addi x2, x0, 10)");
        check_reg(3, 32'd15, "x3 (add  x3, x1, x2)");
        check_reg(4, 32'd10, "x4 (sub  x4, x3, x1)");
        check_reg(5, 32'd7,  "x5 (addi x5, x4, -3)");

        if (errors == 0)
            $display("PASS: ProcessorCoreMin ejecuto add/sub/addi correctamente");
        else
            $display("FAIL: ProcessorCoreMin con %0d error(es)", errors);

        $finish;
    end

endmodule
