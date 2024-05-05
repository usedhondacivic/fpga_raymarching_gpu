`timescale 1ns / 1ps

`define CORDW 10 // Coordinate width 2^10 = 1024

/* verilator lint_off DECLFILENAME */
module M10K (
    output reg [23:0] q,
    input [23:0] d,
    input [18:0] write_address,
    read_address,
    input we,
    clk
);
    // force M10K ram style
    reg [23:0] mem[307200-1:0]  /* synthesis ramstyle = "no_rw_check, M10K" */;

    always @(posedge clk) begin
        if (we) begin
            mem[write_address] <= d;
        end
        q <= mem[read_address];  // q doesn't get d in this clock cycle
    end
endmodule
/* verilator lint_on DECLFILENAME */

/* verilator lint_off UNUSEDSIGNAL */
module top (
    /* VGA Simulation */
    input                   clk_50,       // 50 MHz clock
    input                   clk_pix,      // pixel clock
    input                   sim_rst,      // sim reset
    input      [      26:0] eye_x,
    input      [      26:0] eye_y,
    input      [      26:0] eye_z,
    input      [      26:0] look_at_1_1,  // Look at matrix, calculated on the HPS
    input      [      26:0] look_at_1_2,  // https://lygia.xyz/space/lookAt
    input      [      26:0] look_at_1_3,
    input      [      26:0] look_at_2_1,
    input      [      26:0] look_at_2_2,
    input      [      26:0] look_at_2_3,
    input      [      26:0] look_at_3_1,
    input      [      26:0] look_at_3_2,
    input      [      26:0] look_at_3_3,
    output reg [`CORDW-1:0] sdl_sx,       // horizontal SDL position
    output reg [`CORDW-1:0] sdl_sy,       // vertical SDL position
    output reg              sdl_de,       // data enable (low in blanking interval)
    output reg [       7:0] sdl_r,        // 8-bit red
    output reg [       7:0] sdl_g,        // 8-bit green
    output reg [       7:0] sdl_b         // 8-bit blue
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

    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;
    wire [`CORDW-1:0] x, y;
    raymarcher RM (
        .clk(clk_pix),
        .reset(sim_rst),
        .look_at_1_1(look_at_1_1),
        .look_at_1_2(look_at_1_2),
        .look_at_1_3(look_at_1_3),
        .look_at_2_1(look_at_2_1),
        .look_at_2_2(look_at_2_2),
        .look_at_2_3(look_at_2_3),
        .look_at_3_1(look_at_3_1),
        .look_at_3_2(look_at_3_2),
        .look_at_3_3(look_at_3_3),
        .eye_x(eye_x),
        .eye_y(eye_y),
        .eye_z(eye_z),
        .o_pixel_x(x),
        .o_pixel_y(y),
        .o_red(red),
        .o_green(green),
        .o_blue(blue)
    );
    wire [23:0] output_color;

    M10K fake_vga_sdram (
        .q(output_color),
        .d({red, green, blue}),
        /* verilator lint_off WIDTHEXPAND */
        .write_address(x + y * 640),
        .read_address(sx + sy * 640),
        /* verilator lint_on WIDTHEXPAND */
        .we(1),
        .clk(clk_50)
    );

    always @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_r  <= output_color[23:16];
        sdl_g  <= output_color[15:8];
        sdl_b  <= output_color[7:0];
    end

    initial begin
        if ($test$plusargs("trace") != 0) begin
            $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
            $dumpfile("logs/vlt_dump.vcd");
            $dumpvars();
        end
        $display("[%0t] Model running...\n", $time);
    end

endmodule


// // define a square with screen coordinates
// wire square;
// assign square = (sx > 220 && sx < 420) && (sy > 140 && sy < 340);
//
// // paint colour: white inside square, blue outside
// wire [3:0] paint_r, paint_g, paint_b;
// assign paint_r = (square) ? 4'hF : 4'h1;
// assign paint_g = (square) ? 4'hF : 4'h3;
// assign paint_b = (square) ? 4'hF : 4'h7;
//
// // display colour: paint colour but black in blanking interval
// wire [3:0] display_r, display_g, display_b;
// assign display_r = (de) ? paint_r : 4'h0;
// assign display_g = (de) ? paint_g : 4'h0;
// assign display_b = (de) ? paint_b : 4'h0;
//
// // SDL output (8 bits per colour channel)
// always @(posedge clk_pix) begin
// 	sdl_sx <= sx;
// 	sdl_sy <= sy;
// 	sdl_de <= de;
// 	sdl_r  <= {2{display_r}};  // double signal width from 4 to 8 bits
// 	sdl_g  <= {2{display_g}};
// 	sdl_b  <= {2{display_b}};
// end
/* verilator lint_on UNUSEDSIGNAL */
