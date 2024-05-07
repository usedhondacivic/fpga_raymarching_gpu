module sdf (
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    output [26:0] distance
);
    // wire [26:0] cube_dist, sphere_dist;
    //
    // box BOX (
    //     .clk(clk),
    //     .point_x(point_x),
    //     .point_y(point_y),
    //     .point_z(point_z),
    //     .dim_x(27'h1fc0000),
    //     .dim_y(27'h1fc0000),
    //     .dim_z(27'h1fc0000),
    //     .distance(cube_dist)
    // );
    //
    // // assign distance = cube_dist;
    //
    // sphere BALL (
    //     .clk(clk),
    //     .point_x(point_x),
    //     .point_y(point_y),
    //     .point_z(point_z),
    //     .radius(27'h1fd3333),
    //     .distance(sphere_dist)
    // );
    //
    // sdf_difference #(
    //     .SDF_A_PIPELINE_CYCLES(9),
    //     .SDF_B_PIPELINE_CYCLES(11)
    // ) UNION (
    //     .clk(clk),
    //     .i_dist_a(sphere_dist),
    //     .i_dist_b(cube_dist),
    //     .o_dist(distance)
    // );

    // tetrahedron TETRA (
    //     .clk(clk),
    //     .point_x(point_x),
    //     .point_y(point_y),
    //     .point_z(point_z),
    //     .distance(distance)
    // );

    inf_cross CROSS (
        .clk(clk),
        .point_x(point_x),
        .point_y(point_y),
        .point_z(point_z),
        .distance(distance)
    );

endmodule
