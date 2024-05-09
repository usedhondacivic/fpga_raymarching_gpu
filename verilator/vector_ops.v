/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSEDSIGNAL */

function static [7:0] get_exp_diff([26:0] num, [7:0] exp);
    /* verilator lint_off WIDTHEXPAND */
    /* verilator lint_off WIDTHTRUNC */
    return (num[25:18] - 127) - exp;
    /* verilator lint_on WIDTHEXPAND */
    /* verilator lint_on WIDTHTRUNC */
endfunction

// https://stackoverflow.com/questions/49139283/are-there-any-numbers-that-enable-fast-modulo-calculation-on-floats
module FP_mod_two (
    input i_clk,
    input [26:0] i_num,
    output [26:0] o_num_mod_two
);
    wire [26:0] rounded_div;
    wire [ 7:0] shift_amount = (8'd18 - get_exp_diff(i_num, 8'd2));
    // Clear the low bits corresponding to < 2, ie round to the nearest 2
    assign rounded_div = shift_amount <= 0 ? i_num :
						 shift_amount >= 18 ? 0 :
						 i_num >> shift_amount << shift_amount;
    // Subtract out the rounded result, the rest is remainder
    FpAdd mod_sub (
        .iCLK(i_clk),
        .iA  (i_num),
        .iB  ({~rounded_div[26], rounded_div[25:0]}),
        .oSum(o_num_mod_two)
    );
endmodule

module FP_sqrt #(
    parameter PIPELINE_STAGES = 4
) (
    input i_clk,
    input [26:0] i_a,
    output [26:0] o_sqrt
);
    wire [26:0] inv_sqrt;
    reg  [26:0] i_a_pipe [PIPELINE_STAGES:0];
    FpInvSqrt inv_sq (
        .iCLK(i_clk),
        .iA(i_a),
        .oInvSqrt(inv_sqrt)
    );
    FpMul recip (
        .iA(inv_sqrt),
        .iB(i_a_pipe[PIPELINE_STAGES]),
        .oProd(o_sqrt)
    );
    genvar i;
    generate
        for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin : g_ray_pipeline
            always @(posedge i_clk) begin
                /* verilator lint_off BLKSEQ*/
                i_a_pipe[0] = i_a;
                /* verilator lint_on BLKSEQ */
                i_a_pipe[i+1] <= i_a_pipe[i];
            end
        end
    endgenerate
endmodule

module VEC_add (
    input i_clk,
    input [26:0] i_a_x,
    input [26:0] i_a_y,
    input [26:0] i_a_z,
    input [26:0] i_b_x,
    input [26:0] i_b_y,
    input [26:0] i_b_z,
    output [26:0] o_add_x,
    output [26:0] o_add_y,
    output [26:0] o_add_z
);
    FpAdd x_add (
        .iCLK(i_clk),
        .iA  (i_a_x),
        .iB  (i_b_x),
        .oSum(o_add_x)
    );
    FpAdd y_add (
        .iCLK(i_clk),
        .iA  (i_a_y),
        .iB  (i_b_y),
        .oSum(o_add_y)
    );
    FpAdd z_add (
        .iCLK(i_clk),
        .iA  (i_a_z),
        .iB  (i_b_z),
        .oSum(o_add_z)
    );
endmodule

module VEC_mod_two (
    input i_clk,
    input [26:0] i_a_x,
    input [26:0] i_a_y,
    input [26:0] i_a_z,
    output [26:0] o_mod_x,
    output [26:0] o_mod_y,
    output [26:0] o_mod_z
);
    FP_mod_two x_mod (
        .i_clk(i_clk),
        .i_num(i_a_x),
        .o_num_mod_two(o_mod_x)
    );
    FP_mod_two y_mod (
        .i_clk(i_clk),
        .i_num(i_a_y),
        .o_num_mod_two(o_mod_y)
    );
    FP_mod_two z_mod (
        .i_clk(i_clk),
        .i_num(i_a_z),
        .o_num_mod_two(o_mod_z)
    );
endmodule

module VEC_el_mul (
    input i_clk,
    input [26:0] i_a_x,
    input [26:0] i_a_y,
    input [26:0] i_a_z,
    input [26:0] i_b_x,
    input [26:0] i_b_y,
    input [26:0] i_b_z,
    output [26:0] o_el_mul_x,
    output [26:0] o_el_mul_y,
    output [26:0] o_el_mul_z
);
    FpMul x_mul (
        .iA(i_a_x),
        .iB(i_b_x),
        .oProd(o_el_mul_x)
    );
    FpMul y_mul (
        .iA(i_a_y),
        .iB(i_b_y),
        .oProd(o_el_mul_y)
    );
    FpMul z_mul (
        .iA(i_a_z),
        .iB(i_b_z),
        .oProd(o_el_mul_z)
    );
endmodule


