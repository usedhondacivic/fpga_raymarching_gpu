/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSEDSIGNAL */

module FP_sqrt (
    input i_clk,
    input [26:0] i_a,
    output [26:0] o_sqrt
);
    // 5 + 5 = 10 cycles to complete
    wire [26:0] inv_sqrt, recip_inv_sqrt;
    FpInvSqrt inv_sq (
        .iCLK(i_clk),
        .iA(i_a),
        .oInvSqrt(inv_sqrt)
    );
    FpInvSqrt recip_inv_sq (
        .iCLK(i_clk),
        .iA(inv_sqrt),
        .oInvSqrt(recip_inv_sqrt)
    );
    FpMul recip (
        .iA(recip_inv_sqrt),
        .iB(recip_inv_sqrt),
        .oProd(o_sqrt)
    );
endmodule

module VEC_mag (
    input i_clk,
    input [26:0] i_x,
    input [26:0] i_y,
    input [26:0] i_z,
    output [26:0] o_mag
);
    // 2 + 10 = 12 cycles to complete

    wire [26:0] x_squared, y_squared, z_squared, xy_sum, sum;

    FpMul x_squared_mul (
        .iA(i_x),
        .iB(i_y),
        .oProd(x_squared)
    );
    FpMul y_squared_mul (
        .iA(i_y),
        .iB(i_y),
        .oProd(y_squared)
    );
    FpMul z_squared_mul (
        .iA(i_z),
        .iB(i_z),
        .oProd(z_squared)
    );
    FpAdd xy_sum_of_squares (
        .iCLK(i_clk),
        .iA  (x_squared),
        .iB  (y_squared),
        .oSum(xy_sum)
    );
    FpAdd xyz_sum_of_squares (
        .iCLK(i_clk),
        .iA  (xy_sum),
        .iB  (z_squared),
        .oSum(sum)
    );
    FP_sqrt sqrt (
        .i_clk(i_clk),
        .i_a(sum),
        .o_sqrt(o_mag)
    );
endmodule

module VEC_dot ();
endmodule

/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
