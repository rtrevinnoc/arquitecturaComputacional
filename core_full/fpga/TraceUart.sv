/***************************************************************************
* Material didactico: core_full -- traza por UART para el Arty A7-100T
* Module: TraceUart.sv
*
* Al recibir un pulso `snap_i` captura el estado de retiro de la instruccion
* en curso y lo manda por UART (8N1) como una linea de texto de 33 bytes:
*
*     PC=0004 I=00102023 x--=--------\r\n     (sw / branch: sin escritura)
*     PC=0000 I=00A00093 x01=0000000A\r\n     (addi x1,x0,10)
*
*   PC = direccion de la instruccion (16 bits), I = instruccion en hex,
*   xNN = registro destino (decimal) y el valor que se le escribe (hex).
*
* `busy_o` esta en alto mientras se transmite la linea; el controlador de
* arriba no debe dar otro `snap_i` hasta que baje.
***************************************************************************/
module TraceUart #(
    parameter int CLKS_PER_BIT = 868            // 100 MHz / 115200 baud
)(
    input  logic        clk_i,
    input  logic        snap_i,
    input  logic [31:0] pc_i,
    input  logic [31:0] instruction_i,
    input  logic        reg_write_i,
    input  logic [4:0]  rd_i,
    input  logic [31:0] rd_value_i,
    output logic        busy_o,
    output logic        tx_o
);

    localparam int LINE_LEN = 33;

    // ---- captura -------------------------------------------------------
    logic [15:0] pc_c;
    logic [31:0] instr_c, val_c;
    logic        wr_c;
    logic [4:0]  rd_c;
    logic        active  = 1'b0;
    logic [5:0]  idx     = 6'd0;

    // ---- transmisor UART -----------------------------------------------
    logic [9:0]  shreg   = 10'h3FF;
    logic [3:0]  nbits   = 4'd0;
    logic [9:0]  baud    = 10'd0;
    logic [7:0]  tx_char;
    logic        tx_start;

    assign tx_o     = shreg[0];
    assign busy_o   = active || (nbits != 4'd0);
    assign tx_start = active && (nbits == 4'd0);

    function automatic logic [7:0] hexch(input logic [3:0] n);
        return (n < 4'd10) ? (8'h30 + {4'd0, n}) : (8'h41 + {4'd0, n} - 8'd10);
    endfunction

    logic [1:0] tens;
    logic [3:0] ones;
    always_comb begin
        tens = (rd_c >= 5'd30) ? 2'd3 : (rd_c >= 5'd20) ? 2'd2 : (rd_c >= 5'd10) ? 2'd1 : 2'd0;
        ones = 4'(rd_c - 5'(tens * 10));
    end

    always_comb begin
        tx_char = 8'h20;
        case (idx)
            6'd0:  tx_char = "P";
            6'd1:  tx_char = "C";
            6'd2:  tx_char = "=";
            6'd3:  tx_char = hexch(pc_c[15:12]);
            6'd4:  tx_char = hexch(pc_c[11:8]);
            6'd5:  tx_char = hexch(pc_c[7:4]);
            6'd6:  tx_char = hexch(pc_c[3:0]);
            6'd7:  tx_char = " ";
            6'd8:  tx_char = "I";
            6'd9:  tx_char = "=";
            6'd10: tx_char = hexch(instr_c[31:28]);
            6'd11: tx_char = hexch(instr_c[27:24]);
            6'd12: tx_char = hexch(instr_c[23:20]);
            6'd13: tx_char = hexch(instr_c[19:16]);
            6'd14: tx_char = hexch(instr_c[15:12]);
            6'd15: tx_char = hexch(instr_c[11:8]);
            6'd16: tx_char = hexch(instr_c[7:4]);
            6'd17: tx_char = hexch(instr_c[3:0]);
            6'd18: tx_char = " ";
            6'd19: tx_char = "x";
            6'd20: tx_char = wr_c ? (8'h30 + {6'd0, tens}) : "-";
            6'd21: tx_char = wr_c ? (8'h30 + {4'd0, ones}) : "-";
            6'd22: tx_char = "=";
            6'd23: tx_char = wr_c ? hexch(val_c[31:28]) : "-";
            6'd24: tx_char = wr_c ? hexch(val_c[27:24]) : "-";
            6'd25: tx_char = wr_c ? hexch(val_c[23:20]) : "-";
            6'd26: tx_char = wr_c ? hexch(val_c[19:16]) : "-";
            6'd27: tx_char = wr_c ? hexch(val_c[15:12]) : "-";
            6'd28: tx_char = wr_c ? hexch(val_c[11:8])  : "-";
            6'd29: tx_char = wr_c ? hexch(val_c[7:4])   : "-";
            6'd30: tx_char = wr_c ? hexch(val_c[3:0])   : "-";
            6'd31: tx_char = 8'h0D;
            6'd32: tx_char = 8'h0A;
            default: tx_char = 8'h20;
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (snap_i && !busy_o) begin
            pc_c    <= pc_i[15:0];
            instr_c <= instruction_i;
            wr_c    <= reg_write_i;
            rd_c    <= rd_i;
            val_c   <= rd_value_i;
            idx     <= 6'd0;
            active  <= 1'b1;
        end

        if (tx_start) begin
            shreg <= {1'b1, tx_char, 1'b0};     // stop, datos (LSB primero), start
            nbits <= 4'd10;
            baud  <= 10'd0;
            if (idx == 6'(LINE_LEN - 1)) active <= 1'b0;
            else                         idx    <= idx + 6'd1;
        end else if (nbits != 4'd0) begin
            if (baud == 10'(CLKS_PER_BIT - 1)) begin
                baud  <= 10'd0;
                shreg <= {1'b1, shreg[9:1]};
                nbits <= nbits - 4'd1;
            end else begin
                baud <= baud + 10'd1;
            end
        end
    end

endmodule
