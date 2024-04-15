`timescale 1ns / 1ps

`define CORDW 10

module top (  // coordinate width
    input                   clk_pix,  // pixel clock
    input                   sim_rst,  // sim reset
    output reg [`CORDW-1:0] sdl_sx,   // horizontal SDL position
    output reg [`CORDW-1:0] sdl_sy,   // vertical SDL position
    output reg              sdl_de,   // data enable (low in blanking interval)
    output reg [       7:0] sdl_r,    // 8-bit red
    output reg [       7:0] sdl_g,    // 8-bit green
    output reg [       7:0] sdl_b     // 8-bit blue
);

    // display sync signals and coordinates
    reg [`CORDW-1:0] sx, sy;
    logic de;
    simple_480p display_inst (
        .clk_pix,
        .rst_pix(sim_rst),
        .sx,
        .sy,
        /* verilator lint_off PINCONNECTEMPTY */
        .hsync  (),
        .vsync  (),
        /* verilator lint_on PINCONNECTEMPTY */
        .de
    );

    // define a square with screen coordinates
    wire square;
    assign square = (sx > 220 && sx < 420) && (sy > 140 && sy < 340);

    // paint colour: white inside square, blue outside
    wire [3:0] paint_r, paint_g, paint_b;
    assign paint_r = (square) ? 4'hF : 4'h1;
    assign paint_g = (square) ? 4'hF : 4'h3;
    assign paint_b = (square) ? 4'hF : 4'h7;

    // display colour: paint colour but black in blanking interval
    wire [3:0] display_r, display_g, display_b;
    assign display_r = (de) ? paint_r : 4'h0;
    assign display_g = (de) ? paint_g : 4'h0;
    assign display_b = (de) ? paint_b : 4'h0;

    // SDL output (8 bits per colour channel)
    always @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_r  <= {2{display_r}};  // double signal width from 4 to 8 bits
        sdl_g  <= {2{display_g}};
        sdl_b  <= {2{display_b}};
    end
endmodule
