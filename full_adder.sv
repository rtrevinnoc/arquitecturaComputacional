/***************************************************************
* Material didactico: Implementacion de ADD/SUB/ADDI en Verilog
* Module: full_adder.sv
*
* Suma dos bits mas un acarreo de entrada (carry-in). Se construye
* reutilizando dos half_adder y una compuerta OR -- la forma
* clasica de resolver el problema que dejo abierto half_adder.sv.
***************************************************************/
module full_adder
(
    input  logic a,
    input  logic b,
    input  logic carry_in,
    output logic sum,
    output logic carry_out
);

    logic sum_ab, carry_ab, carry_hs2;

    half_adder hs1 (.a(a),      .b(b),        .sum(sum_ab), .carry(carry_ab));
    half_adder hs2 (.a(sum_ab), .b(carry_in), .sum(sum),    .carry(carry_hs2));

    assign carry_out = carry_ab | carry_hs2;

endmodule

/***************************************************************
* Version conductual (behavioral) del mismo full_adder, para
* comparar contra la version estructural de arriba. Implementa
* directamente las ecuaciones S = A(+)B(+)Cin y
* Cout = AB + ACin + BCin.
***************************************************************/
module full_adder_behavioral
(
    input  logic a,
    input  logic b,
    input  logic carry_in,
    output logic sum,
    output logic carry_out
);

    assign sum       = a ^ b ^ carry_in;
    assign carry_out = (a & b) | (a & carry_in) | (b & carry_in);

endmodule
