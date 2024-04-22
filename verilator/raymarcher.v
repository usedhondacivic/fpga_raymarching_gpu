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
    wire [26:0] x_squared, s_2_x_squared, s_3_x_squared, s_4_x_squared, y_squared, sum;
    wire [26:0] x_squared[10:0];
    wire [26:0] y_squared[10:0];
    wire [26:0] sum[10:0];
    wire [26:0] inv_sqrt[10:0];

    // mul = 1 cycle
    // add = 2 cycles
    // invSqrt = 5 cycles
    FpMul x_squared_mul (
        .iA(point_x),
        .iB(point_x),
        .oProd(x_squared[1])
    );
    FpMul y_squared_mul (
        .iA(point_y),
        .iB(point_y),
        .oProd(y_squared[1])
    );
    FpAdd sum_of_squares (
        .iCLK(clk),
        .iA  (x_squared[1]),
        .iB  (y_squared[1]),
        .oSum(sum[3])
    );
    FpInvSqrt inv_sq (
        .iCLK(clk),
        .iA(sum[3]),
        .oInvSqrt(inv_sqrt[8])
    );
    // Reciprocal
    FpInvSqrt inv_sq (
        .iCLK(clk),
        .iA(sum),
        .oInvSqrt(distance)
    );
    FpInvSqrt inv_sq (
        .iCLK(clk),
        .iA(sum),
        .oInvSqrt(distance)
    );
endmodule


module distance_to_color (
    input  [26:0] distance,
    output [ 7:0] red,
    output [ 7:0] green,
    output [ 7:0] blue
);
endmodule

module raymarcher (
    input clk,
    input reg [`CORDW-1:0] pixel_x,  // horizontal SDL position
    input reg [`CORDW-1:0] pixel_y,  // vertical SDL position
    output [7:0] red,
    output [7:0] green,
    output [7:0] blue
);

    wire [26:0] distance;
    sdf TEST (
        .clk(clk),
        .point_x({17'd0, pixel_x}),
        .point_y({17'd0, pixel_y}),
        .point_z(27'd0),
        .distance(distance)
    );

    assign red   = distance[7:0];
    assign green = distance[7:0];
    assign blue  = distance[7:0];

endmodule

/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
/* verilator lint_on DECLFILENAME */
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
/* verilator lint_on DECLFILENAME */
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
/* verilator lint_on DECLFILENAME */
/* verilator lint_on DECLFILENAME */
/* verilator lint_on DECLFILENAME */
