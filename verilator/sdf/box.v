/* verilator lint_off UNUSEDSIGNAL */
// SDF_STAGES = 11
module box #(
    parameter PIPELINE_STAGES = 8
) (
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    input [26:0] dim_x,
    input [26:0] dim_y,
    input [26:0] dim_z,
    output [26:0] distance
);
    wire [26:0] q_x, q_y, q_z;
    VEC_add abs_p_minus_b (
        .i_clk  (clk),
        .i_a_x  ({1'b0, point_x[25:0]}),
        .i_a_y  ({1'b0, point_y[25:0]}),
        .i_a_z  ({1'b0, point_z[25:0]}),
        .i_b_x  ({~dim_x[26], dim_x[25:0]}),
        .i_b_y  ({~dim_y[26], dim_y[25:0]}),
        .i_b_z  ({~dim_z[26], dim_z[25:0]}),
        .o_add_x(q_x),
        .o_add_y(q_y),
        .o_add_z(q_z)
    );
    wire y_larger, x_larger;
    FpCompare q_y_z_comp (
        .iA(q_y),
        .iB(q_z),
        .oA_larger(y_larger)
    );
    wire [26:0] q_y_z_max, q_x_y_z_max;
    assign q_y_z_max = y_larger ? q_y : q_z;
    reg [26:0] q_x_y_z_max_pipe[PIPELINE_STAGES:0];
    FpCompare q_x_y_z_comp (
        .iA(q_x),
        .iB(q_y_z_max),
        .oA_larger(x_larger)
    );
    assign q_x_y_z_max = x_larger ? q_x : q_y_z_max;
    wire [26:0] q_norm;
    VEC_norm q_norm_mod (
        .i_clk(clk),
        .i_x  (q_x[26] ? 0 : q_x),
        .i_y  (q_y[26] ? 0 : q_y),
        .i_z  (q_z[26] ? 0 : q_z),
        .o_mag(q_norm)
    );
    FpAdd output_add (
        .iCLK(clk),
        .iA  (q_norm),
        .iB  (q_x_y_z_max_pipe[PIPELINE_STAGES][26] ? q_x_y_z_max_pipe[PIPELINE_STAGES] : 0),
        .oSum(distance)
    );
    genvar i;
    generate
        for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin : g_ray_pipeline
            always @(posedge clk) begin
                /* verilator lint_off BLKSEQ*/
                q_x_y_z_max_pipe[0] = q_x_y_z_max;
                /* verilator lint_on BLKSEQ */
                q_x_y_z_max_pipe[i+1] <= q_x_y_z_max_pipe[i];
            end
        end
    endgenerate
endmodule
/* verilator lint_on UNUSEDSIGNAL */
