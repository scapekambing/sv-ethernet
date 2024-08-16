/**
 * @file axis_async_fifo_wrapper.sv
 * 
 * @author Mani Magnusson
 * @date   2024
 * 
 * @brief Wrapper for axis_async_fifo.v from Alex Forencich
 */

`default_nettype none

module axis_async_fifo_wrapper # (
    parameter int DEPTH                 = 4096,
    parameter int RAM_PIPELINE          = 1,
    parameter bit OUTPUT_FIFO_ENABLE    = 1'b0,
    parameter bit FRAME_FIFO            = 1'b0,
    parameter bit USER_BAD_FRAME_VALUE  = 1'b1,
    parameter bit USER_BAD_FRAME_MASK   = 1'b1,
    parameter bit DROP_OVERSIZE_FRAME   = FRAME_FIFO,
    parameter bit DROP_BAD_FRAME        = 1'b0,
    parameter bit DROP_WHEN_FULL        = 1'b0,
    parameter bit MARK_WHEN_FULL        = 1'b0,
    parameter bit PAUSE_ENABLE          = 1'b0,
    parameter bit FRAME_PAUSE           = FRAME_FIFO
) (
    input var logic                     tx_clk,
    input var logic                     rx_clk,

    input var logic                     tx_reset,
    input var logic                     rx_reset,

    AXIS_IF.Transmitter                 tx_axis_if,
    AXIS_IF.Receiver                    rx_axis_if,

    input var logic                     tx_pause_req,
    input var logic                     rx_pause_req,

    output var logic                    tx_pause_ack,
    output var logic                    rx_pause_ack,

    output var logic [$clog2(DEPTH):0]  tx_status_depth,
    output var logic [$clog2(DEPTH):0]  rx_status_depth,

    output var logic [$clog2(DEPTH):0]  tx_status_depth_commit,
    output var logic [$clog2(DEPTH):0]  rx_status_depth_commit,

    output var logic                    tx_status_overflow,
    output var logic                    rx_status_overflow,

    output var logic                    tx_status_bad_frame,
    output var logic                    rx_status_bad_frame,

    output var logic                    tx_status_good_frame,
    output var logic                    rx_status_good_frame
);

localparam int DATA_WIDTH   = in_axis_if.TDATA_WIDTH;
localparam bit KEEP_ENABLE  = in_axis_if.TKEEP_ENABLE && (in_axis_if.TKEEP_WIDTH > 0);
localparam int KEEP_WIDTH   = (in_axis_if.TKEEP_WIDTH > 0 ? in_axis_if.TKEEP_WIDTH : 1);
localparam bit LAST_ENABLE  = 1'b1; // Last is just enabled
localparam bit ID_ENABLE    = (in_axis_if.TID_WIDTH > 0);
localparam int ID_WIDTH     = (in_axis_if.TID_WIDTH > 0 ? in_axis_if.TID_WIDTH : 1);
localparam bit DEST_ENABLE  = (in_axis_if.TDEST_WIDTH > 0);
localparam int DEST_WIDTH   = (in_axis_if.TDEST_WIDTH > 0 ? in_axis_if.TDEST_WIDTH : 1);
localparam bit USER_ENABLE  = (in_axis_if.TUSER_WIDTH > 0);
localparam int USER_WIDTH   = (in_axis_if.TUSER_WIDTH > 0 ? in_axis_if.TUSER_WIDTH : 1);

// Spec allows zero width TDATA but nobody seems to support it
initial begin
    assert (in_axis_if.TDATA_WIDTH == out_axis_if.TDATA_WIDTH && in_axis_if.TDATA_WIDTH > 0)
    else $error("Assertion in %m failed, AXIS IF TDATA_WIDTH should be equal and larger than zero");
end

initial begin
    assert (in_axis_if.TID_WIDTH == out_axis_if.TID_WIDTH)
    else $error("Assertion in %m failed, AXIS IF TID_WIDTH should be equal");
end

initial begin
    assert (in_axis_if.TDEST_WIDTH == out_axis_if.TDEST_WIDTH)
    else $error("Assertion in %m failed, AXIS IF TDEST_WIDTH should be equal");
end

initial begin
    assert (in_axis_if.TUSER_WIDTH == out_axis_if.TUSER_WIDTH)
    else $error("Assertion in %m failed, AXIS IF TUSER_WIDTH should be equal");
end

initial begin
    assert (in_axis_if.TKEEP_ENABLE == out_axis_if.TKEEP_ENABLE)
    else $error("Assertion in %m failed, AXIS IF TKEEP_ENABLE should be equal");
end

initial begin
    assert (in_axis_if.TWAKEUP_ENABLE == 0 && out_axis_if.TWAKEUP_ENABLE == 0)
    else $error("Assertion in %m failed, AXIS IF TWAKEUP_ENABLE should be 0");
end

// Driving these signals to zero since they're not supported by the fifo
always_comb begin
    out_axis_if.tstrb = '0;
    out_axis_if.twakeup = 1'b0;
end

axis_async_fifo # (
    .DEPTH(DEPTH),
    .DATA_WIDTH(DATA_WIDTH),
    .KEEP_ENABLE(KEEP_ENABLE),
    .KEEP_WIDTH(KEEP_WIDTH),
    .LAST_ENABLE(LAST_ENABLE),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH),
    .RAM_PIPELINE(RAM_PIPELINE),
    .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
    .FRAME_FIFO(FRAME_FIFO),
    .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
    .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
    .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
    .DROP_BAD_FRAME(DROP_BAD_FRAME),
    .DROP_WHEN_FULL(DROP_WHEN_FULL),
    .MARK_WHEN_FULL(MARK_WHEN_FULL),
    .PAUSE_ENABLE(PAUSE_ENABLE),
    .FRAME_PAUSE(FRAME_PAUSE)
) axis_fifo_inst (
    .m_clk(tx_clk),
    .s_clk(rx_clk),
    
    .m_rst(tx_reset),
    .s_rst(rx_reset),

    .s_axis_tdata(in_axis_if.tdata),
    .s_axis_tkeep(in_axis_if.tkeep),
    .s_axis_tvalid(in_axis_if.tvalid),
    .s_axis_tready(in_axis_if.tready),
    .s_axis_tlast(in_axis_if.tlast),
    .s_axis_tid(in_axis_if.tid),
    .s_axis_tdest(in_axis_if.tdest),
    .s_axis_tuser(in_axis_if.tuser),

    .m_axis_tdata(out_axis_if.tdata),
    .m_axis_tkeep(out_axis_if.tkeep),
    .m_axis_tvalid(out_axis_if.tvalid),
    .m_axis_tready(out_axis_if.tready),
    .m_axis_tlast(out_axis_if.tlast),
    .m_axis_tid(out_axis_if.tid),
    .m_axis_tdest(out_axis_if.tdest),
    .m_axis_tuser(out_axis_if.tuser),

    .m_pause_req(tx_pause_req),
    .s_pause_req(rx_pause_req),

    .m_pause_ack(tx_pause_ack),
    .s_pause_ack(rx_pause_ack),

    .m_status_depth(tx_status_depth),
    .s_status_depth(rx_status_depth),
    
    .m_status_depth_commit(tx_status_depth_commit),
    .s_status_depth_commit(rx_status_depth_commit),
    
    .m_status_overflow(tx_status_overflow),
    .s_status_overflow(rx_status_overflow),

    .m_status_bad_frame(tx_status_bad_frame),
    .s_status_bad_frame(rx_status_bad_frame),
    
    .m_status_good_frame(tx_status_good_frame),
    .s_status_good_frame(rx_status_good_frame)
);

endmodule

`default_nettype wire