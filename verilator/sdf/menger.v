// SDF_STAGES = 2

// vec3 map( in vec3 p )
// {
//    float d = sdBox(p,vec3(1.0));
//
//    float s = 1.0;
//    for( int m=0; m<3; m++ )
//    {
//       vec3 a = mod( p*s, 2.0 )-1.0;
//       s *= 3.0;
//       vec3 r = abs(1.0 - 3.0*abs(a));
//
//       float da = max(r.x,r.y);
//       float db = max(r.y,r.z);
//       float dc = max(r.z,r.x);
//       float c = (min(da,min(db,dc))-1.0)/s;
//
//       d = max(d,c);
//    }
//
//    return vec3(d,1.0,1.0);
// }

`define THREE 27'h2020000
`define NEG_ONE 27'h5fc0000

/* verilator lint_off UNUSEDSIGNAL */
module menger #(
    parameter LEVELS = 1,
    parameter PIPELINE_STAGES = 4
) (
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    output reg [26:0] distance
);
    wire [26:0] box_d;

    box BOX (
        .clk(clk),
        .point_x(point_x),
        .point_y(point_y),
        .point_z(point_z),
        .dim_x(27'h1fc0000),
        .dim_y(27'h1fc0000),
        .dim_z(27'h1fc0000),
        .distance(box_d)
    );

    genvar n;
    generate
        for (n = 0; n < LEVELS; n = n + 1) begin : g_menger_stages
            always @(posedge clk) begin
            end
        end
    endgenerate
    genvar i;
    generate
        for (i = 0; i < FRAG_DIR_PIPELINE_CYCLES; i = i + 1) begin : g_menger_pipeline
            always @(posedge clk) begin
            end
        end
    endgenerate

endmodule

function static [26:0] get_exp_diff([26:0] num, integer exp);
    return num[25:18] - exp;
endfunction
//       vec3 a = mod( p*s, 2.0 )-1.0;
//       s *= 3.0;
//       vec3 r = abs(1.0 - 3.0*abs(a));
//
//       float da = max(r.x,r.y);
//       float db = max(r.y,r.z);
//       float dc = max(r.z,r.x);
//       float c = (min(da,min(db,dc))-1.0)/s;
//
//       d = max(d,c);

module menger_stage (
    input clk,
    input [26:0] d,
    input [26:0] s,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    output [26:0] d,
    output [26:0] s
);
    // s*= 3.0;
    wire [26:0] three_s;
    FpMul s_calc (
        .iA(s),
        .iB(`THREE),
        .oProd(three_s)
    );

    // vec3 a = mod ( p*s, 2.0)-1.0;
    wire [26:0] p_times_s;
    wire [26:0] p_mul_s_x, p_mul_s_y, p_mul_s_z;
    VEC_el_mul p_t_calc (
        .i_clk(clk),
        .i_a_x(point_x),
        .i_a_y(point_y),
        .i_a_z(point_z),
        .i_b_x(s),
        .i_b_y(s),
        .i_b_z(s),
        .o_el_mul_x(p_mul_s_x),
        .o_el_mul_y(p_mul_s_y),
        .o_el_mul_z(p_mul_s_z)
    );

    wire [26:0] p_s_mod_x, p_s_mod_y, p_s_mod_z;
    VEC_mod_two p_s_mod_calc (
        .i_clk  (clk),
        .i_a_x  (p_mul_s_x),
        .i_a_y  (p_mul_s_y),
        .i_a_z  (p_mul_s_z),
        .o_mod_x(p_s_mod_x),
        .o_mod_y(p_s_mod_y),
        .o_mod_z(p_s_mod_z)
    );

    wire [26:0] a_x, a_y, a_z;
    VEC_add a_sub_one (
        .i_clk  (clk),
        .i_a_x  (p_s_mod_x),
        .i_a_y  (p_s_mod_y),
        .i_a_z  (p_s_mod_z),
        .i_b_x  (`NEG_ONE),
        .i_b_y  (`NEG_ONE),
        .i_b_z  (`NEG_ONE),
        .o_add_x(a_x),
        .o_add_y(a_y),
        .o_add_z(a_z)
    );

    // vec3 r = abs(1.0 - 3.0*abs(a));


endmodule
/* verilator lint_on UNUSEDSIGNAL */
