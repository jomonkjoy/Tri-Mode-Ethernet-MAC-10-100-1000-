// MAC Frame-decapsulation
module mac_decap #(
  parameter MIN_PAYLOAD_LENGTH = 46,
  parameter MAX_PAYLOAD_LENGTH = 1500
  ) (
  input  logic        clk,
  input  logic        reset,
  output logic [7:0]  tdata,
  output logic        tvalid,
  input  logic        tready, // not connected
  output logic        tuser,
  output logic        tlast,
  
  input  logic [1:0]  speed_mode, // 1000(1Gbps)/100/10 Mbps
  input  logic        mac_address_filter,
  input  logic [47:0] mac_address,
  
  input  logic        col_detect,     // Collision detect (half-duplex connections only)
  input  logic        carrier_sense,  // Carrier sense (half-duplex connections only)
  input  logic        clk_enable,
  input  logic [7:0]  gmii_rxd,       // Received data
  input  logic        gmii_rxdv,      // Signifies data received is valid
  input  logic        gmii_rxer       // Signifies data received has errors
  );
  
  localparam MIN_FRAME_LENGTH = MIN_PAYLOAD_LENGTH+6+6+2;
  localparam MAX_FRAME_LENGTH = MAX_PAYLOAD_LENGTH+6+6+2;
  localparam PREAMBLE_LENGTH = 7;
  localparam FCS_LENGTH = 4;
  localparam IFG_LENGTH = 12;
  localparam PREAMBLE_DATA = 8'h55;
  localparam SFD_DATA = 8'hD5;
  localparam IFG_DATA = 8'h00;
  localparam CRC32_RESIDUE = 32'hC704DD7B; // magic number or CRC32 residue
  
  typedef enum {
    IDLE, // wait for SFD
    DATA,
    SKIP_FRAME
  } state_type;
  state_type state = IDLE;
  
  localparam COUNT_WDTH = $clog2(MAX_FRAME_LENGTH);
  logic [COUNT_WDTH-1:0] count = {COUNT_WDTH{1'b0}};
  
  always_ff @(posedge clk) begin
    if (state == DATA && ~gmii_rxdv) begin
      tuser <= gmii_rxer | count <= MIN_FRAME_LENGTH+FCS_LENGTH-1 | count >= MAX_FRAME_LENGTH+FCS_LENGTH-1 | crc_cal != CRC32_RESIDUE;
    end else begin
      tuser <= gmii_rxer;
    end
  end
  
  always_ff @(posedge clk) begin
    tdata <= gmii_rxd;
  end
  
  always_ff @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      count <= {COUNT_WDTH{1'b0}};
    end else if (clk_enable) begin
      case (state)
        IDLE : begin
          if (gmii_rxdv && gmii_rxer) begin
            state <= SKIP_FRAME;
          end else if (gmii_rxdv && gmii_rxd == SFD_DATA) begin
            state <= DATA;
          end else if (gmii_rxdv && gmii_rxd == PREAMBLE_DATA) begin
            state <= IDLE;
          end else if (gmii_rxdv) begin
            state <= SKIP_FRAME;
          end
        end
        DATA : begin
          if (gmii_rxdv && count >= MAX_FRAME_LENGTH+FCS_LENGTH-1) begin
            state <= SKIP_FRAME;
            count <= {COUNT_WDTH{1'b0}};
          end else if (gmii_rxdv) begin
            count <= count + 1;
          end else begin
            state <= IDLE;
            count <= {COUNT_WDTH{1'b0}};
          end
        end
        SKIP_FRAME : begin
          if (~gmii_rxdv) begin
            state <= IDLE;
          end
        end
        default : begin
          state <= IDLE;
          count <= {COUNT_WDTH{1'b0}};
        end
      endcase
    end
  end
  
endmodule
