`define ONE 27'h1fc0000
`define NEG_ONE 27'h5fc0000
`define TWO 27'h2000000
`define NEG_TWO 27'h6000000

module sdf(
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    input [3:0] repetition_pow,
    output [26:0] distance
);

    /* verilator lint_off UNUSEDSIGNAL */
    // wire [26:0] cube_dist, sphere_dist, cross_dist, diff_dist;
    // wire [26:0] cube_dist, cross_dist;
    wire [26:0] cube_dist, cross_dist, tetra_dist;
    wire [26:0] q_x, q_y, q_z;
    VEC_mod_pow_two MOD (
        .i_clk  (clk),
        .i_a_x  (point_x),
        .i_a_y  (point_y),
        .i_a_z  (point_z),
        .i_pow  (repetition_pow),
        .o_mod_x(q_x),
        .o_mod_y(q_y),
        .o_mod_z(q_z)
    );
    wire [26:0] a_x, a_y, a_z;
    VEC_add ADD_A (
        .i_clk  (clk),
        .i_a_x  (q_x),
        .i_a_y  (q_y),
        .i_a_z  (q_z),
        .i_b_x  (~q_x[26] ? `NEG_TWO : `TWO),
        .i_b_y  (~q_y[26] ? `NEG_TWO : `TWO),
        .i_b_z  (~q_z[26] ? `NEG_TWO : `TWO),
        .o_add_x(a_x),
        .o_add_y(a_y),
        .o_add_z(a_z)
    );
    // wire [26:0] b_x, b_y, b_z;
    // VEC_add ADD_B (
    //     .i_clk  (clk),
    //     .i_a_x  (q_x),
    //     .i_a_y  (q_y),
    //     .i_a_z  (q_z),
    //     .i_b_x  (~q_x[26] ? `ONE : `NEG_ONE),
    //     .i_b_y  (~q_y[26] ? `ONE : `NEG_ONE),
    //     .i_b_z  (~q_z[26] ? `ONE : `NEG_ONE),
    //     .o_add_x(b_x),
    //     .o_add_y(b_y),
    //     .o_add_z(b_z)
    // );
    // VEC_add ADD (
    //     .i_clk  (clk),
    //     .i_a_x  (q_x),
    //     .i_a_y  (q_y),
    //     .i_a_z  (q_z),
    //     .i_b_x  (~q_x[26] ? 27'h5fc0000 : 27'h1fc0000),
    //     .i_b_y  (~q_y[26] ? 27'h5fc0000 : 27'h1fc0000),
    //     .i_b_z  (~q_z[26] ? 27'h5fc0000 : 27'h1fc0000),
    //     .o_add_x(a_x),
    //     .o_add_y(a_y),
    //     .o_add_z(a_z)
    // );

    box BOX (
        .clk(clk),
        .point_x(a_x),
        .point_y(a_y),
        .point_z(a_z),
        .dim_x(27'h1f26666),
        .dim_y(27'h1f26666),
        .dim_z(27'h1f26666),
        .distance(cube_dist)
    );
    // sphere BALL (
    //     .clk(clk),
    //     .point_x(point_x),
    //     .point_y(point_y),
    //     .point_z(point_z),
    //     .radius(`ONE),
    //     .distance(distance)
    // );
    inf_cross CROSS (
        .clk(clk),
        .point_x(q_x),
        .point_y(q_y),
        .point_z(q_z),
        .size(27'h5f80000),
        .distance(cross_dist)
    );
    // sdf_difference #(
    //     .SDF_A_PIPELINE_CYCLES(9),
    //     .SDF_B_PIPELINE_CYCLES(11)
    // ) DIFF (
    //     .clk(clk),
    //     .i_dist_a(sphere_dist),
    //     .i_dist_b(cube_dist),
    //     .o_dist(diff_dist)
    // );
    sdf_union #(
        .SDF_A_PIPELINE_CYCLES(1),
        .SDF_B_PIPELINE_CYCLES(7)
    ) UNION (
        .clk(clk),
        .i_dist_a(cross_dist),
        .i_dist_b(tetra_dist),
        .o_dist(distance)
    );

    tetrahedron TETRA (
        .clk(clk),
        .point_x(a_x),
        .point_y(a_y),
        .point_z(a_z),
        .distance(tetra_dist)
    );


    // menger MENG (
    //     .clk(clk),
    //     .point_x(point_x),
    //     .point_y(point_y),
    //     .point_z(point_z),
    //     .distance(distance)
    // );
    /* verilator lint_on UNUSEDSIGNAL */
endmodule
