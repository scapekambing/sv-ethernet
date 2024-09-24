/**
 * @file udp_axis_master.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief UDP to AXI-Stream master with packet ID
 */

`default_nettype none

module udp_axis_master # (
    parameter bit [15:0] UDP_PORT = 4321
) (
    input var logic         clk,
    input var logic         reset,

    UDP_TX_HEADER_IF.Source udp_tx_header_if,
    AXIS_IF.Master          udp_tx_payload_if,

    UDP_RX_HEADER_IF.Sink   udp_rx_header_if,
    AXIS_IF.Slave           udp_rx_payload_if,

    AXIS_IF.Master          out_axis_if
);
    typedef enum {
        STATE_RX_HEADER,
        STATE_RX_DISCARD,
        STATE_RX_ID,
        STATE_RX_DATA,
        STATE_TX_HEADER,
        STATE_TX_ID
    } state_t;

    state_t state;

    var logic [31:0] source_ip;
    var logic [31:0] dest_ip;
    var logic [15:0] source_port;
    var logic [15:0] dest_port;
    var logic [15:0] frame_length;

    var logic [47:0] transfer_id;
    var logic [5:0] id_byte_index;

    AXIS_IF # (
        .TDATA_WIDTH(8),
        .TUSER_WIDTH(1)
    ) axis_mux_to_udp_if();

    AXIS_IF # (
        .TDATA_WIDTH(8),
        .TUSER_WIDTH(1)
    ) axis_mux_to_adapter_if();

    always_comb begin
        if (state == STATE_RX_DATA) begin
            axis_mux_to_adapter_if.tvalid   = udp_rx_payload_if.tvalid;
            axis_mux_to_adapter_if.tdata    = udp_rx_payload_if.tdata;
            axis_mux_to_adapter_if.tstrb    = udp_rx_payload_if.tstrb;
            axis_mux_to_adapter_if.tkeep    = udp_rx_payload_if.tkeep;
            axis_mux_to_adapter_if.tlast    = udp_rx_payload_if.tlast;
            axis_mux_to_adapter_if.tid      = udp_rx_payload_if.tid;
            axis_mux_to_adapter_if.tdest    = udp_rx_payload_if.tdest;
            axis_mux_to_adapter_if.tuser    = udp_rx_payload_if.tuser;
            axis_mux_to_adapter_if.twakeup  = udp_rx_payload_if.twakeup;
            
            axis_mux_to_udp_if.tvalid   = '0;
            axis_mux_to_udp_if.tdata    = '0;
            axis_mux_to_udp_if.tstrb    = '0;
            axis_mux_to_udp_if.tkeep    = '0;
            axis_mux_to_udp_if.tlast    = '0;
            axis_mux_to_udp_if.tid      = '0;
            axis_mux_to_udp_if.tdest    = '0;
            axis_mux_to_udp_if.tuser    = '0;
            axis_mux_to_udp_if.twakeup  = '0;
            
            udp_rx_payload_if.tready = axis_mux_to_adapter_if.tready;
        end else if (state == STATE_RX_DISCARD) begin
            axis_mux_to_adapter_if.tvalid   = '0;
            axis_mux_to_adapter_if.tdata    = '0;
            axis_mux_to_adapter_if.tstrb    = '0;
            axis_mux_to_adapter_if.tkeep    = '0;
            axis_mux_to_adapter_if.tlast    = '0;
            axis_mux_to_adapter_if.tid      = '0;
            axis_mux_to_adapter_if.tdest    = '0;
            axis_mux_to_adapter_if.tuser    = '0;
            axis_mux_to_adapter_if.twakeup  = '0;
            
            axis_mux_to_udp_if.tvalid   = '0;
            axis_mux_to_udp_if.tdata    = '0;
            axis_mux_to_udp_if.tstrb    = '0;
            axis_mux_to_udp_if.tkeep    = '0;
            axis_mux_to_udp_if.tlast    = '0;
            axis_mux_to_udp_if.tid      = '0;
            axis_mux_to_udp_if.tdest    = '0;
            axis_mux_to_udp_if.tuser    = '0;
            axis_mux_to_udp_if.twakeup  = '0;
            
            udp_rx_payload_if.tready = 1'b1;
        end else begin
            axis_mux_to_adapter_if.tvalid   = '0;
            axis_mux_to_adapter_if.tdata    = '0;
            axis_mux_to_adapter_if.tstrb    = '0;
            axis_mux_to_adapter_if.tkeep    = '0;
            axis_mux_to_adapter_if.tlast    = '0;
            axis_mux_to_adapter_if.tid      = '0;
            axis_mux_to_adapter_if.tdest    = '0;
            axis_mux_to_adapter_if.tuser    = '0;
            axis_mux_to_adapter_if.twakeup  = '0;

            axis_mux_to_udp_if.tvalid   = udp_rx_payload_if.tvalid;
            axis_mux_to_udp_if.tdata    = udp_rx_payload_if.tdata;
            axis_mux_to_udp_if.tstrb    = udp_rx_payload_if.tstrb;
            axis_mux_to_udp_if.tkeep    = udp_rx_payload_if.tkeep;
            axis_mux_to_udp_if.tlast    = udp_rx_payload_if.tlast;
            axis_mux_to_udp_if.tid      = udp_rx_payload_if.tid;
            axis_mux_to_udp_if.tdest    = udp_rx_payload_if.tdest;
            axis_mux_to_udp_if.tuser    = udp_rx_payload_if.tuser;
            axis_mux_to_udp_if.twakeup  = udp_rx_payload_if.twakeup;
            
            udp_rx_payload_if.tready = axis_mux_to_udp_if.tready;
        end
    end

    always_ff @ (posedge clk) begin
        if (reset) begin
            state <= STATE_RX_HEADER;
            
            udp_tx_header_if.hdr_valid <= 1'b0;
            udp_tx_payload_if.tvalid <= 1'b0;
            udp_tx_payload_if.tuser <= 1'b0; // Constantly set to zero

            udp_rx_header_if.hdr_ready <= 1'b0;
            axis_mux_to_udp_if.tready <= 1'b0;
        end else begin
            case (state)
                // Read in a UDP header
                STATE_RX_HEADER : begin
                    udp_rx_header_if.hdr_ready <= 1'b1;

                    if (udp_rx_header_if.hdr_valid && udp_rx_header_if.hdr_ready) begin
                        udp_rx_header_if.hdr_ready <= 1'b0;

                        source_ip <= udp_rx_header_if.ip_source_ip;
                        dest_ip <= udp_rx_header_if.ip_dest_ip;
                        source_port <= udp_rx_header_if.source_port;
                        dest_port <= udp_rx_header_if.dest_port;
                        frame_length <= udp_rx_header_if.length;

                        if (udp_rx_header_if.dest_port == UDP_PORT) begin
                            axis_mux_to_udp_if.tready <= 1'b1;
                            id_byte_index <= 48'd0;

                            state <= STATE_RX_ID;
                        end else begin
                            axis_mux_to_udp_if.tready <= 1'b1;
                            state <= STATE_RX_DISCARD;
                        end
                    end
                end

                // Discard the packet
                STATE_RX_DISCARD : begin
                    if (udp_rx_payload_if.tvalid && udp_rx_payload_if.tready && udp_rx_payload_if.tlast) begin
                        axis_mux_to_udp_if.tready <= 1'b0;
                        state <= STATE_RX_HEADER;
                    end
                end

                // Read the transfer ID
                STATE_RX_ID : begin
                    if (udp_rx_payload_if.tvalid && udp_rx_payload_if.tready) begin
                        transfer_id[((8 * (id_byte_index + 1)) - 1) -: 8] <= axis_mux_to_udp_if.tdata;
                        id_byte_index <= id_byte_index + 1;

                        if (id_byte_index == 5) begin
                            axis_mux_to_udp_if.tready <= 1'b0;
                            state <= STATE_RX_DATA;
                        end
                    end
                end

                // Read the data
                STATE_RX_DATA : begin
                    if (udp_rx_payload_if.tvalid && udp_rx_payload_if.tready && udp_rx_payload_if.tlast) begin
                        udp_tx_header_if.hdr_valid      <= 1'b1;
                        udp_tx_header_if.ip_dscp        <= '0;
                        udp_tx_header_if.ip_ecn         <= '0;
                        udp_tx_header_if.ip_ttl         <= 64;
                        udp_tx_header_if.ip_source_ip   <= dest_ip;
                        udp_tx_header_if.ip_dest_ip     <= source_ip;
                        udp_tx_header_if.source_port    <= dest_port;
                        udp_tx_header_if.dest_port      <= source_port;
                        udp_tx_header_if.length         <= 14;
                        udp_tx_header_if.checksum       <= '0;

                        state <= STATE_TX_HEADER;
                    end
                end

                // Transmit a UDP header
                STATE_TX_HEADER : begin
                    if (udp_tx_header_if.hdr_valid && udp_tx_header_if.hdr_ready) begin
                        udp_tx_header_if.hdr_valid <= 1'b0;

                        id_byte_index <= 48'd1;

                        udp_tx_payload_if.tvalid <= 1'b1;
                        udp_tx_payload_if.tdata <= transfer_id[7:0];
                        udp_tx_payload_if.tlast <= 1'b0;

                        state <= STATE_TX_ID;
                    end
                end

                // Transmit the transfer ID
                STATE_TX_ID : begin
                    if (udp_tx_payload_if.tvalid && udp_tx_payload_if.tready) begin
                        udp_tx_payload_if.tdata <= transfer_id[((8 * (id_byte_index + 1)) - 1) -: 8];
                        udp_tx_payload_if.tlast <= id_byte_index == 5;

                        id_byte_index <= id_byte_index + 1;

                        if (udp_tx_payload_if.tlast) begin
                            udp_tx_payload_if.tvalid <= 1'b0;

                            state <= STATE_RX_HEADER;
                        end
                    end
                end
            endcase
        end
    end

    axis_adapter_wrapper axis_adapter_wrapper_inst (
        .clk(clk),
        .reset(reset),
        .in_axis_if(axis_mux_to_adapter_if),
        .out_axis_if(out_axis_if)
    );

endmodule