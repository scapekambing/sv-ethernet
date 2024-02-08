/**
 * @file eth_mac_mii_fifo_wrapper.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief Wrapper for eth_mac_mii_fifo.v from Alex Forencich
 */

`default_nettype none

module eth_mac_mii_fifo_wrapper # (
    // Optins are "SIM", "GENERIC", "XILINX", "ALTERA"
    parameter string TARGET             = "GENERIC",
    // OPtions are "BUFG", "BUFR", "BUFIO", "BUFIO2"
    // Use BUFR for Virtex-5, Virtex-6, 7-Series
    // Use BUFG for Ultrascale
    // Use BUFIO2 for Spartan-6
    parameter string CLOCK_INPUT_STYLE      = "BUFR",
    parameter bit ENABLE_PADDING            = '1,
    parameter int MIN_FRAME_LENGTH          = 64,
    parameter int TX_FIFO_DEPTH             = 4096,
    parameter bit TX_FIFO_RAM_PIPELINE      = '1,
    parameter bit TX_FRAME_FIFO             = '1,
    parameter bit TX_DROP_OVERSIZE_FRAME    = TX_FRAME_FIFO,
    parameter bit TX_DROP_BAD_FRAME         = TX_DROP_OVERSIZE_FRAME,
    parameter bit TX_DROP_WHEN_FULL         = 0,
    parameter int RX_FIFO_DEPTH             = 4096,
    parameter bit RX_FIFO_RAM_PIPELINE      = '1,
    parameter bit RX_FRAME_FIFO             = '1,
    parameter bit RX_DROP_OVERSIZE_FRAME    = RX_FRAME_FIFO,
    parameter bit RX_DROP_BAD_FRAME         = RX_DROP_OVERSIZE_FRAME,
    parameter bit RX_DROP_WHEN_FULL         = RX_DROP_OVERSIZE_FRAME
) (
    input var logic         clk,
    input var logic         reset,
    input var logic         phy_reset,

    AXIS_IF.Receiver        tx_axis_if,
    AXIS_IF.Transmitter     rx_axis_if,
    MII_IF.MAC              mii_if,

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

    eth_mac_mii_fifo # (
        .TARGET(TARGET),
        .CLOCK_INPUT_STYLE(CLOCK_INPUT_STYLE),
        .AXIS_DATA_WIDTH(tx_axis_if.TDATA_WIDTH),
        .AXIS_KEEP_ENABLE(tx_axis_if.TKEEP_ENABLE),
        .AXIS_KEEP_WIDTH(tx_axis_if.TDATA_WIDTH/8),
        .ENABLE_PADDING(ENABLE_PADDING),
        .MIN_FRAME_LENGTH(MIN_FRAME_LENGTH),
        .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
        .TX_FIFO_RAM_PIPELINE(TX_FIFO_RAM_PIPELINE),
        .TX_DROP_OVERSIZE_FRAME(TX_DROP_OVERSIZE_FRAME),
        .TX_DROP_BAD_FRAME(TX_DROP_BAD_FRAME),
        .TX_DROP_WHEN_FULL(TX_DROP_WHEN_FULL),
        .RX_FIFO_DEPTH(TX_FIFO_DEPTH),
        .RX_FIFO_RAM_PIPELINE(RX_FIFO_RAM_PIPELINE),
        .RX_FRAME_FIFO(RX_FRAME_FIFO),
        .RX_DROP_OVERSIZE_FRAME(RX_DROP_OVERSIZE_FRAME),
        .RX_DROP_BAD_FRAME(RX_DROP_BAD_FRAME),
        .RX_DROP_WHEN_FULL(RX_DROP_WHEN_FULL)
    ) eth_mac_mii_fifo_inst (
        .rst(phy_reset),
        .logic_clk(clk),
        .logic_rst(reset),

        .tx_axis_tdata(tx_axis_if.tdata),
        .tx_axis_tkeep(tx_axis_if.tkeep),
        .tx_axis_tvalid(tx_axis_if.tvalid),
        .tx_axis_tready(tx_axis_if.tready),
        .tx_axis_tlast(tx_axis_if.tlast),
        .tx_axis_tuser(tx_axis_if.tuser),

        .rx_axis_tdata(rx_axis_if.tdata),
        .rx_axis_tkeep(tx_axis_if.tkeep),
        .rx_axis_tvalid(rx_axis_if.tvalid),
        .rx_axis_tready(rx_axis_if.tready),
        .rx_axis_tlast(rx_axis_if.tlast),
        .rx_axis_tuser(rx_axis_if.tuser),

        .mii_rx_clk(mii_if.rx_clk),
        .mii_rxd(mii_if.rxd),
        .mii_rx_dv(mii_if.rx_dv),
        .mii_rx_er(mii_if.rx_er),
        .mii_tx_clk(mii_if.tx_clk),
        .mii_txd(mii_if.txd),
        .mii_tx_en(mii_if.tx_en),
        .mii_tx_er(mii_if.tx_er),

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