/***************************************************************
* Material didactico: Implementacion de ADD/SUB/ADDI en Verilog
* Module: InstructionMemory_min.sv
*
* ROM combinacional de 32 palabras de 32 bits, direccionada por
* palabra (instruction_address_i[31:2]). Misma forma de interfaz
* que InstructionMemory.sv del repositorio RV32I, cargada aqui con
* program_add_sub_addi.hex via $readmemh.
***************************************************************/
module InstructionMemory_min
(
    output logic [31:0]   instruction_data_o,
    input  logic [31:0]   instruction_address_i
);

    logic [31:0] instruction [31:0];

    initial
    begin
        $readmemh("program_add_sub_addi.hex", instruction);
    end

    always_comb
    begin
        instruction_data_o = instruction[instruction_address_i[31:2]];
    end

endmodule
