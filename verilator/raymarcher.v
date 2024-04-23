`timescale 1ns / 1ps

`define CORDW 10 // Coordinate width 2^10 = 1024

/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSEDSIGNAL */

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
    VEC_norm circle (
        .i_clk(clk),
        .i_x  (point_x),
        .i_y  (point_y),
        .i_z  (point_z),
        .o_mag(distance)
    );

endmodule

module distance_to_color (
    input  [26:0] distance,
    output [ 7:0] red,
    output [ 7:0] green,
    output [ 7:0] blue
);
    wire [15:0] distance_int;
    Fp2Int dist_fp_2_int (
        .iA(distance),
        .oInteger(distance_int)
    );
    wire in_radius;
    assign in_radius = distance_int < 100;

    wire [7:0] col;
    // assign col   = (in_radius == 1'b1) ? 8'b11111111 : distance_int[9:2];
    assign col   = {8{in_radius}};
    assign red   = col;
    assign blue  = col;
    assign green = col;
endmodule

module raymarcher (
    input clk,
    input reg [`CORDW-1:0] pixel_x,  // horizontal SDL position
    input reg [`CORDW-1:0] pixel_y,  // vertical SDL position
    output [7:0] red,
    output [7:0] green,
    output [7:0] blue
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
    wire [26:0] distance_fp;
    sdf SDF (
        .clk(clk),
        .point_x(pixel_x_fp),
        .point_y(pixel_y_fp),
        .point_z(27'd0),
        .distance(distance_fp)
    );
    distance_to_color COLOR (
        .distance(distance_fp),
        .red(red),
        .green(green),
        .blue(blue)
    );

endmodule

/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
