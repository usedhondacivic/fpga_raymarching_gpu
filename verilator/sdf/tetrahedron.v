// float sdTetrahedron(vec3 point)
// {
//     return (max(
//         abs(point.x + point.y) - point.z,
//         abs(point.x - point.y) + point.z
//     ) - 1.0) / sqrt(3.);
// }

`define SQRT_THREE 27'h1feed9e

module tetrahedron (
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    output [26:0] distance
);
    wire [26:0] a_1_sum, a_2_sum, b_1_sum, b_2_sum;
    FpAdd x_plus_y (
        .iCLK(clk),
        .iA  (point_x),
        .iB  (point_y),
        .oSum(a_1_sum)
    );
    FpAdd x_minus_y (
        .iCLK(clk),
        .iA  (point_x),
        .iB  ({~point_y[26], point_y[25:0]}),
        .oSum(b_1_sum)
    );
    FpAdd minus_z (
        .iCLK(clk),
        .iA  (a_1_sum),
        .iB  ({~point_z[26], point_z[25:0]}),
        .oSum(a_2_sum)
    );
    FpAdd plus_z (
        .iCLK(clk),
        .iA  (b_1_sum),
        .iB  (point_z),
        .oSum(b_2_sum)
    );

    wire a_larger;
    wire [26:0] max;
    FpCompare a_b_comp (
        .iA(a_1_sum),
        .iB(b_1_sum),
        .oA_larger(a_larger)
    );
    assign max = a_larger ? a_1_sum : b_1_sum;

    wire [26:0] minus_one;
    FpAdd plus_z (
        .iCLK(clk),
        .iA  (max),
        .iB  (27'h5fc0000),  // -1.0
        .oSum(minus_one)
    );

endmodule
