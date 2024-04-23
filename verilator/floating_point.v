/* verilator lint_off DECLFILENAME */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off UNUSEDSIGNAL */


/**************************************************************************
 * Following modules written by Bruce Land
 * March 2017
 *************************************************************************/
/**************************************************************************
 * Floating Point to 16-bit integer                                             *
 * Combinational
 * Numbers with mag > than +/-32768 get clipped to 32768 or -32768
 *************************************************************************/

module Int2Fp (
    input signed [15:0] iInteger,
    output [26:0] oA
);
    // output fields
    wire        A_s;
    wire [ 7:0] A_e;
    wire [17:0] A_f;

    wire [15:0] abs_input;
    // get output sign bit
    assign A_s = (iInteger < 0);
    // remove sign from input
    assign abs_input = (iInteger < 0) ? -iInteger : iInteger;

    // find the most significant (nonzero) bit
    wire [7:0] shft_amt;
    assign shft_amt = abs_input[15] ? 8'd3 :
                      abs_input[14] ? 8'd4 : abs_input[13] ? 8'd5 :
                      abs_input[12] ? 8'd6 : abs_input[11] ? 8'd7 :
                      abs_input[10] ? 8'd8 : abs_input[9]  ? 8'd9 :
                      abs_input[8]  ? 8'd10 : abs_input[7]  ? 8'd11 :
                      abs_input[6]  ? 8'd12 : abs_input[5]  ? 8'd13 :
                      abs_input[4]  ? 8'd14 : abs_input[3]  ? 8'd15 :
                      abs_input[2]  ? 8'd16 : abs_input[1]  ? 8'd17 :
                      abs_input[0]  ? 8'd18 : 8'd19;
    // exponent 127 + (18-shift_amt)
    // 127 is 2^0
    // 18 is amount '1' is shifted
    assign A_e = 127 + 18 - shft_amt;
    // where the intermediate value is formed
    wire [33:0] shift_buffer;
    // remember that the high-order '1' is not stored,
    // but is shifted to bit 18
    assign shift_buffer = {16'b0, abs_input} << shft_amt;
    assign A_f = shift_buffer[17:0];
    assign oA = (iInteger == 0) ? 27'b0 : {A_s, A_e, A_f};

endmodule  //Int2Fp

/**************************************************************************
 * Floating Point to 16-bit integer
 * Combinational
 * Numbers with mag > than +/-32768 get clipped to 32768 or -32768
 *************************************************************************/
module Fp2Int (
    input [26:0] iA,
    output reg [15:0] oInteger
);
    // Extract fields of A and B.
    wire        A_s;
    wire [ 7:0] A_e;
    wire [17:0] A_f;
    assign A_s = iA[26];
    assign A_e = iA[25:18];
    assign A_f = iA[17:0];

    wire [15:0] max_int = 16'h7fff;  //32768
    wire [33:0] shift_buffer;
    // form (1.A_f) and shift it to postiion
    assign shift_buffer = {15'b0, 1'b1, A_f} << (A_e - 127);

    // If exponent less than 127, oInteger=0
    // If exponent greater than 127+14 oInteger=max value
    // Between these two values:
    // set up input mantissa with 1.mantissa
    // and the "1." in the lowest bit of an extended word.
    // shift-left by A_e-127
    // If the sign bit is set, negate oInteger

    always @(*) begin
        if (A_e < 127) oInteger = 16'b0;
        else if (A_e > 141) begin
            if (A_s) oInteger = -max_int;
            else oInteger = max_int;
        end else begin
            if (A_s) oInteger = -shift_buffer[33:18];
            else oInteger = shift_buffer[33:18];
        end
    end
endmodule  //Fp2Int

/**************************************************************************
 * Floating Point shift                                             *
 * Combinational
 * Negative shift input is right shift
 *************************************************************************/
module FpShift (
    input  [26:0] iA,
    input  [ 7:0] iShift,
    output [26:0] oShifted
);
    // Extract fields of A and B.
    wire        A_s;
    wire [ 7:0] A_e;
    wire [17:0] A_f;
    assign A_s = iA[26];
    assign A_e = iA[25:18];
    assign A_f = iA[17:0];
    // Flip bit 26
    // zero the output if underflow/overflow
    //    assign oShifted = (A_e+iShift<8'd254 && A_e+iShift>8'd2)?
    //									{A_s, A_e+iShift, A_f}
    assign oShifted = {A_s, A_e + iShift, A_f};
endmodule  //FpShift

/**************************************************************************
 * Floating Point sign negation                                             *
 * Combinational                                                          *
 *************************************************************************/
module FpNegate (
    input  [26:0] iA,
    output [26:0] oNegative
);
    // Extract fields of A and B.
    wire        A_s;
    wire [ 7:0] A_e;
    wire [17:0] A_f;
    assign A_s = iA[26];
    assign A_e = iA[25:18];
    assign A_f = iA[17:0];
    // Flip bit 26
    assign oNegative = {~A_s, A_e, A_f};
endmodule  //FpNegate

/**************************************************************************
 * Floating Point absolute                                             *
 * Combinational                                                          *
 *************************************************************************/
module FpAbs (
    input  [26:0] iA,
    output [26:0] oAbs
);
    // Extract fields of A and B.
    wire        A_s;
    wire [ 7:0] A_e;
    wire [17:0] A_f;
    assign A_s  = iA[26];
    assign A_e  = iA[25:18];
    assign A_f  = iA[17:0];
    // zero bit 26
    assign oAbs = {1'b0, A_e, A_f};
endmodule  //Fp absolute

/**************************************************************************
 * Floating Point compare                                             *
 * Combinational
 * output=1 if A>=B
 *************************************************************************/
module FpCompare (
    input [26:0] iA,
    input [26:0] iB,
    output reg oA_larger
);
    // Extract fields of A and B.
    wire        A_s;
    wire [ 7:0] A_e;
    wire [17:0] A_f;
    wire        B_s;
    wire [ 7:0] B_e;
    wire [17:0] B_f;

    assign A_s = iA[26];
    assign A_e = iA[25:18];
    assign A_f = iA[17:0];
    assign B_s = iB[26];
    assign B_e = iB[25:18];
    assign B_f = iB[17:0];

    // Determine which of A, B is larger
    wire A_mag_larger;
    assign A_mag_larger = (A_e > B_e) ? 1'b1 : ((A_e == B_e) && (A_f >= B_f)) ? 1'b1 : 1'b0;

    // now do the sign checks
    always @(*) begin
        if (A_s == 0 && B_s == 1) begin  // A positive, B negative
            oA_larger = 1'b1;
        end
        if (A_s == 1 && B_s == 0) begin  // A negative, B positive
            oA_larger = 1'b0;
        end
        if (A_s == 0 && B_s == 0) begin  // A positive, B positive
            oA_larger = A_mag_larger;
        end
        if (A_s == 1 && B_s == 1) begin  // A negative, B negative
            oA_larger = ~A_mag_larger;
        end
    end
endmodule  //FpCompare

/**************************************************************************
 * Mark Eiding mje56                                                      *
 * ECE 5760                                                               *
 * Modified IEEE single precision FP                                      *
 * bit 26:      Sign     (0: pos, 1: neg)                                 *
 * bits[25:18]: Exponent (unsigned)                                       *
 * bits[17:0]:  Fraction (unsigned)                                       *
 *  (-1)^SIGN * 2^(EXP-127) * (1+.FRAC)                                   *
 * (http://en.wikipedia.org/wiki/Single-precision_floating-point_format)  *
 * Adapted from Skyler Schneider ss868                                    *
 *************************************************************************/
/**************************************************************************
 * Floating Point Fast Inverse Square Root                                *
 * 5-stage pipeline                                                       *
 * http://en.wikipedia.org/wiki/Fast_inverse_square_root                  *
 * Magic number 27'd49920718                                              *
 * 1.5 = 27'd33423360                                                     *
 *************************************************************************/
module FpInvSqrt (
    input         iCLK,
    input  [26:0] iA,
    output [26:0] oInvSqrt
);

    // Extract fields of A and B.
    wire        A_s;
    wire [ 7:0] A_e;
    wire [17:0] A_f;
    assign A_s = iA[26];
    assign A_e = iA[25:18];
    assign A_f = iA[17:0];

    //Stage 1
    wire [26:0] y_1, y_1_out, half_iA_1;
    assign y_1 = 27'd49920718 - (iA >> 1);
    assign half_iA_1 = {A_s, A_e - 8'd1, A_f};
    FpMul s1_mult (
        .iA(y_1),
        .iB(y_1),
        .oProd(y_1_out)
    );
    //Stage 2
    reg [26:0] y_2, mult_2_in, half_iA_2;
    wire [26:0] y_2_out;
    FpMul s2_mult (
        .iA(half_iA_2),
        .iB(mult_2_in),
        .oProd(y_2_out)
    );
    //Stage 3
    reg [26:0] y_3, add_3_in;
    wire [26:0] y_3_out;
    FpAdd s3_add (
        .iCLK(iCLK),
        .iA  ({~add_3_in[26], add_3_in[25:0]}),
        .iB  (27'd33423360),
        .oSum(y_3_out)
    );
    //Stage 4
    reg [26:0] y_4;
    //Stage 5
    reg [26:0] y_5, mult_5_in;
    FpMul s5_mult (
        .iA(y_5),
        .iB(mult_5_in),
        .oProd(oInvSqrt)
    );

    always @(posedge iCLK) begin
        //Stage 1 to 2
        y_2 <= y_1;
        mult_2_in <= y_1_out;
        half_iA_2 <= half_iA_1;
        //Stage 2 to 3
        y_3 <= y_2;
        add_3_in <= y_2_out;
        //Stage 3 to 4
        y_4 <= y_3;
        //Stage 4 to 5
        y_5 <= y_4;
        mult_5_in <= y_3_out;
    end
endmodule

/**************************************************************************
 * Floating Point Multiplier                                              *
 * Combinational                                                          *
 *************************************************************************/
module FpMul (
    input  [26:0] iA,    // First input
    input  [26:0] iB,    // Second input
    output [26:0] oProd  // Product
);

    // Extract fields of A and B.
    wire        A_s;
    wire [ 7:0] A_e;
    wire [17:0] A_f;
    wire        B_s;
    wire [ 7:0] B_e;
    wire [17:0] B_f;
    assign A_s = iA[26];
    assign A_e = iA[25:18];
    assign A_f = {1'b1, iA[17:1]};
    assign B_s = iB[26];
    assign B_e = iB[25:18];
    assign B_f = {1'b1, iB[17:1]};

    // XOR sign bits to determine product sign.
    wire oProd_s;
    assign oProd_s = A_s ^ B_s;

    // Multiply the fractions of A and B
    wire [35:0] pre_prod_frac;
    assign pre_prod_frac = A_f * B_f;

    // Add exponents of A and B
    wire [8:0] pre_prod_exp;
    assign pre_prod_exp = A_e + B_e;

    // If top bit of product frac is 0, shift left one
    wire [ 7:0] oProd_e;
    wire [17:0] oProd_f;
    assign oProd_e = pre_prod_frac[35] ? (pre_prod_exp - 9'd126) : (pre_prod_exp - 9'd127);
    assign oProd_f = pre_prod_frac[35] ? pre_prod_frac[34:17] : pre_prod_frac[33:16];

    // Detect underflow
    wire underflow;
    assign underflow = pre_prod_exp < 9'h80;

    // Detect zero conditions (either product frac doesn't start with 1, or underflow)
    assign oProd = underflow        ? 27'b0 :
                   (B_e == 8'd0)    ? 27'b0 :
                   (A_e == 8'd0)    ? 27'b0 :
                   {oProd_s, oProd_e, oProd_f};

endmodule


/**************************************************************************
 * Floating Point Adder                                                   *
 * 2-stage pipeline                                                       *
 *************************************************************************/
module FpAdd (
    input             iCLK,
    input      [26:0] iA,
    input      [26:0] iB,
    output reg [26:0] oSum
);

    // Extract fields of A and B.
    wire        A_s;
    wire [ 7:0] A_e;
    wire [17:0] A_f;
    wire        B_s;
    wire [ 7:0] B_e;
    wire [17:0] B_f;
    assign A_s = iA[26];
    assign A_e = iA[25:18];
    assign A_f = {1'b1, iA[17:1]};
    assign B_s = iB[26];
    assign B_e = iB[25:18];
    assign B_f = {1'b1, iB[17:1]};
    wire A_larger;

    // Shift fractions of A and B so that they align.
    wire [7:0] exp_diff_A;
    wire [7:0] exp_diff_B;
    wire [7:0] larger_exp;
    wire [36:0] A_f_shifted;
    wire [36:0] B_f_shifted;

    assign exp_diff_A = B_e - A_e;  // if B bigger
    assign exp_diff_B = A_e - B_e;  // if A bigger

    assign larger_exp = (B_e > A_e) ? B_e : A_e;

    assign A_f_shifted = A_larger             ? {1'b0,  A_f, 18'b0} :
                         (exp_diff_A > 9'd35) ? 37'b0 :
                         ({1'b0, A_f, 18'b0} >> exp_diff_A);
    assign B_f_shifted = ~A_larger            ? {1'b0,  B_f, 18'b0} :
                         (exp_diff_B > 9'd35) ? 37'b0 :
                         ({1'b0, B_f, 18'b0} >> exp_diff_B);

    // Determine which of A, B is larger
    assign A_larger = (A_e > B_e) ? 1'b1 : ((A_e == B_e) && (A_f > B_f)) ? 1'b1 : 1'b0;

    // Calculate sum or difference of shifted fractions.
    wire [36:0] pre_sum;
    assign pre_sum = ((A_s^B_s) &  A_larger) ? A_f_shifted - B_f_shifted :
                     ((A_s^B_s) & ~A_larger) ? B_f_shifted - A_f_shifted :
                     A_f_shifted + B_f_shifted;

    // buffer midway results
    reg [36:0] buf_pre_sum;
    reg [ 7:0] buf_larger_exp;
    reg        buf_A_e_zero;
    reg        buf_B_e_zero;
    reg [26:0] buf_A;
    reg [26:0] buf_B;
    reg        buf_oSum_s;
    always @(posedge iCLK) begin
        buf_pre_sum    <= pre_sum;
        buf_larger_exp <= larger_exp;
        buf_A_e_zero   <= (A_e == 8'b0);
        buf_B_e_zero   <= (B_e == 8'b0);
        buf_A          <= iA;
        buf_B          <= iB;
        buf_oSum_s     <= A_larger ? A_s : B_s;
    end

    // Convert to positive fraction and a sign bit.
    wire [36:0] pre_frac;
    assign pre_frac = buf_pre_sum;

    // Determine output fraction and exponent change with position of first 1.
    wire [17:0] oSum_f;
    wire [ 7:0] shft_amt;
    assign shft_amt = pre_frac[36] ? 8'd0  : pre_frac[35] ? 8'd1  :
                      pre_frac[34] ? 8'd2  : pre_frac[33] ? 8'd3  :
                      pre_frac[32] ? 8'd4  : pre_frac[31] ? 8'd5  :
                      pre_frac[30] ? 8'd6  : pre_frac[29] ? 8'd7  :
                      pre_frac[28] ? 8'd8  : pre_frac[27] ? 8'd9  :
                      pre_frac[26] ? 8'd10 : pre_frac[25] ? 8'd11 :
                      pre_frac[24] ? 8'd12 : pre_frac[23] ? 8'd13 :
                      pre_frac[22] ? 8'd14 : pre_frac[21] ? 8'd15 :
                      pre_frac[20] ? 8'd16 : pre_frac[19] ? 8'd17 :
                      pre_frac[18] ? 8'd18 : pre_frac[17] ? 8'd19 :
                      pre_frac[16] ? 8'd20 : pre_frac[15] ? 8'd21 :
                      pre_frac[14] ? 8'd22 : pre_frac[13] ? 8'd23 :
                      pre_frac[12] ? 8'd24 : pre_frac[11] ? 8'd25 :
                      pre_frac[10] ? 8'd26 : pre_frac[9]  ? 8'd27 :
                      pre_frac[8]  ? 8'd28 : pre_frac[7]  ? 8'd29 :
                      pre_frac[6]  ? 8'd30 : pre_frac[5]  ? 8'd31 :
                      pre_frac[4]  ? 8'd32 : pre_frac[3]  ? 8'd33 :
                      pre_frac[2]  ? 8'd34 : pre_frac[1]  ? 8'd35 :
                      pre_frac[0]  ? 8'd36 : 8'd37;

    wire [53:0] pre_frac_shft, uflow_shift;
    // the shift +1 is because high order bit is not stored, but implied
    assign pre_frac_shft = {pre_frac, 17'b0} << (shft_amt + 1);  //? shft_amt+1
    assign uflow_shift = {pre_frac, 17'b0} << (shft_amt);  //? shft_amt for overflow
    assign oSum_f = pre_frac_shft[53:36];

    wire [7:0] oSum_e;
    assign oSum_e = buf_larger_exp - shft_amt + 8'd1;

    // Detect underflow
    wire underflow;
    // this incorrectly sets uflow for 10-10.1
    //assign underflow = ~oSum_e[7] && buf_larger_exp[7] && (shft_amt != 8'b0);

    // if top bit of matissa is not set, then denorm
    assign underflow = ~uflow_shift[53];

    always @(posedge iCLK) begin
        oSum <= (buf_A_e_zero && buf_B_e_zero)    ? 27'b0 :
                  buf_A_e_zero                     ? buf_B :
                  buf_B_e_zero                     ? buf_A :
                  underflow                        ? 27'b0 :
                  (pre_frac == 0)                  ? 27'b0 :
                  {buf_oSum_s, oSum_e, oSum_f};
    end  //output update
endmodule

/* verilator lint_on DECLFILENAME */
/* verilator lint_on WIDTHEXPAND */
/* verilator lint_on WIDTHTRUNC */
/* verilator lint_on UNUSEDSIGNAL */

