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
    wire [26:0] x_squared, y_squared, sum, inv_sqrt, recip_inv_sqrt;

    // mul = 1 cycle
    // add = 2 cycles
    // invSqrt = 5 cycles

    FpMul x_squared_mul (
        .iA(point_x),
        .iB(point_x),
        .oProd(x_squared)
    );
    FpMul y_squared_mul (
        .iA(point_y),
        .iB(point_y),
        .oProd(y_squared)
    );

    FpAdd sum_of_squares (
        .iCLK(clk),
        .iA  (x_squared),
        .iB  (y_squared),
        .oSum(sum)
    );

    FpInvSqrt inv_sq (
        .iCLK(clk),
        .iA(sum),
        .oInvSqrt(inv_sqrt)
    );

    // Reciprocal
    FpInvSqrt recip_inv_sq (
        .iCLK(clk),
        .iA(inv_sqrt),
        .oInvSqrt(recip_inv_sqrt)
    );
    FpMul recip (
        .iA(recip_inv_sqrt),
        .iB(recip_inv_sqrt),
        .oProd(distance)
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
    sdf TEST (
        .clk(clk),
        .point_x(pixel_x_fp),
        .point_y(pixel_y_fp),
        .point_z(27'd0),
        .distance(distance_fp)
    );
    wire [15:0] distance;
    Fp2Int dist_fp_2_int (
        .iA(distance_fp),
        .oInteger(distance)
    );

    // assign red   = distance[15:8];
    // assign green = distance[15:8];
    // assign blue  = distance[15:8];
    // assign red   = distance[7:0];
    // assign green = distance[7:0];
    // assign blue  = distance[7:0];
    assign red   = distance[9:2];
    assign green = distance[9:2];
    assign blue  = distance[9:2];
    // assign red   = pixel_x[9:2];
    // assign green = pixel_y[9:2];
    // assign blue  = 8'd0;

endmodule

/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
