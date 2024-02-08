/**
 * @file mii_if.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief MII Interface Definition, skips CRS and COL lines
 */

`default_nettype none

interface MII_IF # (
    // No parameters
);
    var logic       tx_clk;
    var logic [3:0] txd;
    var logic       tx_en;

    var logic       rx_clk;
    var logic [3:0] rxd;
    var logic       rx_dv;
    var logic       rx_er;
    var logic       crs;
    var logic       col;

    modport MAC (
        input tx_clk,
        output txd,
        output tx_en,
        
        input rx_clk,
        input rxd,
        input rx_dv,
        input rx_er,
        input crs,
        input col
    );

    modport PHY (
        output tx_clk,
        input txd,
        input tx_en,
        
        output rx_clk,
        output rxd,
        output rx_dv,
        output rx_er,
        output crs,
        output col
    );

    modport Monitor (
        input tx_clk,
        input txd,
        input rx_en,
        
        input rx_clk,
        input rxd,
        input rx_dv,
        input rx_er,
        input crs,
        input col
    );

endinterface

`default_nettype wire