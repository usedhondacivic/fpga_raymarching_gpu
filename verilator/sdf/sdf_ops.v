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
endmodule

/* verilator lint_on DECLFILENAME */
