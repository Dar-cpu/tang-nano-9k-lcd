// Copyright (C) 2014-2022 Gowin Semiconductor Corporation.
// All rights reserved.
// Part Number: GW1NR-LV9QN88PC6/15
// Device: GW1NR-9C

module lcd_clock_tmp (
    input      clkin_i,     // Reloj de entrada
    output     clkout_o,    // Salida de reloj principal
    output     clkoutd_o    // Salida de reloj dividido
);

    Gowin_rPLL your_instance_name (
        .clkout(clkout_o),  // output clkout
        .clkoutd(clkoutd_o), // output clkoutd
        .clkin(clkin_i)      // input clkin
    );

endmodule