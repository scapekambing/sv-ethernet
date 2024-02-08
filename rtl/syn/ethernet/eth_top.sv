/**
 * @file eth_top.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief Top module of Ethernet stack
 */

`default_nettype none

module eth_top # (
   parameter string TARGET = "GENERIC"
) (
   input var logic clk,
   input var logic reset,

   MII_IF.MAC mii_if
);
   AXIS_IF loopback_axis_if();

   eth_mac_mii_fifo_wrapper # (
      .TARGET(TARGET)
   ) eth_mac_mii_fifo_wrapper_inst (
      .clk(clk),
      .reset(reset),
      .phy_reset(reset),

      .tx_axis_if(loopback_axis_if.Receiver),
      .rx_axis_if(loopback_axis_if.Transmitter),

      .mii_if(mii_if.MAC),

      .tx_error_underflow(),
      .tx_fifo_overflow(),
      .tx_fifo_bad_frame(),
      .tx_fifo_good_frame(),
      
      .rx_error_bad_frame(),
      .rx_error_bad_fcs(),
      .rx_fifo_overflow(),
      .rx_fifo_bad_frame(),
      .rx_fifo_good_frame(),

      .cfg_ifg(8'd12),
      .cfg_tx_enable(1'b1),
      .cfg_rx_enable(1'b1)
   );
endmodule

`default_nettype wire