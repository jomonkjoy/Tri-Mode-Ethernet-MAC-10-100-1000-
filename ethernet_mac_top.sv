// MAC Frame-decapsulation & encapsulation
module ethernet_mac_top #(
  parameter MIN_PAYLOAD_LENGTH = 46,
  parameter MAX_PAYLOAD_LENGTH = 1500
  ) (
  input  logic        clk,
  input  logic        reset,
  output logic [7:0]  rx_tdata,
  output logic        rx_tvalid,
  input  logic        rx_tready,      // not connected
  output logic        rx_tuser,
  output logic        rx_tlast,
  
  input  logic [7:0]  tx_tdata,
  input  logic        tx_tvalid,
  output logic        tx_tready,
  input  logic        tx_tuser,
  input  logic        tx_tlast,

  input  logic [1:0]  speed_mode,     // 1000(1Gbps)/100/10 Mbps
  input  logic        mac_address_filter,
  input  logic [47:0] mac_address,
  
  
  output logic        gtx_clk,        // Clock signal for gigabit TX signals (125 MHz)
  input  logic        col_detect,     // Collision detect (half-duplex connections only)
  input  logic        carrier_sense,  // Carrier sense (half-duplex connections only)
  input  logic        rx_clk_enable,  // Clock signal for 10/100 Mbit/s signals
  output logic        tx_clk_enable,  // Clock signal for 10/100 Mbit/s signals
  output logic [7:0]  gmii_txd,       // Data to be transmitted
  output logic        gmii_txen,      // Transmitter enable
  output logic        gmii_txer,      // Transmitter error (used to corrupt a packet)
  input  logic [7:0]  gmii_rxd,       // Received data
  input  logic        gmii_rxdv,      // Signifies data received is valid
  input  logic        gmii_rxer       // Signifies data received has errors
  );
  
  ethernet_mac_decap #(
    .MIN_PAYLOAD_LENGTH (MIN_PAYLOAD_LENGTH),
    .MAX_PAYLOAD_LENGTH (MAX_PAYLOAD_LENGTH)
  ) ethernet_mac_decap_inst (
    .clk                (clk),
    .reset              (reset),
    .tdata              (rx_tdata),
    .tvalid             (rx_tvalid),
    .tready             (rx_tready),
    .tuser              (rx_tuser),
    .tlast              (rx_tlast),
  
    .speed_mode         (speed_mode),
    .mac_address_filter (mac_address_filter),
    .mac_address        (mac_address),
  
    .col_detect         (col_detect),
    .carrier_sense      (carrier_sense),
    .clk_enable         (rx_clk_enable),
    .gmii_rxd           (gmii_rxd),
    .gmii_rxdv          (gmii_rxdv),
    .gmii_rxer          (gmii_rxer)
  );

  ethernet_mac_encap #(
    .MIN_PAYLOAD_LENGTH (MIN_PAYLOAD_LENGTH),
    .MAX_PAYLOAD_LENGTH (MAX_PAYLOAD_LENGTH)
  ) ethernet_mac_encap_inst (
    .clk                (clk),
    .reset              (reset),
    .tdata              (tx_tdata),
    .tvalid             (tx_tvalid),
    .tready             (tx_tready),
    .tuser              (tx_tuser),
    .tlast              (tx_tlast),
  
    .speed_mode         (speed_mode),
    .mac_address        (mac_address),
  
    .gtx_clk            (gtx_clk),
    .clk_enable         (tx_clk_enable),
    .gmii_txd           (gmii_txd),
    .gmii_txen          (gmii_txen),
    .gmii_txer          (gmii_txer)
  );
  
endmodule
