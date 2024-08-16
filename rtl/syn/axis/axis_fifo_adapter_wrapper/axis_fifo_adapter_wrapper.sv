/**
 * @file axis_fifo_wrapper.sv
 * 
 * @author Mani Magnusson
 * @date   2024
 * 
 * @brief Wrapper for axis_fifo.v from Alex Forencich
 */

`default_nettype none

module axis_fifo_wrapper # (
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
    input var logic                     clk,
    input var logic                     reset,

    AXIS_IF.Receiver                    in_axis_if,
    AXIS_IF.Transmitter                 out_axis_if,

    input var logic                     pause_req,
    output var logic                    pause_ack,

    output var logic [$clog2(DEPTH):0]  status_depth,
    output var logic [$clog2(DEPTH):0]  status_depth_commit,
    output var logic                    status_overflow,
    output var logic                    status_bad_frame,
    output var logic                    status_good_frame
);

    localparam int IN_DATA_WIDTH   = in_axis_if.TDATA_WIDTH;
    localparam bit IN_KEEP_ENABLE  = in_axis_if.TKEEP_ENABLE && (in_axis_if.TKEEP_WIDTH > 0);
    localparam int IN_KEEP_WIDTH   = (in_axis_if.TKEEP_WIDTH > 0 ? in_axis_if.TKEEP_WIDTH : 1);
    localparam int OUT_DATA_WIDTH   = out_axis_if.TDATA_WIDTH;
    localparam bit OUT_KEEP_ENABLE  = out_axis_if.TKEEP_ENABLE && (out_axis_if.TKEEP_WIDTH > 0);
    localparam int OUT_KEEP_WIDTH   = (out_axis_if.TKEEP_WIDTH > 0 ? out_axis_if.TKEEP_WIDTH : 1);
    localparam bit LAST_ENABLE  = 1'b1; // Last is just enabled
    localparam bit ID_ENABLE    = (in_axis_if.TID_WIDTH > 0);
    localparam int ID_WIDTH     = (in_axis_if.TID_WIDTH > 0 ? in_axis_if.TID_WIDTH : 1);
    localparam bit DEST_ENABLE  = (in_axis_if.TDEST_WIDTH > 0);
    localparam int DEST_WIDTH   = (in_axis_if.TDEST_WIDTH > 0 ? in_axis_if.TDEST_WIDTH : 1);
    localparam bit USER_ENABLE  = (in_axis_if.TUSER_WIDTH > 0);
    localparam int USER_WIDTH   = (in_axis_if.TUSER_WIDTH > 0 ? in_axis_if.TUSER_WIDTH : 1);

    // Spec allows zero width TDATA but nobody seems to support it
    initial begin
        assert (in_axis_if.TDATA_WIDTH > 0 && out_axis_if.TDATA_WIDTH > 0)
        else $error("Assertion in %m failed, AXIS IF TDATA_WIDTH should be larger than zero");
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
        assert (in_axis_if.TWAKEUP_ENABLE == 0 && out_axis_if.TWAKEUP_ENABLE == 0)
        else $error("Assertion in %m failed, AXIS IF TWAKEUP_ENABLE should be 0");
    end

    // Driving these signals to zero since they're not supported by the fifo
    always_comb begin
        out_axis_if.tstrb = '0;
        out_axis_if.twakeup = 1'b0;
    end

    axis_adapter_fifo # (
        .DEPTH(DEPTH),
        .S_DATA_WIDTH(IN_DATA_WIDTH),
        .S_KEEP_ENABLE(IN_KEEP_ENABLE),
        .S_KEEP_WIDTH(IN_KEEP_WIDTH),
        .M_DATA_WIDTH(OUT_DATA_WIDTH),
        .M_KEEP_ENABLE(OUT_KEEP_ENABLE),
        .M_KEEP_WIDTH(OUT_KEEP_WIDTH),
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
    ) axis_adapter_fifo_inst (
        .clk(clk),
        .rst(reset),

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

        .pause_req(pause_req),
        .pause_ack(pause_ack),

        .status_depth(status_depth),
        .status_depth_commit(status_depth_commit),
        .status_overflow(status_overflow),
        .status_bad_frame(status_bad_frame),
        .status_good_frame(status_good_frame)
    );

endmodule

`default_nettype wire