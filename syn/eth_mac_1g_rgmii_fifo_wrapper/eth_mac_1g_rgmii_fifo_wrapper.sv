/**
 * @file eth_mac_mii_fifo_wrapper.sv
 *
 * @author Edwin Firmansyah
 * @date   2024
 *
 * @brief Wrapper for eth_mac_mii_fifo.v from Alex Forencich
 */

`default_nettype none

module eth_mac_rgmii_1g_fifo_wrapper # (
    // target ("SIM", "GENERIC", "XILINX", "ALTERA")
    parameter TARGET = "GENERIC",
    // IODDR style ("IODDR", "IODDR2")
    // Use IODDR for Virtex-4, Virtex-5, Virtex-6, 7 Series, Ultrascale
    // Use IODDR2 for Spartan-6
    parameter IODDR_STYLE = "IODDR2",
    // Clock input style ("BUFG", "BUFR", "BUFIO", "BUFIO2")
    // Use BUFR for Virtex-6, 7-series
    // Use BUFG for Virtex-5, Spartan-6, Ultrascale
    parameter CLOCK_INPUT_STYLE = "BUFG",
    // Use 90 degree clock for RGMII transmit ("TRUE", "FALSE")
    parameter USE_CLK90 = "TRUE",
    parameter AXIS_DATA_WIDTH = 8,
    parameter AXIS_KEEP_ENABLE = (AXIS_DATA_WIDTH>8),
    parameter AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8),
    parameter ENABLE_PADDING = 1,
    parameter MIN_FRAME_LENGTH = 64,
    parameter TX_FIFO_DEPTH = 4096,
    parameter TX_FIFO_RAM_PIPELINE = 1,
    parameter TX_FRAME_FIFO = 1,
    parameter TX_DROP_OVERSIZE_FRAME = TX_FRAME_FIFO,
    parameter TX_DROP_BAD_FRAME = TX_DROP_OVERSIZE_FRAME,
    parameter TX_DROP_WHEN_FULL = 0,
    parameter RX_FIFO_DEPTH = 4096,
    parameter RX_FIFO_RAM_PIPELINE = 1,
    parameter RX_FRAME_FIFO = 1,
    parameter RX_DROP_OVERSIZE_FRAME = RX_FRAME_FIFO,
    parameter RX_DROP_BAD_FRAME = RX_DROP_OVERSIZE_FRAME,
    parameter RX_DROP_WHEN_FULL = RX_DROP_OVERSIZE_FRAME
) (
    input var logic         clk,
    input var logic         reset,
    input var logic         phy_reset,

    AXIS_IF.Slave           tx_axis_if,
    AXIS_IF.Master          rx_axis_if,
    RGMII_IF.MAC            rgmii_if,

    output var logic        tx_error_underflow,
    output var logic        tx_fifo_overflow,
    output var logic        tx_fifo_bad_frame,
    output var logic        tx_fifo_good_frame,

    output var logic        rx_error_bad_frame,
    output var logic        rx_error_bad_fcs,
    output var logic        rx_fifo_overflow,
    output var logic        rx_fifo_bad_frame,
    output var logic        rx_fifo_good_frame,

    input var logic [7:0]   cfg_ifg,
    input var logic         cfg_tx_enable,
    input var logic         cfg_rx_enable
);

    initial begin
        assert (tx_axis_if.TDATA_WIDTH == rx_axis_if.TDATA_WIDTH)
        else $error("Assertion in %m failed, tx_axis_if and rx_axis_if TDATA_WIDTH don't match");
    end

    initial begin
        assert (tx_axis_if.TID_WIDTH == rx_axis_if.TID_WIDTH && tx_axis_if.TID_WIDTH == 0)
        else $error("Assertion in %m failed, tx_axis_if and rx_axis_if TID_WIDTH should be 0");
    end

    initial begin
        assert (tx_axis_if.TUSER_WIDTH == rx_axis_if.TUSER_WIDTH && tx_axis_if.TUSER_WIDTH == 1)
        else $error("Assertion in %m failed, tx_axis_if and rx_axis_if TUSER_WIDTH should be 1");
    end

    initial begin
        assert (tx_axis_if.TDEST_WIDTH == rx_axis_if.TDEST_WIDTH && tx_axis_if.TDEST_WIDTH == 0)
        else $error("Assertion in %m failed, tx_axis_if and rx_axis_if TDEST_WIDTH should be 0");
    end

    initial begin
        assert (tx_axis_if.TWAKEUP_ENABLE == rx_axis_if.TWAKEUP_ENABLE && tx_axis_if.TWAKEUP_ENABLE == 0)
        else $error("Assertion in %m failed, tx_axis_if and rx_axis_if TWAKEUP_ENABLE should be 0");
    end

    eth_mac_1g_rgmii_fifo # (
        .TARGET(TARGET),
        .IODDR_STYLE(IODDR_STYLE),
        .CLOCK_INPUT_STYLE(CLOCK_INPUT_STYLE),
        .USE_CLK90(USE_CLK90),
        .AXIS_DATA_WIDTH(tx_axis_if.TDATA_WIDTH),
        .AXIS_KEEP_ENABLE(tx_axis_if.TKEEP_ENABLE),
        .AXIS_KEEP_WIDTH(tx_axis_if.TDATA_WIDTH/8),
        .ENABLE_PADDING(ENABLE_PADDING),
        .MIN_FRAME_LENGTH(MIN_FRAME_LENGTH),
        .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
        .TX_FIFO_RAM_PIPELINE(TX_FIFO_RAM_PIPELINE),
        .TX_FRAME_FIFO(TX_FRAME_FIFO),
        .TX_DROP_OVERSIZE_FRAME(TX_DROP_OVERSIZE_FRAME),
        .TX_DROP_BAD_FRAME(TX_DROP_BAD_FRAME),
        .TX_DROP_WHEN_FULL(TX_DROP_WHEN_FULL),
        .RX_FIFO_DEPTH(RX_FIFO_DEPTH),
        .RX_FIFO_RAM_PIPELINE(RX_FIFO_RAM_PIPELINE),
        .RX_FRAME_FIFO(RX_FRAME_FIFO),
        .RX_DROP_OVERSIZE_FRAME(RX_DROP_OVERSIZE_FRAME),
        .RX_DROP_BAD_FRAME(RX_DROP_BAD_FRAME),
        .RX_DROP_WHEN_FULL(RX_DROP_WHEN_FULL)
    ) eth_mac_1g_rgmii_fifo_inst (
        .gtx_clk(clk),
        .gtx_clk90(),
        .gtx_rst(reset),

        .logic_clk(clk),
        .logic_rst(reset),

        .tx_axis_tdata(tx_axis_if.tdata),
        .tx_axis_tkeep(tx_axis_if.tkeep),
        .tx_axis_tvalid(tx_axis_if.tvalid),
        .tx_axis_tready(tx_axis_if.tready),
        .tx_axis_tlast(tx_axis_if.tlast),
        .tx_axis_tuser(tx_axis_if.tuser),

        .rx_axis_tdata(rx_axis_if.tdata),
        .rx_axis_tkeep(rx_axis_if.tkeep),
        .rx_axis_tvalid(rx_axis_if.tvalid),
        .rx_axis_tready(rx_axis_if.tready),
        .rx_axis_tlast(rx_axis_if.tlast),
        .rx_axis_tuser(rx_axis_if.tuser),

        .rgmii_rx_clk(rgmii_if.rx_clk),
        .rgmii_rxd(rgmii_if.rxd),
        .rgmii_rx_ctl(rgmii_if.rx_ctl),
        .rgmii_tx_clk(rgmii_if.tx_clk),
        .rgmii_txd(rgmii_if.txd),
        .rgmii_tx_ctl(rgmii_if.tx_ctl),

        .tx_error_underflow(tx_error_underflow),
        .tx_fifo_overflow(tx_fifo_overflow),
        .tx_fifo_bad_frame(tx_fifo_bad_frame),
        .tx_fifo_good_frame(tx_fifo_good_frame),
        .rx_error_bad_frame(rx_error_bad_frame),
        .rx_fifo_overflow(rx_fifo_overflow),
        .rx_fifo_bad_frame(rx_fifo_bad_frame),
        .rx_fifo_good_frame(rx_fifo_good_frame),

        .cfg_ifg(cfg_ifg),
        .cfg_tx_enable(cfg_tx_enable),
        .cfg_rx_enable(cfg_rx_enable)
    );

endmodule

`default_nettype wire