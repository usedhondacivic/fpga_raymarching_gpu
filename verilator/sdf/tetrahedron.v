// SDF_STAGES = 5
//
`define INV_SQRT_THREE 27'h1f89e69

// float sdTetrahedron(vec3 point)
// {
//     return (max(
//         abs(point.x + point.y) - point.z,
//         abs(point.x - point.y) + point.z
//     ) - 1.0) / sqrt(3.);
// }

/* verilator lint_off UNUSEDSIGNAL */
module tetrahedron #(
    parameter PIPELINE_STAGES = 1
) (
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    output [26:0] distance
);
    reg [26:0] point_z_pipe[PIPELINE_STAGES:0];

    wire [26:0] a_1_sum, a_1_abs, a_2_sum, b_1_sum, b_1_abs, b_2_sum;
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
    assign a_1_abs = {1'd0, a_1_sum[25:0]};
    assign b_1_abs = {1'd0, b_1_sum[25:0]};
    FpAdd minus_z (
        .iCLK(clk),
        .iA  (a_1_abs),
        .iB  ({~point_z_pipe[PIPELINE_STAGES][26], point_z_pipe[PIPELINE_STAGES][25:0]}),
        .oSum(a_2_sum)
    );
    FpAdd plus_z (
        .iCLK(clk),
        .iA  (b_1_abs),
        .iB  (point_z_pipe[PIPELINE_STAGES]),
        .oSum(b_2_sum)
    );

    wire a_larger;
    wire [26:0] max;
    FpCompare a_b_comp (
        .iA(a_2_sum),
        .iB(b_2_sum),
        .oA_larger(a_larger)
    );
    assign max = a_larger ? a_2_sum : b_2_sum;

    wire [26:0] minus_one;
    FpAdd sub_one (
        .iCLK(clk),
        .iA  (max),
        .iB  (27'h5fc0000),  // -1.0
        .oSum(minus_one)
    );

    FpMul coeff (
        .iA(minus_one),
        .iB(`INV_SQRT_THREE),
        .oProd(distance)
    );

    genvar i;
    generate
        for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin : g_ray_pipeline
            always @(posedge clk) begin
                /* verilator lint_off BLKSEQ*/
                point_z_pipe[0]   <= point_z;
                /* verilator lint_on BLKSEQ */
                point_z_pipe[i+1] <= point_z_pipe[i];
            end
        end
    endgenerate
endmodule
/* verilator lint_on UNUSEDSIGNAL */
