/**
 * @file udp_axis_axil_bridge.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief UDP AXI-Stream to AXI-Lite bridge
*/

/* TODO:
 *  - Figure out the state machine for creating AXI-Lite transfers
 *  - Figure out how to actually create a state machine for AXI-Lite transfers
*/

`default_nettype none

module udp_axis_axil_bridge # (
    parameter bit [15:0] UDP_PORT = 1234,
    parameter int REQUEST_BUFFER_SIZE = 64
) (
    input var logic clk,
    input var logic reset,

    UDP_INPUT_HEADER_IF.Input udp_header_output_if,
    AXIS_IF.Receiver udp_payload_output_if,

    UDP_OUTPUT_HEADER_IF.Output udp_header_input_if,
    AXIS_IF.Transmitter udp_payload_input_if,

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

    /* TODO:
        Find a better name than just state_t for the high level SM states
    */

    // Opcode for what to do
    typedef enum logic [1:0] { 
        WRITE_DATA=0,
        READ_DATA=1,
        WRITE_OK=2,
        READ_OK=3
    } opcode_t;

    typedef struct packed {
        opcode_t opcode;
        var logic [29:0] address;
        var logic [31:0] data;
    } request_t;

    typedef union packed {
        request_t request;
        var logic [7:0][7:0] byte;
        // TODO: Add 64-bit representation
    } request_union_t;

    request_union_t [REQUEST_BUFFER_SIZE-1:0] requests;

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
            state = STATE_RX_HEADER;
        end else begin
            case (state)
                // Read in a UDP header
                STATE_RX_HEADER : begin
                    udp_output_header_if.ready <= 1'b1;

                    if (udp_output_header_if.hdr_valid && udp_output_header_if.hdr_ready) begin
                        udp_output_header_if.ready <= 1'b0;

                        source_ip <= udp_output_header_if.ip_source_ip;
                        dest_ip <= udp_output_header_if.ip_dest_ip;
                        source_port <= udp_output_header_if.source_port;
                        dest_port <= udp_output_header_if.dest_port;
                        frame_length <= udp_output_header_if.length;
                        
                        // TODO: Check if length % 64 == 0
                        if (udp_output_header_if.dest_port == UDP_PORT) begin
                            request_id <= '0;
                            byte_id <= '0;
                            state <= STATE_RX_PAYLOAD;
                        end else begin
                            state <= STATE_RX_DISCARD;
                        end
                    end
                end

                // Discard the packet, not for us.
                STATE_RX_DISCARD : begin
                    udp_payload_output_if.tready <= 1'b1;
                    if (udp_payload_output_if.tvalid && udp_output_payload_if.tready && udp_output_payload_if.tlast) begin
                        udp_output_payload_if.tready <= 1'b0;
                        state <= STATE_RX_HEADER;
                    end
                end
                
                // Receive the payload and insert into request_t buffer
                STATE_RX_PAYLOAD : begin
                    udp_payload_output_if.tready <= 1'b1;

                    if (udp_payload_output_if.tvalid && udp_payload_output_if.tready) begin
                        // TODO: Check endianness if running into issues
                        requests[request_id].byte[byte_id] <= udp_payload_output_if.tdata;
                        
                        if (byte_id == 8) begin
                            byte_id <= '0;
                            request_id <= request_id + 1;
                        end
                        
                        if (udp_payload_output_if.tlast) begin
                            if (udp_payload_output_if.tuser) begin
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
                            requests[request_id].request.opcode <= requests[request_id].request.opcode & 2'b01;
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
                    axil_if.arprot <= AXI_PROT_UNPRIVILEGED_NONSECURE_DATA;
                    // Pad the msb with zeros
                    axil_if.araddr <= {2'b0, requests[request_id].request.address};

                    if (axil_if.arvalid && axil_if.arready) begin
                        axil_if.arvalid <= 1'b0;
                        state <= STATE_AXIL_READ_DATA;
                    end
                end
                
                // AXI-Lite transfer
                STATE_AXIL_READ_DATA : begin
                    axil_if.rready <= 1'b1;

                    if (axil_if.rready && axil_if.rvalid) begin
                        // TODO: Check rresp to see if the data is valid or not
                        requests[request_id].request.data <= rdata;
                        
                        if (request_id == request_count) begin
                            // TODO: Add more stuff that may be needed
                            state <= STATE_TX_HEADER;
                        end else begin
                            request_id <= request_id + 1;
                            state <= STATE_PROCESS_REQUEST;
                        end
                    end
                end
                
                // AXI-Lite transfer
                STATE_AXIL_WRITE_ADDRESS : begin
                end
                
                // AXI-Lite transfer
                STATE_AXIL_WRITE_DATA : begin
                end
                
                // AXI-Lite transfer
                STATE_AXIL_WRITE_RESPONSE : begin
                    if (request_id == request_count) begin
                        // TODO: Add more stuff that may be needed
                        state <= STATE_TX_HEADER;
                    end else begin
                        request_id <= request_id + 1;
                        state <= STATE_PROCESS_REQUEST;
                    end
                end

                //
                STATE_TX_HEADER : begin
                end

                //
                STATE_TX_DATA : begin
                end
                
            endcase
        end
    end 

endmodule

`default_nettype wire