module VEC_dot (
    input i_clk,
    input [26:0] i_a_x,
    input [26:0] i_a_y,
    input [26:0] i_a_z,
    input [26:0] i_b_x,
    input [26:0] i_b_y,
    input [26:0] i_b_z,
    output [26:0] o_dot
);
    wire [26:0] x_prod, y_prod, xy_sum;
    reg [26:0] z_prod_pipe[2:0];
    FpMul x_prod_mul (
        .iA(i_a_x),
        .iB(i_b_x),
        .oProd(x_prod)
    );
    FpMul y_prod_mul (
        .iA(i_a_y),
        .iB(i_b_y),
        .oProd(y_prod)
    );
    FpMul z_prod_mul (
        .iA(i_a_z),
        .iB(i_b_z),
        .oProd(z_prod_pipe[0])
    );
    FpAdd xy_sum_add (
        .iCLK(i_clk),
        .iA  (x_prod),
        .iB  (y_prod),
        .oSum(xy_sum)
    );
    FpAdd xyz_sum (
        .iCLK(i_clk),
        .iA  (xy_sum),
        .iB  (z_prod_pipe[2]),
        .oSum(o_dot)
    );
    always @(posedge i_clk) begin
        z_prod_pipe[2] <= z_prod_pipe[1];
        z_prod_pipe[1] <= z_prod_pipe[0];
    end

endmodule

module VEC_norm (
    input i_clk,
    input [26:0] i_x,
    input [26:0] i_y,
    input [26:0] i_z,
    output [26:0] o_mag
);
    wire [26:0] x_squared, y_squared, z_squared, dot;
    VEC_dot sqr_dot (
        .i_clk(i_clk),
        .i_a_x(i_x),
        .i_a_y(i_y),
        .i_a_z(i_z),
        .i_b_x(i_x),
        .i_b_y(i_y),
        .i_b_z(i_z),
        .o_dot(dot)
    );
    FP_sqrt sqrt (
        .i_clk(i_clk),
        .i_a(dot),
        .o_sqrt(o_mag)
    );
endmodule


module VEC_normalize #(
    parameter PIPELINE_STAGES = 3
) (
    input i_clk,
    input [26:0] i_x,
    input [26:0] i_y,
    input [26:0] i_z,
    output [26:0] o_norm_x,
    output [26:0] o_norm_y,
    output [26:0] o_norm_z
);
    wire [26:0] dot, inv_sqrt;

    reg [26:0]
        point_x_pipe[PIPELINE_STAGES:0],
        point_y_pipe[PIPELINE_STAGES:0],
        point_z_pipe[PIPELINE_STAGES:0];

    VEC_dot sqr_dot (
        .i_clk(i_clk),
        .i_a_x(i_x),
        .i_a_y(i_y),
        .i_a_z(i_z),
        .i_b_x(i_x),
        .i_b_y(i_y),
        .i_b_z(i_z),
        .o_dot(dot)
    );
    FpInvSqrt inv_sq (
        .iCLK(i_clk),
        .iA(dot),
        .oInvSqrt(inv_sqrt)
    );
    FpMul x_scale_mul (
        .iA(point_x_pipe[PIPELINE_STAGES]),
        .iB(inv_sqrt),
        .oProd(o_norm_x)
    );
    FpMul y_scale_mul (
        .iA(point_y_pipe[PIPELINE_STAGES]),
        .iB(inv_sqrt),
        .oProd(o_norm_y)
    );
    FpMul z_scale_mul (
        .iA(point_z_pipe[PIPELINE_STAGES]),
        .iB(inv_sqrt),
        .oProd(o_norm_z)
    );
    always @(posedge i_clk) begin
        /* verilator lint_off BLKSEQ*/
        point_x_pipe[0] <= i_x;
        point_y_pipe[0] <= i_y;
        point_z_pipe[0] <= i_z;
    end
    genvar i;
    generate
        for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin : g_ray_pipeline
            always @(posedge i_clk) begin
                point_x_pipe[i+1] <= point_x_pipe[i];
                point_y_pipe[i+1] <= point_y_pipe[i];
                point_z_pipe[i+1] <= point_z_pipe[i];
            end
        end
    endgenerate
endmodule

module VEC_3x3_mult (
    input i_clk,
    input [26:0] i_m_1_1,
    input [26:0] i_m_1_2,
    input [26:0] i_m_1_3,
    input [26:0] i_m_2_1,
    input [26:0] i_m_2_2,
    input [26:0] i_m_2_3,
    input [26:0] i_m_3_1,
    input [26:0] i_m_3_2,
    input [26:0] i_m_3_3,
    input [26:0] i_x,
    input [26:0] i_y,
    input [26:0] i_z,
    output [26:0] o_x,
    output [26:0] o_y,
    output [26:0] o_z
);
    VEC_dot x (
        .i_clk(i_clk),
        .i_a_x(i_m_1_1),
        .i_a_y(i_m_1_2),
        .i_a_z(i_m_1_3),
        .i_b_x(i_x),
        .i_b_y(i_y),
        .i_b_z(i_z),
        .o_dot(o_x)
    );
    VEC_dot y (
        .i_clk(i_clk),
        .i_a_x(i_m_2_1),
        .i_a_y(i_m_2_2),
        .i_a_z(i_m_2_3),
        .i_b_x(i_x),
        .i_b_y(i_y),
        .i_b_z(i_z),
        .o_dot(o_y)
    );
    VEC_dot z (
        .i_clk(i_clk),
        .i_a_x(i_m_3_1),
        .i_a_y(i_m_3_2),
        .i_a_z(i_m_3_3),
        .i_b_x(i_x),
        .i_b_y(i_y),
        .i_b_z(i_z),
        .o_dot(o_z)
    );
endmodule

/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
