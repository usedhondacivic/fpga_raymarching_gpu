`define SDF_PIPELINE_DIFF abs(SDF_A_PIPELINE_CYCLES - SDF_B_PIPELINE_CYCLES)

function static integer abs(integer num);
    return num > 0 ? num : -num;
endfunction

/* verilator lint_off DECLFILENAME */
module sdf_union #(
    parameter SDF_A_PIPELINE_CYCLES = 0,
    parameter SDF_B_PIPELINE_CYCLES = 0
) (
    input clk,
    input [26:0] i_dist_a,
    input [26:0] i_dist_b,
    output [26:0] o_dist
);
    reg [26:0] i_dist_pipe[`SDF_PIPELINE_DIFF:0];

    wire [26:0] faster_sdf, slower_sdf;

    assign faster_sdf = SDF_A_PIPELINE_CYCLES < SDF_B_PIPELINE_CYCLES ? i_dist_a : i_dist_b;
    assign slower_sdf = SDF_A_PIPELINE_CYCLES > SDF_B_PIPELINE_CYCLES ? i_dist_a : i_dist_b;

    wire a_max;
    FpCompare max_comp (
        .iA(slower_sdf),
        .iB(i_dist_pipe[`SDF_PIPELINE_DIFF]),
        .oA_larger(a_max)
    );

    assign o_dist = ~a_max ? slower_sdf : i_dist_pipe[`SDF_PIPELINE_DIFF];

    genvar i;
    generate
        for (i = 0; i < `SDF_PIPELINE_DIFF; i = i + 1) begin : g_union_pipeline
            always @(posedge clk) begin
                /* verilator lint_off BLKSEQ*/
                i_dist_pipe[0] = faster_sdf;
                /* verilator lint_on BLKSEQ */
                i_dist_pipe[i+1] <= i_dist_pipe[i];
            end
        end
    endgenerate
endmodule

module sdf_difference #(
    parameter SDF_A_PIPELINE_CYCLES = 0,
    parameter SDF_B_PIPELINE_CYCLES = 0
) (
    input clk,
    input [26:0] i_dist_a,
    input [26:0] i_dist_b,
    output [26:0] o_dist
);
    reg [26:0] i_dist_pipe[`SDF_PIPELINE_DIFF:0];

    wire [26:0] faster_sdf, neg_a, op_b;

    assign faster_sdf = SDF_A_PIPELINE_CYCLES < SDF_B_PIPELINE_CYCLES ? i_dist_a : i_dist_b;
    assign neg_a = SDF_A_PIPELINE_CYCLES < SDF_B_PIPELINE_CYCLES ?
		{~i_dist_pipe[`SDF_PIPELINE_DIFF][26], i_dist_pipe[`SDF_PIPELINE_DIFF][25:0]} :
		{~i_dist_a[26], i_dist_a[25:0]};
    assign op_b = SDF_A_PIPELINE_CYCLES < SDF_B_PIPELINE_CYCLES ?
		i_dist_b :
		i_dist_pipe[`SDF_PIPELINE_DIFF];

    wire a_max;
    FpCompare max_comp (
        .iA(neg_a),
        .iB(op_b),
        .oA_larger(a_max)
    );

    assign o_dist = a_max ? neg_a : op_b;

    genvar i;
    generate
        for (i = 0; i < `SDF_PIPELINE_DIFF; i = i + 1) begin : g_union_pipeline
            always @(posedge clk) begin
                /* verilator lint_off BLKSEQ*/
                i_dist_pipe[0] = faster_sdf;
                /* verilator lint_on BLKSEQ */
                i_dist_pipe[i+1] <= i_dist_pipe[i];
            end
        end
    endgenerate
endmodule

module sdf_intersection #(
    parameter SDF_A_PIPELINE_CYCLES,
    parameter SDF_B_PIPELINE_CYCLES
) (
    input clk,
    input [26:0] i_dist_a,
    input [26:0] i_dist_b,
    output [26:0] o_dist
);
    /* TODO */
endmodule


// vec3 fold(vec3 point, vec3 pointOnPlane, vec3 planeNormal)
// {
//     // Center plane on origin for distance calculation
//     float distToPlane = dot(point - pointOnPlane, planeNormal);
//
//     // We only want to reflect if the dist is negative
//     distToPlane = min(distToPlane, 0.0);
//     return point - 2.0 * distToPlane * planeNormal;
// }
// Fold can be used to make self similar fractals, but I think it will be too
// expensive for use on the FPGA

// module sdf_fold #(
//     parameter PIPELINE_STAGES = 4
// ) (
//     input [26:0] point_x,
//     input [26:0] point_y,
//     input [26:0] point_z,
//     input [26:0] point_on_plane_x,
//     input [26:0] point_on_plane_y,
//     input [26:0] point_on_plane_z,
//     input [26:0] plane_normal_x,
//     input [26:0] plane_normal_y,
//     input [26:0] plane_normal_z,
//     output reg o_x,
//     output reg o_y,
//     output reg o_z
// );
//     reg [26:0]
//         plane_normal_x_pipe[PIPELINE_STAGES:0],
//         plane_normal_y_pipe[PIPELINE_STAGES:0],
//         plane_normal_z_pipe[PIPELINE_STAGES:0];
//
//     wire [26:0] pmpop_x, pmpop_y, pmpop_z;
//     VEC_add pmpop_sub (
//         .i_a_x  (point_x),
//         .i_a_y  (point_y),
//         .i_a_z  (point_z),
//         .i_b_x  (point_on_plane_x),
//         .i_b_y  (point_on_plane_y),
//         .i_b_z  (point_on_plane_z),
//         .o_add_x(pmpop_x),
//         .o_add_y(pmpop_y),
//         .o_add_z(pmpop_z)
//     );
//
//     wire [26:0] dist_to_plane, neg_dist_to_plane;
//     VEC_dot dist_to_plane_dot (
//         .i_a_x(pmpop_x),
//         .i_a_y(pmpop_y),
//         .i_a_z(pmpop_z),
//         .i_b_x(plane_normal_x_pipe[2]),
//         .i_b_y(plane_normal_y_pipe[2]),
//         .i_b_z(plane_normal_z_pipe[2]),
//         .o_dot(dist_to_plane),
//     );
//
//     assign neg_dist_to_plane = dist_to_plane[26] ? dist_to_plane : 27'd0;
//
//     /* TODO: Complete */
//
//     genvar i;
//     generate
//         for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin : g_sdf_fold_pipeline
//             always @(posedge i_clk) begin
//                 /* verilator lint_off BLKSEQ*/
//                 plane_normal_x_pipe[0]   <= plane_normal_x;
//                 plane_normal_y_pipe[0]   <= plane_normal_y;
//                 plane_normal_z_pipe[0]   <= plane_normal_z;
//                 /* verilator lint_on BLKSEQ */
//                 plane_normal_x_pipe[i+1] <= plane_normal_x_pipe[i];
//                 plane_normal_y_pipe[i+1] <= plane_normal_y_pipe[i];
//                 plane_normal_z_pipe[i+1] <= plane_normal_z_pipe[i];
//             end
//         end
//     endgenerate
// endmodule

// float opRepetition( in vec3 p, in vec3 s, in sdf3d primitive )
// {
//     vec3 q = p - s*round(p/s);
//     return primitive( q );
// }
module sdf_repetition ();
	
endmodule

/* verilator lint_on DECLFILENAME */
