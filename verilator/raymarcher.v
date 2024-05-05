`timescale 1ns / 1ps

`define CORDW 10 // Coordinate width 2^10 = 1024

`define SCREEN_WIDTH 640
`define SCREEN_HEIGHT 480

`define ITR_PER_LOOP 6
`define NUM_LOOPS 3

// `define EPSILON 27'h1ee6666 // 0.1
`define EPSILON 27'h1e11eb8 //0.01
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
    output [7:0] o_color
);
    wire [7:0] red, green, blue;
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
    assign blue = hit ? 8'd255 : 8'd0;
    // assign red   = 8'd255 - distance_int[7:0] + 8'd125;
    // assign col   = hit ? 8'd255 : 8'd0;
    assign col = hit ? 8'd255 - distance_int[7:0] + 8'd125 : 8'd0;
    // assign col   = 8'd255 - distance_int[7:0] + 8'd125;
    assign red = col;
    // assign green = hit ? 8'd255 - distance_int[8:1] + 8'd125 : 8'd0;
    // assign red   = hit ? 8'd255 : 8'd0;
    // assign green = hit ? 8'd255 : 8'd0;
    assign green = 0;
    // assign blue  = col;
    assign o_color = {red[7:5], green[7:5], blue[7:6]};
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
    parameter SDF_STAGES = 12
) (
    input clk,
    input [`CORDW-1:0] pixel_x,
    input [`CORDW-1:0] pixel_y,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    input [26:0] frag_dir_x,
    input [26:0] frag_dir_y,
    input [26:0] frag_dir_z,
    input [26:0] depth,
    output reg [26:0] o_point_x,
    output reg [26:0] o_point_y,
    output reg [26:0] o_point_z,
    output reg [26:0] o_frag_dir_x,
    output reg [26:0] o_frag_dir_y,
    output reg [26:0] o_frag_dir_z,
    output reg [26:0] o_depth,
    output reg [`CORDW-1:0] o_pixel_x,
    output reg [`CORDW-1:0] o_pixel_y,
    output reg o_hit,
    output reg o_max_depth
);
    reg [26:0]
        point_x_pipe[SDF_STAGES+2:0], point_y_pipe[SDF_STAGES+2:0], point_z_pipe[SDF_STAGES+2:0];
    reg [26:0]
        frag_dir_x_pipe[SDF_STAGES+2:0],
        frag_dir_y_pipe[SDF_STAGES+2:0],
        frag_dir_z_pipe[SDF_STAGES+2:0];
    reg [`CORDW-1:0] pixel_x_pipe[SDF_STAGES+2:0], pixel_y_pipe[SDF_STAGES+2:0];
    reg  [26:0] depth_pipe[SDF_STAGES+2:0];
    wire [26:0] distance;
    wire [26:0] scaled_frag_x, scaled_frag_y, scaled_frag_z;
    wire [26:0] new_point_x, new_point_y, new_point_z;
    wire [26:0] new_depth;
    reg hit_pipe[2:0];
    reg max_depth;

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
        .iA  (depth_pipe[SDF_STAGES]),
        .iB  (distance),
        .oSum(new_depth)
    );

    FpCompare ep_compare (
        .iA(`EPSILON),
        .iB(distance),
        .oA_larger(hit_pipe[0])
    );
    FpCompare max_dist_compare (
        .iA(new_depth),
        .iB(`MAX_DIST),
        .oA_larger(max_depth)
    );

    always @(posedge clk) begin
        o_max_depth <= max_depth;
        o_hit <= hit_pipe[2];
        hit_pipe[2] <= hit_pipe[1];
        hit_pipe[1] <= hit_pipe[0];
        o_point_x <= hit_pipe[2] ? point_x_pipe[SDF_STAGES+2] : new_point_x;
        o_point_y <= hit_pipe[2] ? point_y_pipe[SDF_STAGES+2] : new_point_y;
        o_point_z <= hit_pipe[2] ? point_z_pipe[SDF_STAGES+2] : new_point_z;
        o_frag_dir_x <= frag_dir_x_pipe[SDF_STAGES+2];
        o_frag_dir_y <= frag_dir_y_pipe[SDF_STAGES+2];
        o_frag_dir_z <= frag_dir_z_pipe[SDF_STAGES+2];
        o_pixel_x <= pixel_x_pipe[SDF_STAGES+2];
        o_pixel_y <= pixel_y_pipe[SDF_STAGES+2];
        o_depth <= hit_pipe[2] ? depth_pipe[SDF_STAGES+2] : new_depth;
    end

    genvar i;
    generate
        for (i = 0; i < SDF_STAGES + 2; i = i + 1) begin : g_ray_pipeline
            always @(posedge clk) begin
                /* verilator lint_off BLKSEQ*/
                point_x_pipe[0] = point_x;
                point_y_pipe[0] = point_y;
                point_z_pipe[0] = point_z;
                frag_dir_x_pipe[0] = frag_dir_x;
                frag_dir_y_pipe[0] = frag_dir_y;
                frag_dir_z_pipe[0] = frag_dir_z;
                pixel_x_pipe[0] = pixel_x;
                pixel_y_pipe[0] = pixel_y;
                depth_pipe[0] = depth;
                /* verilator lint_on BLKSEQ */
                point_x_pipe[i+1] <= point_x_pipe[i];
                point_y_pipe[i+1] <= point_y_pipe[i];
                point_z_pipe[i+1] <= point_z_pipe[i];
                frag_dir_x_pipe[i+1] <= frag_dir_x_pipe[i];
                frag_dir_y_pipe[i+1] <= frag_dir_y_pipe[i];
                frag_dir_z_pipe[i+1] <= frag_dir_z_pipe[i];
                pixel_x_pipe[i+1] <= pixel_x_pipe[i];
                pixel_y_pipe[i+1] <= pixel_y_pipe[i];
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
module raymarcher (
    input                   clk,
    input                   reset,
    input      [      26:0] look_at_1_1,   // Look at matrix, calculated on the HPS
    input      [      26:0] look_at_1_2,   // https://lygia.xyz/space/lookAt
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
    input      [`CORDW-1:0] read_pixel_x,
    input      [`CORDW-1:0] read_pixel_y,
    output reg [       7:0] o_color
);
    reg [`CORDW-1:0] x, y;
    reg [`CORDW-1:0] write_pixel_x;
    reg [`CORDW-1:0] write_pixel_y;

    reg [26:0]
        frag_dir_x[`ITR_PER_LOOP:0], frag_dir_y[`ITR_PER_LOOP:0], frag_dir_z[`ITR_PER_LOOP:0];

    frag_to_world_vector F (
        .i_clk(clk),
        .i_x(x),
        .i_y(y),
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

    reg [26:0] depth[`ITR_PER_LOOP:0];
    reg [26:0] point_x[`ITR_PER_LOOP:0], point_y[`ITR_PER_LOOP:0], point_z[`ITR_PER_LOOP:0];
    reg [`CORDW-1:0] pixel_x[`ITR_PER_LOOP:0], pixel_y[`ITR_PER_LOOP:0];
    reg hit[`ITR_PER_LOOP:0], max_depth[`ITR_PER_LOOP:0];
    reg [9:0] itr_before_hit[`ITR_PER_LOOP:0];

    wire send_new_pixel;
    reg [5:0] pipeline_fill_counter;
    reg pipeline_full;

    assign send_new_pixel = hit[`ITR_PER_LOOP] | max_depth[`ITR_PER_LOOP] | ~pipeline_full;
    // assign send_new_pixel = 1;

    always @(posedge clk) begin
        if (reset) begin
            x <= 0;
            y <= 0;
            pipeline_fill_counter <= 0;
            pipeline_full <= 0;
        end else if (send_new_pixel) begin
            // Set fresh raymarch initial values
            hit[0] <= 0;
            itr_before_hit[0] <= 0;
            depth[0] <= 0;
            point_x[0] <= eye_x;
            point_y[0] <= eye_y;
            point_z[0] <= eye_z;
            pixel_x[0] <= x;
            pixel_y[0] <= y;

            // Bump next pixel location
            x <= x == `SCREEN_WIDTH ? 0 : x + 1;
            y <= x == `SCREEN_WIDTH ? (y == `SCREEN_HEIGHT ? 0 : y + 1) : y;

            // Update outputs
            write_pixel_x <= pixel_x[`ITR_PER_LOOP];
            write_pixel_y <= pixel_y[`ITR_PER_LOOP];
            write_color <= color_output;
            // o_red <= red;
            // o_green <= green;
            // o_blue <= blue;
        end else begin
            // Pixel is not done being solved, keep trying
            hit[0] <= hit[`ITR_PER_LOOP];
            itr_before_hit[0] <= itr_before_hit[`ITR_PER_LOOP];
            depth[0] <= depth[`ITR_PER_LOOP];
            point_x[0] <= point_x[`ITR_PER_LOOP];
            point_y[0] <= point_y[`ITR_PER_LOOP];
            point_z[0] <= point_z[`ITR_PER_LOOP];
            pixel_x[0] <= pixel_x[`ITR_PER_LOOP];
            pixel_y[0] <= pixel_y[`ITR_PER_LOOP];
            frag_dir_x[0] <= frag_dir_x[`ITR_PER_LOOP];
            frag_dir_y[0] <= frag_dir_y[`ITR_PER_LOOP];
            frag_dir_z[0] <= frag_dir_z[`ITR_PER_LOOP];
        end

        if (pipeline_fill_counter < `ITR_PER_LOOP) begin
            pipeline_fill_counter <= pipeline_fill_counter + 1;
        end else begin
            pipeline_full <= 1;
        end
    end

    genvar n;
    generate
        for (n = 0; n < `ITR_PER_LOOP; n = n + 1) begin : g_ray_stages
            ray_stage its_not_a_stage_mom (
                .clk(clk),
                .pixel_x(pixel_x[n]),
                .pixel_y(pixel_y[n]),
                .point_x(point_x[n]),
                .point_y(point_y[n]),
                .point_z(point_z[n]),
                .frag_dir_x(frag_dir_x[n]),
                .frag_dir_y(frag_dir_y[n]),
                .frag_dir_z(frag_dir_z[n]),
                .depth(depth[n]),
                .o_point_x(point_x[n+1]),
                .o_point_y(point_y[n+1]),
                .o_point_z(point_z[n+1]),
                .o_frag_dir_x(frag_dir_x[n+1]),
                .o_frag_dir_y(frag_dir_y[n+1]),
                .o_frag_dir_z(frag_dir_z[n+1]),
                .o_pixel_x(pixel_x[n+1]),
                .o_pixel_y(pixel_y[n+1]),
                .o_depth(depth[n+1]),
                .o_hit(hit[n+1]),
                .o_max_depth(max_depth[n+1])
            );
        end
    endgenerate

    wire [7:0] color_output;
    reg  [7:0] write_color;
    distance_to_color COLOR (
        .distance(depth[`ITR_PER_LOOP]),
        .num_itr(itr_before_hit[`ITR_PER_LOOP]),
        .hit(hit[`ITR_PER_LOOP]),
        .o_color(color_output)
    );

    M10K do_electric_sheep_dream_of_24_bit_color (
        .q(o_color),
        .d(write_color),
        /* verilator lint_off WIDTHEXPAND */
        .write_address(write_pixel_x + write_pixel_y * 640),
        .read_address(read_pixel_x + read_pixel_y * 640),
        /* verilator lint_on WIDTHEXPAND */
        .we(1),
        .clk(clk)
    );

endmodule

module M10K (
    output reg [7:0] q,
    input [7:0] d,
    input [18:0] write_address,
    read_address,
    input we,
    clk
);
    // force M10K ram style
    reg [7:0] mem[307200-1:0]  /* synthesis ramstyle = "no_rw_check, M10K" */;

    always @(posedge clk) begin
        if (we) begin
            mem[write_address] <= d;
        end
        q <= mem[read_address];  // q doesn't get d in this clock cycle
    end
endmodule

/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
