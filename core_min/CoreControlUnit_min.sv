/***************************************************************************
* Material didactico: Implementacion de ADD/SUB/ADDI en Verilog
* Module: CoreControlUnit_min.sv
*
* Version reducida de CoreControlUnit.sv (repositorio RV32I) que solo
* decodifica lo necesario para ADD, SUB y ADDI:
*   - OP_R_TYPE     (0110011): add / sub, distinguidas por funct7_bit5_i
*   - OP_I_ALU_TYPE (0010011): addi
*
* El archivo completo del repositorio maneja ademas loads, stores,
* branches, jal, jalr, lui y auipc con la misma estructura de case.
***************************************************************************/
import risc_v_32_i_pkg::*;

module CoreControlUnit_min
(
    output logic                    pc_mux_sel_o,
    output logic                    reg_write_enable_o,
    output imm_select_e             imm_select_o,
    output logic                    execute_port_a_sel_o,
    output logic                    execute_port_b_sel_o,
    output alu_select_e             alu_op_sel_o,
    output write_data_select_e      reg_write_data_sel_o,
    input logic [6:0]               op_code_i,
    input logic [2:0]               funct3_i,
    input logic                     funct7_bit5_i
);

    localparam OP_R_TYPE     = 7'b0110011;
    localparam OP_I_ALU_TYPE = 7'b0010011;

    always_comb
    begin

        unique case(op_code_i)
            OP_R_TYPE:
            begin
                pc_mux_sel_o          = 1'b0;
                reg_write_enable_o    = 1'b1;
                imm_select_o          = IMM_UNKNOWN_TYPE;
                execute_port_a_sel_o  = 1'b1;
                execute_port_b_sel_o  = 1'b1;
                reg_write_data_sel_o  = RD_MUX_ALU;

                unique case({funct7_bit5_i,funct3_i})
                    4'b0000: alu_op_sel_o = OP_ADD;  // add
                    4'b1000: alu_op_sel_o = OP_SUB;  // sub
                    default: alu_op_sel_o = OP_UNKNOWN;
                endcase
            end
            OP_I_ALU_TYPE:
            begin
                pc_mux_sel_o          = 1'b0;
                reg_write_enable_o    = 1'b1;
                imm_select_o          = IMM_I_TYPE;
                execute_port_a_sel_o  = 1'b1;
                execute_port_b_sel_o  = 1'b0;
                reg_write_data_sel_o  = RD_MUX_ALU;

                unique case(funct3_i)
                    3'b000:  alu_op_sel_o = OP_ADD;  // addi
                    default: alu_op_sel_o = OP_UNKNOWN;
                endcase
            end
            default:
            begin
                pc_mux_sel_o          = 1'b0;
                reg_write_enable_o    = 1'b0;
                imm_select_o          = IMM_UNKNOWN_TYPE;
                execute_port_a_sel_o  = 1'b0;
                execute_port_b_sel_o  = 1'b0;
                alu_op_sel_o          = OP_UNKNOWN;
                reg_write_data_sel_o  = RD_MUX_N_A;
            end
        endcase

    end
endmodule
