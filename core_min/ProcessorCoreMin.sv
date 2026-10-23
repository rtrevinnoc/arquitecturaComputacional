/***************************************************************
* Material didactico: Implementacion de ADD/SUB/ADDI en Verilog
* Module: ProcessorCoreMin.sv
*
* Version reducida de ProcessorCore.sv (repositorio RV32I): el
* datapath monociclo minimo necesario para ejecutar exactamente
* add, sub y addi. Se omiten a proposito ComparatorUnit y
* LoadAndStoreUnit (branches, jal/jalr, loads/stores) -- pc_mux_sel
* siempre vale 0 aqui, asi que el PC solo avanza con PC+4.
***************************************************************/
import risc_v_32_i_pkg::*;

module ProcessorCoreMin
(
    input logic             clk_i,
    input logic             reset_i,

    output logic [31:0]     instruction_address_o,
     input logic [31:0]     instruction_data_i,

    // Puertos de retiro (usados por el testbench)
    output logic            retire_valid_o,
    output logic [31:0]     retire_pc_o,
    output logic [31:0]     retire_instruction_o,
    output logic            retire_reg_write_o,
    output logic [4:0]      retire_rd_o,
    output logic [31:0]     retire_rd_value_o,

    // Puerto de lectura de depuracion (usado por el testbench)
    input  logic [4:0]      debug_reg_addr_i,
    output logic [31:0]     debug_reg_data_o
);
    logic [31:0]PC;
    logic [31:0]pc_next,pc_update;

    logic [31:0] instruction;

    logic [31:0]immediate;
    logic [31:0]reg_source_1;
    logic [31:0]reg_source_2;

    logic [31:0]alu_port_a;
    logic [31:0]alu_port_b;
    logic [31:0]alu_output;

    logic pc_mux_sel;
    logic reg_write_enable;
    imm_select_e imm_select;
    logic execute_port_a_sel;
    logic execute_port_b_sel;
    alu_select_e alu_op_sel;
    write_data_select_e reg_write_data_sel;

    logic [31:0]reg_data;

    assign pc_next = PC + 32'd4;
    assign pc_update = pc_mux_sel ? alu_output : pc_next;

    always_ff @(posedge clk_i, posedge reset_i)
    begin
        if (reset_i)
        begin
            PC <= 32'd0;
        end
        else
        begin
            PC <= pc_update;
        end
    end

    assign instruction_address_o = PC;
    assign instruction = instruction_data_i;

    RegisterFile #(.XLEN(XLEN), .REG_ADDR_WIDTH(REG_ADDR_WIDTH)) regfile
    (
        .read_data_1_o       (reg_source_1),
        .read_data_2_o       (reg_source_2),
        .debug_read_data_o   (debug_reg_data_o),
        .debug_read_address_i(debug_reg_addr_i),
        .clk_i               (clk_i),
        .write_enable_i      (reg_write_enable),
        .write_data_i        (reg_data),
        .write_address_i     (instruction[11:7]),
        .read_address_1_i    (instruction[19:15]),
        .read_address_2_i    (instruction[24:20])
    );

    ImmediateSignExtend #(.XLEN(XLEN)) ise
    (
        .imm_o      (immediate),
        .imm_i      (instruction[31:7]),
        .imm_sel_i  (imm_select)
    );

    CoreControlUnit_min ccu
    (
        .pc_mux_sel_o                     (pc_mux_sel),
        .reg_write_enable_o               (reg_write_enable),
        .imm_select_o                     (imm_select),
        .execute_port_a_sel_o             (execute_port_a_sel),
        .execute_port_b_sel_o             (execute_port_b_sel),
        .alu_op_sel_o                     (alu_op_sel),
        .reg_write_data_sel_o             (reg_write_data_sel),
        .op_code_i                        (instruction[6:0]),
        .funct3_i                         (instruction[14:12]),
        .funct7_bit5_i                    (instruction[30])
    );

    assign alu_port_a = execute_port_a_sel ? reg_source_1 : PC;
    assign alu_port_b = execute_port_b_sel ? reg_source_2 : immediate;

    ArithmeticLogicUnit #(.XLEN(XLEN), .REG_ADDR_WIDTH(REG_ADDR_WIDTH)) alu
    (
        .alu_o          (alu_output),
        .alu_port_a_i   (alu_port_a),
        .alu_port_b_i   (alu_port_b),
        .alu_op_sel_i   (alu_op_sel)
    );

    always_comb
    begin
        unique case(reg_write_data_sel)
            RD_MUX_ALU: reg_data = alu_output;
               default: reg_data = alu_output;
        endcase
    end

    // Observacion de retiro: el procesador monociclo retira cada ciclo
    assign retire_valid_o       = 1'b1;
    assign retire_pc_o          = PC;
    assign retire_instruction_o = instruction;
    assign retire_reg_write_o   = reg_write_enable;
    assign retire_rd_o          = instruction[11:7];
    assign retire_rd_value_o    = reg_data;

endmodule
