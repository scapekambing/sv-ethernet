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
   localparam int AXIS_TDATA_WIDTH = 8;
   localparam bit AXIS_TKEEP_ENABLE = AXIS_TDATA_WIDTH > 8;

   /* Interfaces */

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) mii_tx_axis_if();

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) input_eth_payload_if();

   ETH_HEADER_IF input_eth_header_if();

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) mii_rx_axis_if();

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) output_eth_payload_if();

   ETH_HEADER_IF output_eth_header_if();

   /* Modules */

   eth_mac_mii_fifo_wrapper # (
      .TARGET(TARGET)
   ) eth_mac_mii_fifo_wrapper_inst (
      .clk(clk),
      .reset(reset),
      .phy_reset(reset),

      .tx_axis_if(mii_tx_axis_if.Receiver),
      .rx_axis_if(mii_rx_axis_if.Transmitter),

      .mii_if(mii_if),

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

   eth_axis_tx_wrapper # (
      .DATA_WIDTH(AXIS_TDATA_WIDTH),
      .KEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) eth_axis_tx_wrapper_inst (
      .clk(clk),
      .reset(reset),

      .mii_axis_if(mii_tx_axis_if.Transmitter),

      .eth_header_in_if(input_eth_header_if.Receiver),
      .eth_payload_in_if(input_eth_payload_if.Receiver),

      .busy()
   );

   eth_axis_rx_wrapper # (
      .DATA_WIDTH(AXIS_TDATA_WIDTH),
      .KEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) eth_axis_rx_wrapper_inst (
      .clk(clk),
      .reset(reset),

      .mii_axis_if(mii_rx_axis_if.Receiver),
   
      .eth_header_out_if(output_eth_header_if.Transmitter),
      .eth_payload_out_if(output_eth_payload_if.Transmitter),

      .busy(),
      .error_header_early_termination()
   );

endmodule

`default_nettype wire