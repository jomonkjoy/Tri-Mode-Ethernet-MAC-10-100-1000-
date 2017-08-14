// MAC Frame-decapsulation
module mac_decap #(
  parameter MIN_PAYLOAD_LENGTH = 46,
  parameter MAX_PAYLOAD_LENGTH = 1500
  ) (
  input  logic        clk,
  input  logic        reset,
  output logic [7:0]  tdata,
  output logic        tvalid,
  input  logic        tready,
  output logic        tuser,
  output logic        tlast,
  
  input  logic [1:0]  speed_mode, // 1000(1Gbps)/100/10 Mbps
  input  logic        mac_address_filter,
  input  logic [47:0] mac_address,
  
  input  logic        col_detect,     // Collision detect (half-duplex connections only)
  input  logic        carrier_sense,  // Carrier sense (half-duplex connections only)
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
  
  typedef enum {
    IDLE, // wait for SFD
    DATA,
    ERROR,
    SKIP_FRAME
  } state_type;
  state_type state = IDLE;
  
  localparam COUNT_WDTH = $clog2(MAX_FRAME_LENGTH);
  logic [COUNT_WDTH-1:0] count = {COUNT_WDTH{1'b0}};
  
endmodule
