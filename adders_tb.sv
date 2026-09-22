/***************************************************************
* Material didactico: Implementacion de ADD/SUB/ADDI en Verilog
* Module: adders_tb.sv
*
* Testbench exhaustivo para half_adder, full_adder (estructural y
* conductual) y ripple_carry_adder de 4 bits. Verifica cada tabla
* de verdad usada en las diapositivas antes de confiar en ellas.
***************************************************************/
`timescale 1ns/1ps

module adders_tb;

    int errors = 0;

    // -------- half_adder: tabla de verdad completa (4 filas) --------
    logic ha_a, ha_b, ha_sum, ha_carry;
    half_adder u_ha (.a(ha_a), .b(ha_b), .sum(ha_sum), .carry(ha_carry));

    // -------- full_adder: estructural vs conductual (8 filas) --------
    logic fa_a, fa_b, fa_cin, fa_sum, fa_cout;
    logic fb_sum, fb_cout;
    full_adder            u_fa (.a(fa_a), .b(fa_b), .carry_in(fa_cin), .sum(fa_sum),  .carry_out(fa_cout));
    full_adder_behavioral u_fb (.a(fa_a), .b(fa_b), .carry_in(fa_cin), .sum(fb_sum),  .carry_out(fb_cout));

    // -------- ripple_carry_adder de 4 bits --------
    logic [3:0] rca_a, rca_b;
    logic       rca_cin, rca_cout;
    logic [3:0] rca_sum;
    ripple_carry_adder #(.WIDTH(4)) u_rca
        (.a(rca_a), .b(rca_b), .carry_in(rca_cin), .sum(rca_sum), .carry_out(rca_cout));

    initial
    begin
        $dumpfile("adders_tb.fst");
        $dumpvars(0, adders_tb);
    end

    initial
    begin
        // half_adder: las 4 combinaciones de A,B
        for (int a = 0; a <= 1; a++)
        begin
            for (int b = 0; b <= 1; b++)
            begin
                ha_a = a[0]; ha_b = b[0];
                #1;
                if (ha_sum !== (a ^ b) || ha_carry !== (a & b))
                begin
                    $display("FAIL half_adder: a=%0d b=%0d sum=%0d carry=%0d", a, b, ha_sum, ha_carry);
                    errors++;
                end
            end
        end
        $display("half_adder: tabla de verdad (4 filas) verificada");

        // full_adder: las 8 combinaciones de A,B,Cin; estructural == conductual == formula
        for (int a = 0; a <= 1; a++)
        begin
            for (int b = 0; b <= 1; b++)
            begin
                for (int cin = 0; cin <= 1; cin++)
                begin
                    logic exp_sum, exp_cout;
                    fa_a = a[0]; fa_b = b[0]; fa_cin = cin[0];
                    #1;
                    exp_sum  = a[0] ^ b[0] ^ cin[0];
                    exp_cout = (a & b) | (a & cin) | (b & cin);
                    if (fa_sum !== exp_sum || fa_cout !== exp_cout)
                    begin
                        $display("FAIL full_adder (estructural): a=%0d b=%0d cin=%0d sum=%0d cout=%0d",
                                 a, b, cin, fa_sum, fa_cout);
                        errors++;
                    end
                    if (fb_sum !== exp_sum || fb_cout !== exp_cout)
                    begin
                        $display("FAIL full_adder_behavioral: a=%0d b=%0d cin=%0d sum=%0d cout=%0d",
                                 a, b, cin, fb_sum, fb_cout);
                        errors++;
                    end
                end
            end
        end
        $display("full_adder: tabla de verdad (8 filas), estructural y conductual coinciden");

        // ripple_carry_adder: 4 bits, con y sin carry_in, incluye overflow del rango
        rca_a = 4'd7;  rca_b = 4'd6; rca_cin = 1'b0; #1;
        if ({rca_cout, rca_sum} !== 5'd13) begin $display("FAIL rca 7+6"); errors++; end

        rca_a = 4'd7;  rca_b = 4'd1; rca_cin = 1'b0; #1;   // peor caso: acarreo cruza los 4 bits
        if ({rca_cout, rca_sum} !== 5'd8) begin $display("FAIL rca 7+1"); errors++; end

        rca_a = 4'd15; rca_b = 4'd1; rca_cin = 1'b0; #1;   // desborda el rango de 4 bits
        if ({rca_cout, rca_sum} !== 5'd16) begin $display("FAIL rca 15+1"); errors++; end

        rca_a = 4'd5;  rca_b = 4'd2; rca_cin = 1'b1; #1;   // usando carry_in
        if ({rca_cout, rca_sum} !== 5'd8) begin $display("FAIL rca 5+2+cin"); errors++; end

        $display("ripple_carry_adder (4 bits): sumas y acarreo en cascada verificados");

        if (errors == 0)
            $display("PASS: half_adder, full_adder y ripple_carry_adder");
        else
            $display("FAIL: %0d error(es) en los sumadores", errors);

        $finish;
    end

endmodule
