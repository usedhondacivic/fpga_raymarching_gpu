`timescale 1ns / 1ps

`define CORDW 10 // Coordinate width 2^10 = 1024

`define SCREEN_WIDTH 640
`define SCREEN_HEIGHT 480

`define NUM_ITR 10

`define EPSILON 27'h1ee6666 // 0.1
// `define EPSILON 27'h1e11eb8 //0.01
// `define EPSILON 27'h1f26666 // 0.2

`define MAX_DIST 27'h2180000

// glsl float z = u_resolution.y / tan(radians(FIELD_OF_VIEW) / 2.0);
// see get_fov_magic_num.c and fractal.frag
`define FOV_MAGIC_NUMBER 27'h1fc0000

/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSEDSIGNAL */

module distance_to_color (
    input [26:0] distance,
    input [9:0] num_itr,
    input hit,
    output [7:0] red,
    output [7:0] green,
    output [7:0] blue
);
    wire [26:0] distance_scaled;
    wire signed [15:0] distance_int;
    FpShift scale (
        .iA(distance),
        .iShift(5),
        .oShifted(distance_scaled)
    );
    Fp2Int dist_fp_2_int (
        .iA(distance_scaled),
        .oInteger(distance_int)
    );
    wire [7:0] col;
    // assign green = hit ? 8'd255 - distance_int[7:0] + 8'd125 : 8'd0;
    assign blue  = hit ? 8'd255 : 8'd0;
    // assign red   = 8'd255 - distance_int[7:0] + 8'd125;
    // assign col   = hit ? 8'd255 : 8'd0;
    assign col   = hit ? 8'd255 - distance_int[7:0] + 8'd125 : 8'd0;
    // assign col   = 8'd255 - distance_int[7:0] + 8'd125;
    assign red   = col;
    assign green = col;
    // assign blue  = col;
endmodule

/*
vec3 fragToWorldVector() {
    vec2 xy = gl_FragCoord.xy - u_resolution.xy / 2.0;
    float z = u_resolution.y / tan(radians(FIELD_OF_VIEW) / 2.0);
    vec3 viewDir = lookAt(
            -u_camera,
            vec3(0.0, 0.0, 0.0),
            vec3(0.0, 1.0, 0.0)
        ) * normalize(vec3(xy, -z));
    return normalize(viewDir.xyz);
*/
module frag_to_world_vector (
    input i_clk,
    input [`CORDW-1:0] i_x,  // integers, screen coords
    input [`CORDW-1:0] i_y,
    input [26:0] look_at_1_1,  // Look at matrix, calculated on the HPS
    input [26:0] look_at_1_2,  // https://lygia.xyz/space/lookAt
    input [26:0] look_at_1_3,
    input [26:0] look_at_2_1,
    input [26:0] look_at_2_2,
    input [26:0] look_at_2_3,
    input [26:0] look_at_3_1,
    input [26:0] look_at_3_2,
    input [26:0] look_at_3_3,
    output [26:0] o_x,  // floats, world space vector
    output [26:0] o_y,
    output [26:0] o_z
);
    wire signed [`CORDW:0] x_signed, y_signed, x_adj, y_adj;
    assign x_signed = {1'b0, i_x};
    assign y_signed = {1'b0, i_y};

    // vec2 xy = gl_FragCoord.xy - u_resolution.xy / 2.0;
    assign x_adj = x_signed - (`SCREEN_WIDTH >> 1);
    assign y_adj = y_signed - (`SCREEN_HEIGHT >> 1);
    wire [26:0] x_fp, y_fp, z_fp, res_x_fp, res_y_fp;
    Int2Fp px_fp (
        .iInteger({{5{x_adj[`CORDW]}}, x_adj[`CORDW:0]}),
        .oA(x_fp)
    );
    Int2Fp py_fp (
        .iInteger({{5{y_adj[`CORDW]}}, y_adj[`CORDW:0]}),
        .oA(y_fp)
    );
    Int2Fp calc_res_x_fp (
        .iInteger(`SCREEN_WIDTH),
        .oA(res_x_fp)
    );
    Int2Fp calc_res_y_fp (
        .iInteger(`SCREEN_HEIGHT),
        .oA(res_y_fp)
    );

    // float z = u_resolution.y / tan(radians(FIELD_OF_VIEW) / 2.0);
    FpMul z_calc (
        .iA(res_y_fp),
        .iB(`FOV_MAGIC_NUMBER),
        .oProd(z_fp)
    );


    // vec3 viewDir = lookAt(
    //     -u_camera, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0)
    // ) * normalize(
    //     vec3(xy, -z)
    // );
    wire [26:0] x_norm_fp, y_norm_fp, z_norm_fp;
    VEC_normalize hi (
        .i_clk(i_clk),
        .i_x(x_fp),
        .i_y(y_fp),
        .i_z(z_fp),
        .o_norm_x(x_norm_fp),
        .o_norm_y(y_norm_fp),
        .o_norm_z(z_norm_fp)
    );
    wire [26:0] z_neg_fp;
    FpNegate negate_z (
        .iA(z_norm_fp),
        .oNegative(z_neg_fp)
    );
    VEC_3x3_mult oh_god (
        .i_clk(i_clk),
        .i_m_1_1(look_at_1_1),
        .i_m_1_2(look_at_1_2),
        .i_m_1_3(look_at_1_3),
        .i_m_2_1(look_at_2_1),
        .i_m_2_2(look_at_2_2),
        .i_m_2_3(look_at_2_3),
        .i_m_3_1(look_at_3_1),
        .i_m_3_2(look_at_3_2),
        .i_m_3_3(look_at_3_3),
        .i_x(x_norm_fp),
        .i_y(y_norm_fp),
        .i_z(z_neg_fp),
        .o_x(o_x),
        .o_y(o_y),
        .o_z(o_z)
    );
