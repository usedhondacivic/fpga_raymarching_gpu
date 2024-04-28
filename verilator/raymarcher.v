`timescale 1ns / 1ps

`define CORDW 10 // Coordinate width 2^10 = 1024

`define SCREEN_WIDTH 640
`define SCREEN_HEIGHT 480

`define NUM_ITR 5

`define EPSILON 27'h1ee6666 // 0.1

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
    // wire [15:0] distance_int;
    // Fp2Int dist_fp_2_int (
    //     .iA(distance),
    //     .oInteger(distance_int)
    // );
    wire [7:0] col;
    assign col   = hit ? 8'd255 - (num_itr[7:0] * 20) : 8'd0;
    assign red   = col;
    assign blue  = col;
    assign green = col;
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
module sdf (
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    output [26:0] distance
);
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
module raymarcher (
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

    wire [26:0] pixel_x_fp, pixel_y_fp;
    Int2Fp px_fp (
        .iInteger({6'd0, pixel_x}),
        .oA(pixel_x_fp)
    );
    Int2Fp py_fp (
        .iInteger({6'd0, pixel_y}),
        .oA(pixel_y_fp)
    );

    wire [26:0] frag_dir_x, frag_dir_y, frag_dir_z;
    frag_to_world_vector F (
        .i_clk(clk),
        .i_x(pixel_x),
        .i_y(pixel_y),
        .look_at_1_1(look_at_1_1),
        .look_at_1_2(look_at_1_2),
        .look_at_1_3(look_at_1_3),
        .look_at_2_1(look_at_2_1),
        .look_at_2_2(look_at_2_2),
        .look_at_2_3(look_at_2_3),
        .look_at_3_1(look_at_3_1),
        .look_at_3_2(look_at_3_2),
        .look_at_3_3(look_at_3_3),
        .o_x(frag_dir_x),
        .o_y(frag_dir_y),
        .o_z(frag_dir_z)
    );

    reg [26:0] depth[`NUM_ITR:0];
    reg [26:0] point_x[`NUM_ITR:0];
    reg [26:0] point_y[`NUM_ITR:0];
    reg [26:0] point_z[`NUM_ITR:0];
    reg hit[`NUM_ITR:0];
    reg [9:0] itr_before_hit[`NUM_ITR:0];

    always @(posedge clk) begin
        hit[0] <= 0;
        itr_before_hit[0] <= 0;
        depth[0] <= 0;
        point_x[0] <= eye_x;
        point_y[0] <= eye_y;
        point_z[0] <= eye_z;
    end
    genvar i;
    generate
        for (i = 0; i < `NUM_ITR - 1; i = i + 1) begin : g_ray_stages
            wire [26:0] distance,
				scaled_frag_y,
				scaled_frag_x,
				scaled_frag_z,
				new_point_x,
				new_point_y,
				new_point_z,
				new_depth;
            wire new_hit;
            sdf SDF (
                .clk(clk),
                .point_x(point_x[i]),
                .point_y(point_y[i]),
                .point_z(point_z[i]),
                .distance(distance)
            );
            FpMul x_scale_mul (
                .iA(frag_dir_x),
                .iB(distance),
                .oProd(scaled_frag_x)
            );
            FpAdd new_x_p_add (
                .iCLK(clk),
                .iA  (scaled_frag_x),
                .iB  (point_x[i]),
                .oSum(new_point_x)
            );
            FpMul y_scale_mul (
                .iA(frag_dir_y),
                .iB(distance),
                .oProd(scaled_frag_y)
            );
            FpAdd new_y_p_add (
                .iCLK(clk),
                .iA  (scaled_frag_y),
                .iB  (point_y[i]),
                .oSum(new_point_y)
            );
            FpMul z_scale_mul (
                .iA(frag_dir_z),
                .iB(distance),
                .oProd(scaled_frag_z)
            );
            FpAdd new_z_p_add (
                .iCLK(clk),
                .iA  (scaled_frag_z),
                .iB  (point_z[i]),
                .oSum(new_point_z)
            );
            FpAdd new_depth_add (
                .iCLK(clk),
                .iA  (depth[i]),
                .iB  (distance),
                .oSum(new_depth)
            );
            FpCompare ep_compare (
                .iA(`EPSILON),
                .iB(distance),
                .oA_larger(new_hit)
            );
            always @(posedge clk) begin
                if (~new_hit && ~hit[i]) begin
                    itr_before_hit[i+1] <= itr_before_hit[i] + 1;
                end else begin
                    itr_before_hit[i+1] <= itr_before_hit[i];
                end
                hit[i+1] <= hit[i] ? hit[i] : new_hit;
                depth[i+1] <= new_depth;
                point_x[i+1] <= new_point_x;
                point_y[i+1] <= new_point_y;
                point_z[i+1] <= new_point_z;
            end
        end
    endgenerate

    distance_to_color COLOR (
        .distance(depth[`NUM_ITR-1]),
        .num_itr(itr_before_hit[`NUM_ITR-1]),
        .hit(hit[`NUM_ITR-1]),
        .red(red),
        .green(green),
        .blue(blue)
    );
endmodule

/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
