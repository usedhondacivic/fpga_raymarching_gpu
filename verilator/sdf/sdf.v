module sdf (
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    output [26:0] distance
);
    // wire [26:0] cube_dist, sphere_dist, cross_dist, diff_dist;
    wire [26:0] q_x, q_y, q_z;
    VEC_mod_two MOD (
        .i_clk  (clk),
        .i_a_x  (point_x),
        .i_a_y  (point_y),
        .i_a_z  (point_z),
        .o_mod_x(q_x),
        .o_mod_y(q_y),
        .o_mod_z(q_z)
    );

    // box BOX (
    //     .clk(clk),
    //     .point_x(q_x),
    //     .point_y(q_y),
    //     .point_z(q_z),
    //     .dim_x(27'h1fc0000),
    //     .dim_y(27'h1fc0000),
    //     .dim_z(27'h1fc0000),
    //     .distance(cube_dist)
    // );
    sphere BALL (
        .clk(clk),
        .point_x(q_x),
        .point_y(q_y),
        .point_z(q_z),
        .radius(27'h1fd3333),
        .distance(distance)
    );
    // inf_cross CROSS (
    //     .clk(clk),
    //     .point_x(q_x),
    //     .point_y(q_y),
    //     .point_z(q_z),
    //     .size(27'h5ee6666),
    //     .distance(cross_dist)
    // );
    // sdf_difference #(
    //     .SDF_A_PIPELINE_CYCLES(9),
    //     .SDF_B_PIPELINE_CYCLES(11)
    // ) DIFF (
    //     .clk(clk),
    //     .i_dist_a(sphere_dist),
    //     .i_dist_b(cube_dist),
    //     .o_dist(diff_dist)
    // );
    // sdf_union #(
    //     .SDF_A_PIPELINE_CYCLES(11),
    //     .SDF_B_PIPELINE_CYCLES(1)
    // ) UNION (
    //     .clk(clk),
    //     .i_dist_a(diff_dist),
    //     .i_dist_b(cross_dist),
    //     .o_dist(distance)
    // );

    // tetrahedron TETRA (
    //     .clk(clk),
    //     .point_x(point_x),
    //     .point_y(point_y),
    //     .point_z(point_z),
    //     .distance(distance)
    // );


    // menger MENG (
    //     .clk(clk),
    //     .point_x(point_x),
    //     .point_y(point_y),
    //     .point_z(point_z),
    //     .distance(distance)
    // );


endmodule
