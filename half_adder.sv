/***************************************************************
* Material didactico: Implementacion de ADD/SUB/ADDI en Verilog
* Module: half_adder.sv
*
* Suma dos bits sueltos. No tiene entrada de acarreo (carry-in),
* por lo que no puede encadenarse para sumar numeros de mas de
* un bit -- ese problema se resuelve en full_adder.sv.
***************************************************************/
module half_adder
(
    input  logic a,
    input  logic b,
    output logic sum,
    output logic carry
);

    assign sum   = a ^ b;
    assign carry = a & b;

endmodule
