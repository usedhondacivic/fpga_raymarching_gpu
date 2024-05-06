module tetrahedron (
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    output [26:0] distance
);
    // Sphere sdf, radius 1
    wire [26:0] norm;
    VEC_norm circle (
        .i_clk(clk),
        .i_x  (point_x),
        .i_y  (point_y),
        .i_z  (point_z),
        .o_mag(norm)
    );
    FpAdd norm_sum (
        .iCLK(clk),
        .iA  (norm),
        .iB  (27'h5fc0000),  // -1.0
        .oSum(distance)
    );
endmodule
