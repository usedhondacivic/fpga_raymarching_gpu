/* This files provides address values that exist in the system */

/* Memory */
        .equ  DDR_BASE,             0x40000000
        .equ  DDR_END,              0x7FFFFFFF
        .equ  A9_ONCHIP_BASE,       0xFFFF0000
        .equ  A9_ONCHIP_END,        0xFFFFFFFF
        .equ  SDRAM_BASE,           0x00000000
        .equ  SDRAM_END,            0x03FFFFFF
        .equ  FPGA_ONCHIP_BASE,     0x08000000
        .equ  FPGA_ONCHIP_END,      0x0803FFFF
        .equ  FPGA_CHAR_BASE,       0x09000000
        .equ  FPGA_CHAR_END,        0x09001FFF

/* Cyclone V FPGA devices */
        .equ  LEDR_BASE,             0xFF200000
        .equ  HEX3_HEX0_BASE,        0xFF200020
        .equ  HEX5_HEX4_BASE,        0xFF200030
		.equ  HEX7_HEX4_BASE,        0xFF200030 /* Redundant HEX7_HEX4 needed for existing NIOS2 programs. */
        .equ  SW_BASE,               0xFF200040
        .equ  KEY_BASE,              0xFF200050
        .equ  JP1_BASE,              0xFF200060
        .equ  JP2_BASE,              0xFF200070
        .equ  PS2_BASE,              0xFF200100
        .equ  PS2_DUAL_BASE,         0xFF200108
        .equ  JTAG_UART_BASE,        0xFF201000
        .equ  JTAG_UART_2_BASE,      0xFF201008
        .equ  IrDA_BASE,             0xFF201020
        .equ  TIMER_BASE,            0xFF202000
        .equ  TIMER_2_BASE,          0xFF202020
        .equ  AV_CONFIG_BASE,        0xFF203000
        .equ  PIXEL_BUF_CTRL_BASE,   0xFF203020
        .equ  CHAR_BUF_CTRL_BASE,    0xFF203030
        .equ  AUDIO_BASE,            0xFF203040
        .equ  VIDEO_IN_BASE,         0xFF203060
        .equ  ADC_BASE,              0xFF204000

/* Cyclone V HPS devices */
        .equ  HPS_GPIO1_BASE,        0xFF709000
        .equ  I2C0_BASE,             0xFFC04000
        .equ  I2C1_BASE,             0xFFC05000
        .equ  I2C2_BASE,             0xFFC06000
        .equ  I2C3_BASE,             0xFFC07000
        .equ  HPS_TIMER0_BASE,       0xFFC08000
        .equ  HPS_TIMER1_BASE,       0xFFC09000
        .equ  HPS_TIMER2_BASE,       0xFFD00000
        .equ  HPS_TIMER3_BASE,       0xFFD01000
        .equ  FPGA_BRIDGE,           0xFFD0501C
