/***************************************************************************
* Material didactico: core_full -- antirrebote de boton para el Arty A7-100T
* Module: Debounce.sv
*
* Sincroniza la entrada (2 FF) y solo cambia `level_o` cuando la entrada
* lleva estable 2^N ciclos (N=20 a 100 MHz ~ 10 ms). `rise_o` es un pulso de
* un ciclo cuando `level_o` pasa de 0 a 1.
***************************************************************************/
module Debounce #(parameter int N = 20)
(
    input  logic clk_i,
    input  logic in_i,
    output logic level_o,
    output logic rise_o
);
    logic s0 = 1'b0, s1 = 1'b0;
    logic [N-1:0] cnt = '0;
    logic level = 1'b0;

    assign level_o = level;

    always_ff @(posedge clk_i) begin
        s0 <= in_i;
        s1 <= s0;
        rise_o <= 1'b0;
        if (s1 == level) begin
            cnt <= '0;
        end else begin
            cnt <= cnt + 1'b1;
            if (&cnt) begin
                level  <= s1;
                rise_o <= s1;
                cnt    <= '0;
            end
        end
    end
endmodule
