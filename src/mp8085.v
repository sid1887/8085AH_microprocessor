`define ADD  8'b10000000
`define ADDC 8'b10001000
`define SUB  8'b10010000
`define SUBB 8'b10011000
`define ANA  8'b10100000
`define ORA  8'b10110000
`define XRA  8'b10101000
`define CMA  8'b00101111

module alu_8085 # (parameter DATA_WIDTH=16) (
    input [DATA_WIDTH-9 : 0] operand_a, operand_b,
    input [DATA_WIDTH-9:0] alu_op,
    input cin,
    output reg [DATA_WIDTH-9 : 0] alu_out,
    output reg cout, sign, parity, aux_carry, zero
    );

    reg [DATA_WIDTH-8:0] alu_full_result_sum;
    reg [DATA_WIDTH-8:0] alu_full_result_diff;
    reg [DATA_WIDTH-8:0] low_nibble_sum;
    reg [DATA_WIDTH-8:0] low_nibble_diff;

    always @(*) begin
        low_nibble_sum = 0;
        low_nibble_diff = 0;
        alu_full_result_sum = 0;
        alu_full_result_diff = 0;
        alu_out = 0;
        cout = 0;
        sign = 0;
        parity = 0;
        aux_carry = 0;
        zero = 0;
        case(alu_op)
            `ANA: begin
                alu_out = operand_a & operand_b;
                aux_carry = 1;
            end

            `ORA: begin
                alu_out = operand_a | operand_b;
            end

            `XRA: begin
                alu_out = operand_a ^ operand_b;
            end

            `CMA: begin
                alu_out = ~operand_a;
            end

            `ADD : begin
                alu_out = operand_a + operand_b;
                low_nibble_sum = {1'b0, operand_a[3:0]} + {1'b0, operand_b[3:0]};

                if (alu_out == 0) zero = 1;
                if (alu_out[7] == 1) sign=1;
                if (low_nibble_sum[4] == 1) aux_carry = 1;
                if ((~^alu_out) == 1) parity = 1;
            end
            
            `ADDC : begin
                alu_full_result_sum = {1'b0, operand_a} + {1'b0, operand_b} + cin;
                low_nibble_sum = {1'b0, operand_a[3:0]} + {1'b0, operand_b[3:0]};
                alu_out = alu_full_result_sum[7:0];

                if (alu_full_result_sum[8] == 1) cout = 1;
                if (alu_out == 0) zero = 1;
                if (alu_out[7] == 1) sign=1;
                if (low_nibble_sum[4] == 1) aux_carry = 1;
                if ((~^alu_out) == 1) parity = 1;
            end

            `SUB : begin
                alu_full_result_diff = {1'b0, operand_a} - {1'b0, operand_b};
                low_nibble_diff = {1'b0, operand_a[3:0]} - {1'b0, operand_b[3:0]};
                alu_out = alu_full_result_diff[7:0];

                if (alu_out == 0) zero = 1;
                if (alu_out[7] == 1) sign=1;
                if (low_nibble_sum[4] == 1) aux_carry = 1;
                if ((~^alu_out) == 1) parity = 1;
            end

            `SUBB : begin
                alu_full_result_diff = {1'b0, operand_a} - {1'b0, operand_b} - cin;
                low_nibble_diff = {1'b0, operand_a[3:0]} - {1'b0, operand_b[3:0]};
                alu_out = alu_full_result_diff[7:0];

                if (alu_out == 0) zero = 1;
                if (alu_out[7] == 1) sign=1;
                if (low_nibble_sum[4] == 1) aux_carry = 1;
                if ((~^alu_out) == 1) parity = 1;
                if (alu_full_result_diff[8] == 1) cout = 1;
            end
        endcase
    end
endmodule
                


module mp8085 # (parameter DATA_WIDTH=16) (
            output [DATA_WIDTH-9:0] UA,
            inout [DATA_WIDTH-9:0] AD,
            output S0, S1, M_, RD_, WR_, HLDA, INTA_, RESET_OUT, SOD, CLK, ALE,
            input READY, HOLD, INTR, RST_55, RST_65, RST_75, TRAP, RESET_IN_, X1, X2, SID
            );
    reg [DATA_WIDTH-9:0] A,TR, B, C, D, E, H, L, IR, F, W, Z;
    reg [DATA_WIDTH-1:0] SP, PC, INC_DEC;
    reg [DATA_WIDTH-9:0] data_bus;
    reg [DATA_WIDTH-13:0] bus_sel;
    wire A_load, B_load, C_load, D_load, E_load, F_load, H_load, L_load, W_load, Z_load, TR_load, IR_load;
    wire [DATA_WIDTH-9:0] alu_result_wire;
    wire cout_wire, sign_wire, parity_wire, aux_carry_wire, zero_wire;

    alu_8085 alu_inst (
    .operand_a(A), 
    .operand_b(TR), 
    .alu_op(IR), 
    .cin(F[0]), // Assuming carry is bit 0 of Flag register
    .alu_out(alu_result_wire), 
    .cout(cout_wire), 
    .sign(sign_wire), 
    .parity(parity_wire), 
    .aux_carry(aux_carry_wire), 
    .zero(zero_wire)
    );

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

    always @(posedge CLK or negedge RESET_IN_) begin
        if (!RESET_IN_) begin
            A <= 8'h00;
            B <= 8'h00;
            C <= 8'h00;
            D <= 8'h00;
            E <= 8'h00;
            F <= 8'h00;
            H <= 8'h00;
            L <= 8'h00;
            W <= 8'h00;
            Z <= 8'h00;
            TR <= 8'h00;
            IR <= 8'h00;
        end
        else begin
            if (A_load)  A  <= data_bus;
            if (B_load)  B  <= data_bus;
            if (C_load)  C  <= data_bus;
            if (D_load)  D  <= data_bus;
            if (E_load)  E  <= data_bus;
            if (F_load)  F  <= data_bus;
            if (H_load)  H  <= data_bus;
            if (L_load)  L  <= data_bus;
            if (W_load)  W  <= data_bus;
            if (Z_load)  Z  <= data_bus;
            if (TR_load) TR <= data_bus;
            if (IR_load) IR <= data_bus;
        end
    end
endmodule         




    // reg [2:0] reg_sel;

    // always @(*) begin
    //     case(reg_sel) 
    //         3'b000 : operand_b <= REG_B;
    //         3'b001 : operand_b <= REG_C;
    //         3'b010 : operand_b <= REG_D;
    //         3'b011 : operand_b <= REG_E;
    //         3'b100 : operand_b <= REG_H;
    //         3'b101 : operand_b <= REG_L;
    //         default : operand_b = REG_B;
    //     endcase
    // end

    // reg [DATA_WIDTH-9:0] operand_b;
    // reg [DATA_WIDTH-9:0] alu_TR;

    // localparam REG_B = 3'b000;
    // localparam REG_C = 3'b001;
    // localparam REG_D = 3'b010;
    // localparam REG_E = 3'b011;
    // localparam REG_H = 3'b100;
    // localparam REG_L = 3'b101;
    // localparam REG_M = 3'b110;  // memory byte at address {H, L} currently ignored
    // localparam REG_A = 3'b111;