endmodule

/*
* sdf
* INPUTS:
	* clk - module clock
	* point_x, _y, _z - x, y, z position of sample point (floating point)
* OUTPUTS:
	* distance - distance to scene (floating point)
*/
// Sphere sdf, radius 1
module sdf (
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    output [26:0] distance
);
    // Sphere sdf, radius 1
    // wire [26:0] norm;
    // VEC_norm circle (
    //     .i_clk(clk),
    //     .i_x  (point_x),
    //     .i_y  (point_y),
    //     .i_z  (point_z),
    //     .o_mag(norm)
    // );
    // FpAdd norm_sum (
    //     .iCLK(clk),
    //     .iA  (norm),
    //     .iB  (27'h5fc0000),  // -1.0
    //     .oSum(distance)
    // );
    //float sdBox( vec3 p, vec3 b )
    // {
    //   vec3 q = abs(p) - b;
    //   return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
    // }
    wire [26:0] q_x, q_y, q_z;
    VEC_add abs_p_minus_b (
        .i_clk(clk),
        .i_a_x({1'b0, point_x[25:0]}),
        .i_a_y({1'b0, point_y[25:0]}),
        .i_a_z({1'b0, point_z[25:0]}),
        .i_b_x(27'h5fc0000),  // -1.0
        .i_b_y(27'h5fc0000),  // -1.0
        .i_b_z(27'h5fc0000),  // -1.0
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
        .iB  (q_x_y_z_max[26] ? q_x_y_z_max : 0),
        .oSum(distance)
    );
endmodule

module ray_stage #(
    parameter SDF_STAGES = 11
) (
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    input [26:0] frag_dir_x,
    input [26:0] frag_dir_y,
    input [26:0] frag_dir_z,
    input [26:0] depth,
    // input hit,
    // input max_depth,
    output reg [26:0] o_point_x,
    output reg [26:0] o_point_y,
    output reg [26:0] o_point_z,
    output reg [26:0] o_frag_dir_x,
    output reg [26:0] o_frag_dir_y,
    output reg [26:0] o_frag_dir_z,
    output reg [26:0] o_depth,
    output reg o_hit
    // output reg o_max_depth
);
    reg [26:0]
        point_x_pipe[SDF_STAGES+1:0], point_y_pipe[SDF_STAGES+1:0], point_z_pipe[SDF_STAGES+1:0];
    reg [26:0]
        frag_dir_x_pipe[SDF_STAGES+1:0],
        frag_dir_y_pipe[SDF_STAGES+1:0],
        frag_dir_z_pipe[SDF_STAGES+1:0];
    reg  [26:0] depth_pipe[SDF_STAGES+1:0];
    wire [26:0] distance;
    wire [26:0] scaled_frag_x, scaled_frag_y, scaled_frag_z;
    wire [26:0] new_point_x, new_point_y, new_point_z;
    wire [26:0] new_depth;
    reg max_depth;
    reg max_depth_pipe[1:0];
    reg hit;

    sdf SDF (
        .clk(clk),
        .point_x(point_x),
        .point_y(point_y),
        .point_z(point_z),
        .distance(distance)
    );

    VEC_el_mul scale_mul (
        .i_clk(clk),
        .i_a_x(frag_dir_x_pipe[SDF_STAGES]),
        .i_a_y(frag_dir_y_pipe[SDF_STAGES]),
        .i_a_z(frag_dir_z_pipe[SDF_STAGES]),
        .i_b_x(distance),
        .i_b_y(distance),
        .i_b_z(distance),
        .o_el_mul_x(scaled_frag_x),
        .o_el_mul_y(scaled_frag_y),
        .o_el_mul_z(scaled_frag_z)
    );

    VEC_add new_p_add (
        .i_clk  (clk),
        .i_a_x  (scaled_frag_x),
        .i_a_y  (scaled_frag_y),
        .i_a_z  (scaled_frag_z),
        .i_b_x  (point_x_pipe[SDF_STAGES]),
        .i_b_y  (point_y_pipe[SDF_STAGES]),
        .i_b_z  (point_z_pipe[SDF_STAGES]),
        .o_add_x(new_point_x),
        .o_add_y(new_point_y),
        .o_add_z(new_point_z)
    );

    FpAdd new_depth_add (
        .iCLK(clk),
        .iA  (depth),
        .iB  (distance),
        .oSum(new_depth)
    );

    FpCompare ep_compare (
        .iA(`EPSILON),
        .iB(distance),
        .oA_larger(hit)
    );
    FpCompare max_dist_compare (
        .iA(new_depth),
        .iB(`MAX_DIST),
        .oA_larger(max_depth_pipe[0])
    );

    always @(posedge clk) begin
        o_hit <= hit;
        max_depth <= max_depth_pipe[1];
        max_depth_pipe[1] <= max_depth_pipe[0];
        o_point_x <= (hit | max_depth) ? point_x_pipe[SDF_STAGES+1] : new_point_x;
        o_point_y <= (hit | max_depth) ? point_y_pipe[SDF_STAGES+1] : new_point_y;
        o_point_z <= (hit | max_depth) ? point_z_pipe[SDF_STAGES+1] : new_point_z;
        o_frag_dir_x <= frag_dir_x_pipe[SDF_STAGES+1];
        o_frag_dir_y <= frag_dir_y_pipe[SDF_STAGES+1];
        o_frag_dir_z <= frag_dir_z_pipe[SDF_STAGES+1];
        o_depth <= (hit | max_depth) ? depth_pipe[SDF_STAGES+1] : new_depth;
    end

    genvar i;
    generate
        for (i = 0; i < SDF_STAGES + 1; i = i + 1) begin : g_ray_pipeline
            always @(posedge clk) begin
                /* verilator lint_off BLKSEQ*/
                point_x_pipe[0] = point_x;
                point_y_pipe[0] = point_y;
                point_z_pipe[0] = point_z;
                frag_dir_x_pipe[0] = frag_dir_x;
                frag_dir_y_pipe[0] = frag_dir_y;
                frag_dir_z_pipe[0] = frag_dir_z;
                depth_pipe[0] = depth;
                /* verilator lint_on BLKSEQ */
                point_x_pipe[i+1] <= point_x_pipe[i];
                point_y_pipe[i+1] <= point_y_pipe[i];
                point_z_pipe[i+1] <= point_z_pipe[i];
                frag_dir_x_pipe[i+1] <= frag_dir_x_pipe[i];
                frag_dir_y_pipe[i+1] <= frag_dir_y_pipe[i];
                frag_dir_z_pipe[i+1] <= frag_dir_z_pipe[i];
                depth_pipe[i+1] <= depth_pipe[i];
            end
        end
    endgenerate
endmodule
/*
rayInfo raymarch() {
    vec3 dir = fragToWorldVector();
    float depth = MIN_DIST;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(u_camera + depth * dir);
        if (dist < EPSILON) {
            return rayInfo(vec3(1.0, 1.0, 1.0) * (MAX_MARCHING_STEPS / (i * 5)));
        }
        depth += dist;
        if (depth >= MAX_DIST) {
            return rayInfo(vec3(0.0, 0.0, 0.0));
        u}
    }
    return rayInfo(vec3(0.0, 1.0, 0.0));
}
*/
module raymarcher #(
    parameter PIPELINE_OFFSET = 60
) (
    input                   clk,
    input  reg [`CORDW-1:0] pixel_x,      // horizontal SDL position
    input  reg [`CORDW-1:0] pixel_y,      // vertical SDL position
    input      [      26:0] look_at_1_1,  // Look at matrix, calculated on the HPS
    input      [      26:0] look_at_1_2,  // https://lygia.xyz/space/lookAt
    input      [      26:0] look_at_1_3,
    input      [      26:0] look_at_2_1,
    input      [      26:0] look_at_2_2,
    input      [      26:0] look_at_2_3,
    input      [      26:0] look_at_3_1,
    input      [      26:0] look_at_3_2,
    input      [      26:0] look_at_3_3,
    input      [      26:0] eye_x,
    input      [      26:0] eye_y,
    input      [      26:0] eye_z,
    output     [       7:0] red,
    output     [       7:0] green,
    output     [       7:0] blue
);
    wire [`CORDW-1:0] pixel_pipeline_adj_x;
    assign pixel_pipeline_adj_x =
		pixel_x > `SCREEN_WIDTH ? `SCREEN_WIDTH :
		pixel_x + PIPELINE_OFFSET > `SCREEN_WIDTH ? PIPELINE_OFFSET - pixel_x :
		pixel_x + PIPELINE_OFFSET;

    wire [`CORDW-1:0] pixel_pipeline_adj_y;
    assign pixel_pipeline_adj_y =
		pixel_y > `SCREEN_HEIGHT ? `SCREEN_HEIGHT :
		pixel_x + PIPELINE_OFFSET > `SCREEN_WIDTH ? pixel_y + 1 :
		pixel_y;

    wire [26:0] pixel_x_fp, pixel_y_fp;
    Int2Fp px_fp (
        .iInteger({6'd0, pixel_pipeline_adj_x}),
        .oA(pixel_x_fp)
    );
    Int2Fp py_fp (
        .iInteger({6'd0, pixel_y}),
        .oA(pixel_y_fp)
    );

    reg [26:0] frag_dir_x[`NUM_ITR:0], frag_dir_y[`NUM_ITR:0], frag_dir_z[`NUM_ITR:0];
    frag_to_world_vector F (
        .i_clk(clk),
        .i_x(pixel_pipeline_adj_x),
        .i_y(pixel_pipeline_adj_y),
        .look_at_1_1(look_at_1_1),
        .look_at_1_2(look_at_1_2),
        .look_at_1_3(look_at_1_3),
        .look_at_2_1(look_at_2_1),
        .look_at_2_2(look_at_2_2),
        .look_at_2_3(look_at_2_3),
        .look_at_3_1(look_at_3_1),
        .look_at_3_2(look_at_3_2),
        .look_at_3_3(look_at_3_3),
        .o_x(frag_dir_x[0]),
        .o_y(frag_dir_y[0]),
        .o_z(frag_dir_z[0])
    );

    reg [26:0] depth[`NUM_ITR:0];
    reg [26:0] point_x[`NUM_ITR:0], point_y[`NUM_ITR:0], point_z[`NUM_ITR:0];
    reg hit[`NUM_ITR:0];
    reg max_depth[`NUM_ITR:0];
    reg [9:0] itr_before_hit[`NUM_ITR:0];

    always @(posedge clk) begin
        hit[0] <= 0;
        itr_before_hit[0] <= 0;
        max_depth[0] <= 0;
        depth[0] <= 0;
        point_x[0] <= eye_x;
        point_y[0] <= eye_y;
        point_z[0] <= eye_z;
    end
    genvar n;
    generate
        for (n = 0; n < `NUM_ITR; n = n + 1) begin : g_ray_stages
            ray_stage its_not_a_stage_mom (
                .clk(clk),
                .point_x(point_x[n]),
                .point_y(point_y[n]),
                .point_z(point_z[n]),
                .frag_dir_x(frag_dir_x[n]),
                .frag_dir_y(frag_dir_y[n]),
                .frag_dir_z(frag_dir_z[n]),
                .depth(depth[n]),
                // .hit(hit[n]),
                // .max_depth(max_depth[n]),
                .o_point_x(point_x[n+1]),
                .o_point_y(point_y[n+1]),
                .o_point_z(point_z[n+1]),
                .o_frag_dir_x(frag_dir_x[n+1]),
                .o_frag_dir_y(frag_dir_y[n+1]),
                .o_frag_dir_z(frag_dir_z[n+1]),
                .o_depth(depth[n+1]),
                .o_hit(hit[n+1])
                // .o_max_depth(max_depth[n+1])
            );
        end
    endgenerate

    distance_to_color COLOR (
        .distance(depth[`NUM_ITR]),
        .num_itr(itr_before_hit[`NUM_ITR]),
        .hit(hit[`NUM_ITR]),
        .red(red),
        .green(green),
        .blue(blue)
    );
endmodule

/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
