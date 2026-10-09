module mp8085 # (parameter WIDTH=16) (
            output [WIDTH-9:0] UA,
            inout [WIDTH-9:0] AD,
            output S0, S1, M_, RD_, WR_, HLDA, INTA_, RESET_OUT, SOD, CLK, ALE,
            input READY, HOLD, INTR, RST_55, RST_65, RST_75, TRAP, RESET_IN_, X1, X2, SID
);
reg [WIDTH-9:0] A,TR, B, C, D, E, H, L, IR, F, W, Z;
reg [WIDTH-1:0] SP, PC, INC_DEC;
reg [WIDTH-9:0] data_bus;
reg [WIDTH-13:0] bus_sel;

always @(*) begin
        case(bus_sel)
            4'b0000 : data_bus = A;
            4'b0001 : data_bus = B;
            4'b0010 : data_bus = C;
            4'b0011 : data_bus = D;
            4'b0100 : data_bus = E;
            4'b0101 : data_bus = F;
            4'b0110 : data_bus = H;
            4'b0111 : data_bus = L;
            4'b1000 : data_bus = W;
            4'b1001 : data_bus = Z;
            4'b1010 : data_bus = IR;
            4'b1011 : data_bus = TR;
            default : data_bus = 8'b00000000;
        endcase
end
endmodule         