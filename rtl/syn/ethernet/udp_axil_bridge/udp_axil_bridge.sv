/**
 * @file udp_axis_axil_bridge.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief UDP AXI-Stream to AXI-Lite bridge
*/

/* TODO:
 *  - Make address write and data write channels happen in parallel
*/

`default_nettype none

package udp_axil_bridge_types;
    // Opcode for what to do
    typedef enum logic [1:0] { 
        WRITE_DATA=0,
        READ_DATA=1,
        WRITE_OK=2,
        READ_OK=3
    } opcode_t;

    typedef struct packed {
        opcode_t opcode;
        logic [29:0] address;
        logic [31:0] data;
    } request_t;

    typedef union packed {
        request_t request;
        logic [7:0][7:0] bytes;
        // TODO: Add 64-bit representation
    } request_union_t;
endpackage

import udp_axil_bridge_types::*;

module udp_axil_bridge # (
    parameter bit [15:0] UDP_PORT = 1234,
    parameter int REQUEST_BUFFER_SIZE = 64
) (
    input var logic clk,
    input var logic reset,

    // Logic to PHY
    UDP_TX_HEADER_IF.Source udp_tx_header_if,
    AXIS_IF.Transmitter udp_tx_payload_if,

    // PHY to logic
    UDP_RX_HEADER_IF.Sink udp_rx_header_if,
    AXIS_IF.Receiver udp_rx_payload_if,

    AXIL_IF.Master axil_if
);
    /*
        Get a header valid
        Read header params and set header ready
        Read stream data into buffer
        Parse each request and issue AXI-L transfers
        Fill the same buffer from earlier with results from transfers
        If transfer successful, set bit 63 to 1, otherwise keep it at 0
        At end of AXI-L transfers send the buffer back to the UDP module
    */

    request_union_t requests [REQUEST_BUFFER_SIZE-1:0];

    // Fourth time is the charm??
    // TODO: Add the rest of the states
    typedef enum {
        STATE_RX_HEADER,
        STATE_RX_DISCARD,
        STATE_RX_PAYLOAD,
        STATE_PROCESS_REQUEST,
        STATE_AXIL_READ_ADDRESS,
        STATE_AXIL_READ_DATA,
        STATE_AXIL_WRITE_ADDRESS,
        STATE_AXIL_WRITE_DATA,
        STATE_AXIL_WRITE_RESPONSE,
        STATE_TX_HEADER,
        STATE_TX_DATA
    } state_t;

    state_t state;

    var logic [31:0] source_ip;
    var logic [31:0] dest_ip;
    var logic [15:0] source_port;
    var logic [15:0] dest_port;
    var logic [15:0] frame_length;

    var logic [2:0] byte_id;
    var logic [$clog2(REQUEST_BUFFER_SIZE)-1:0] request_id;
    var logic [$clog2(REQUEST_BUFFER_SIZE)-1:0] request_count;

    always_ff @ (posedge clk) begin
        if (reset) begin
            // Reset signals
            state           <= STATE_RX_HEADER;
            axil_if.awvalid <= 1'b0;
            axil_if.wvalid  <= 1'b0;
            axil_if.bready  <= 1'b0;
            axil_if.arvalid <= 1'b0;
            axil_if.rready  <= 1'b0;
            
            udp_tx_header_if.hdr_valid <= 1'b0;
            udp_tx_payload_if.tvalid <= 1'b0;
            udp_rx_header_if.hdr_ready<= 1'b0;
            udp_rx_payload_if.tready <= 1'b0;
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
                        
                        // TODO: Check if length % 64 == 0
                        if (udp_rx_header_if.dest_port == UDP_PORT) begin
                            udp_rx_payload_if.tready <= 1'b1;
                            request_id <= '0;
                            byte_id <= '0;
                            state <= STATE_RX_PAYLOAD;
                        end else begin
                            udp_rx_payload_if.tready <= 1'b1;
                            state <= STATE_RX_DISCARD;
                        end
                    end
                end

                // Discard the packet, not for us.
                STATE_RX_DISCARD : begin
                    if (udp_rx_payload_if.tvalid && udp_rx_payload_if.tready && udp_rx_payload_if.tlast) begin
                        udp_rx_payload_if.tready <= 1'b0;
                        state <= STATE_RX_HEADER;
                    end
                end
                
                // Receive the payload and insert into request_t buffer
                STATE_RX_PAYLOAD : begin
                    if (udp_rx_payload_if.tvalid && udp_rx_payload_if.tready) begin
                        // TODO: Check endianness if running into issues
                        requests[request_id].bytes[byte_id] <= udp_rx_payload_if.tdata;
                        
                        if (byte_id == 7) begin
                            byte_id <= '0;
                            request_id <= request_id + 1;
                        end else begin
                            byte_id <= byte_id + 1;
                        end
                        
                        if (udp_rx_payload_if.tlast) begin
                            if (udp_rx_payload_if.tuser) begin
                                // tuser indicates bad frame, ignore
                                state <= STATE_RX_HEADER;
                            end else begin
                                request_count <= request_id;
                                request_id <= '0;
                                state <= STATE_PROCESS_REQUEST;
                            end
                        end
                    end
                end

                // Process the requests we have
                STATE_PROCESS_REQUEST : begin
                    case (requests[request_id].request.opcode)
                        WRITE_DATA : begin
                            state <= STATE_AXIL_WRITE_ADDRESS;
                        end

                        READ_DATA : begin
                            state <= STATE_AXIL_READ_ADDRESS;
                        end

                        default : begin
                            // Invalid opcode, don't issue request
                            requests[request_id].request.opcode <= opcode_t'(requests[request_id].request.opcode & 2'b01);
                            // Check if the invalid request was the last request in the list
                            if (request_id == request_count) begin
                                state <= STATE_TX_HEADER;
                            end else begin
                                request_id = request_id + 1;
                            end
                        end
                    endcase
                end

                // AXI-Lite transfer
                STATE_AXIL_READ_ADDRESS : begin
                    axil_if.arvalid <= 1'b1;
                    axil_if.arprot <= axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA;
                    // Pad the msb with zeros
                    axil_if.araddr <= {2'b0, requests[request_id].request.address};

                    if (axil_if.arready && axil_if.arvalid) begin
                        axil_if.arvalid <= 1'b0;
                        axil_if.rready <= 1'b1;
                        state <= STATE_AXIL_READ_DATA;
                    end
                end
                
                // AXI-Lite transfer
                STATE_AXIL_READ_DATA : begin
                    if (axil_if.rready && axil_if.rvalid) begin
                        axil_if.rready <= 1'b0;
                        requests[request_id].request.data <= axil_if.rdata;
                        if (axil_if.rresp == axil_if.AXI_RESP_OKAY) begin
                            requests[request_id].request.opcode <= READ_OK;
                        end

                        if (request_id == request_count) begin
                            request_id <= '0;
                            state <= STATE_TX_HEADER;
                        end else begin
                            request_id <= request_id + 1;
                            state <= STATE_PROCESS_REQUEST;
                        end
                    end
                end
                
                // AXI-Lite transfer
                STATE_AXIL_WRITE_ADDRESS : begin
                    axil_if.awvalid <= 1'b1;
                    axil_if.awprot <= axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA;
                    // Pad the msb with zeros
                    axil_if.awaddr <= {2'b0, requests[request_id].request.address};

                    if (axil_if.awready && axil_if.awvalid) begin
                        axil_if.awvalid <= 1'b0;
                        state <= STATE_AXIL_WRITE_DATA;
                    end
                end
                
                // AXI-Lite transfer
                STATE_AXIL_WRITE_DATA : begin
                    axil_if.wvalid <= 1'b1;
                    axil_if.wstrb <= '1;
                    axil_if.wdata <= requests[request_id].request.data;

                    if (axil_if.wready && axil_if.wvalid) begin
                        axil_if.wvalid <= 1'b0;
                        axil_if.bready <= 1'b1;
                        state <= STATE_AXIL_WRITE_RESPONSE;
                    end
                end
                
                // AXI-Lite transfer
                STATE_AXIL_WRITE_RESPONSE : begin
                    if (axil_if.bready && axil_if.bvalid) begin
                        axil_if.bready <= 1'b0;
                        if (axil_if.bresp == axil_if.AXI_RESP_OKAY) begin
                            requests[request_id].request.opcode <= WRITE_OK;
                        end
                        if (request_id == request_count) begin
                            request_id <= '0;
                            
                            udp_tx_header_if.hdr_valid <= 1'b1;
                            udp_tx_header_if.ip_dscp <= '0;
                            udp_tx_header_if.ip_ecn <= '0;
                            udp_tx_header_if.ip_ttl <= 64;
                            udp_tx_header_if.ip_source_ip <= dest_ip;
                            udp_tx_header_if.ip_dest_ip <= source_ip;
                            udp_tx_header_if.source_port <= dest_port;
                            udp_tx_header_if.dest_port <= source_port;
                            udp_tx_header_if.length <= frame_length;
                            udp_tx_header_if.checksum <= '0;

                            byte_id <= '0;
                            request_id <= '0;

                            state <= STATE_TX_HEADER;
                        end else begin
                            request_id <= request_id + 1;
                            state <= STATE_PROCESS_REQUEST;
                        end
                    end
                end

                // Transmit UDP header
                STATE_TX_HEADER : begin
                    if (udp_tx_header_if.hdr_ready && udp_tx_header_if.hdr_valid) begin
                        udp_tx_header_if.hdr_valid <= 1'b0;

                        udp_tx_payload_if.tvalid <= 1'b1;
                        udp_tx_payload_if.tdata <= requests[request_id].bytes[byte_id];
                        udp_tx_payload_if.tlast <= '0;
                        udp_tx_payload_if.tuser <= '0;
                        byte_id <= byte_id + 1;

                        state <= STATE_TX_DATA;
                    end
                end

                // Transmit UDP data
                STATE_TX_DATA : begin
                    if (udp_tx_payload_if.tready && udp_tx_payload_if.tvalid) begin
                        udp_tx_payload_if.tdata <= requests[request_id].bytes[byte_id];

                        if (byte_id == 7) begin
                            byte_id <= '0;
                            request_id <= request_id + 1;
                        end else begin
                            byte_id <= byte_id + 1;
                        end

                        if (request_id == request_count) begin
                            if (byte_id == 7) begin
                                udp_tx_payload_if.tlast <= 1'b1;
                                udp_tx_payload_if.tuser <= 1'b0;
                            end
                            if (byte_id == 8) begin
                                state <= STATE_RX_HEADER;
                            end
                        end
                    end
                end
                
            endcase
        end
    end

    ila_0 ila_0_inst (
        .clk    ( clk ),
        .probe0 ( state ),
        .probe1 ( udp_rx_header_if.dest_port ),
        .probe2 ( {udp_rx_header_if.hdr_valid, udp_rx_header_if.hdr_ready} ),
        .probe3 ( {udp_tx_header_if.length, udp_tx_payload_if.tvalid, udp_tx_payload_if.tready} ),
        .probe4 ( {udp_rx_payload_if.tvalid, udp_rx_payload_if.tready} ),
        .probe5 ( '0 ),
        .probe6 ( '0 ),
        .probe7 ( '0 )
    );

endmodule

`default_nettype wire