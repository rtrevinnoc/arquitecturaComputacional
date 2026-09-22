/***************************************************************
* Material didactico: Implementacion de ADD/SUB/ADDI en Verilog
* Module: ripple_carry_adder.sv
*
* Encadena WIDTH full_adder: el carry_out del bit i alimenta el
* carry_in del bit i+1. Asi se suma un numero de WIDTH bits con
* una sola instancia parametrizada.
***************************************************************/
module ripple_carry_adder
#(
    parameter int WIDTH = 32
)
(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic             carry_in,
    output logic [WIDTH-1:0] sum,
    output logic             carry_out
);

    logic [WIDTH:0] carry_chain;
    assign carry_chain[0] = carry_in;
    assign carry_out      = carry_chain[WIDTH];

    genvar i;
    generate
        for (i = 0; i < WIDTH; i++) begin : bit_slice
            full_adder fa
            (
                .a          (a[i]),
                .b          (b[i]),
                .carry_in   (carry_chain[i]),
                .sum        (sum[i]),
                .carry_out  (carry_chain[i+1])
            );
        end
    endgenerate

endmodule
