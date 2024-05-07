// SDF_STAGES = 2

// float sdCross( in vec3 p )
// {
//   float da = maxcomp(abs(p.xy));
//   float db = maxcomp(abs(p.yz));
//   float dc = maxcomp(abs(p.zx));
//   return min(da,min(db,dc))-1.0;
// }

/* verilator lint_off UNUSEDSIGNAL */
function static [26:0] fp_abs([26:0] num);
    return {1'd0, num[25:0]};
endfunction

module inf_cross (
    input clk,
    input [26:0] point_x,
    input [26:0] point_y,
    input [26:0] point_z,
    output [26:0] distance
);
    wire xy_comp, yz_comp, zx_comp;
    wire [26:0] da, db, dc;
    FpCompare da_comp_op (
        .iA(fp_abs(point_x)),
        .iB(fp_abs(point_y)),
        .oA_larger(xy_comp)
    );
    assign da = xy_comp ? fp_abs(point_x) : fp_abs(point_y);
    FpCompare db_comp (
        .iA(fp_abs(point_y)),
        .iB(fp_abs(point_z)),
        .oA_larger(yz_comp)
    );
    assign db = yz_comp ? fp_abs(point_y) : fp_abs(point_z);
    FpCompare dc_comp (
        .iA(fp_abs(point_z)),
        .iB(fp_abs(point_x)),
        .oA_larger(zx_comp)
    );
    assign dc = zx_comp ? fp_abs(point_z) : fp_abs(point_x);

    wire db_dc_comp, da_comp;
    wire [26:0] db_dc_min, da_min;
    FpCompare db_dc_comp_op (
        .iA(db),
        .iB(dc),
        .oA_larger(db_dc_comp)
    );
    assign db_dc_min = db_dc_comp ? dc : db;
    FpCompare da_db_dc_comp_op (
        .iA(da),
        .iB(db_dc_min),
        .oA_larger(da_comp)
    );
    assign da_min = da_comp ? db_dc_min : da;
    FpAdd sub_one (
        .iCLK(clk),
        .iA  (da_min),
        .iB  (27'h5fc0000),  // -1.0
        .oSum(distance)
    );
endmodule
/* verilator lint_on UNUSEDSIGNAL */
