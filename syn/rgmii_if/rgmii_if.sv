/**
 * @file mii_if.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief MII Interface Definition, skips CRS and COL lines
 */

`default_nettype none

interface RGMII_IF #(
    // No parameters
);
  var logic       tx_clk;
  var logic [3:0] txd;
  var logic       tx_ctl;

  var logic       rx_clk;
  var logic [3:0] rxd;
  var logic       rx_ctl;

  modport MAC(
      output tx_clk,
      output txd,
      output tx_ctl,

      input rx_clk,
      input rxd,
      input rx_ctl
  );

  modport Observer(
      input tx_clk,
      input txd,
      input tx_ctl,

      input rx_clk,
      input rxd,
      input rx_ctl
  );

endinterface

`default_nettype wire
