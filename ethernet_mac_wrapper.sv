// Ethernet MAC Wrapper with Load/Store-FIFO
module ethernet_mac_wrapper #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_DEPTH = 4,
  parameter MIN_PAYLOAD_LENGTH = 46,
  parameter MAX_PAYLOAD_LENGTH = 1500
  ) (
  input  logic        clk,
  input  logic        reset,
  // MAC-Rx-FIFO Interface
  input  logic        rx_clk,
  input  logic        rx_reset_n,
  output logic [7:0]  rx_tdata,
  output logic        rx_tvalid,
  input  logic        rx_tready,
  output logic        rx_tuser,
  output logic        rx_tlast,
  // MAC-Tx-FIFO Interface
  input  logic        tx_clk,
  input  logic        tx_reset_n,
  input  logic [7:0]  tx_tdata,
  input  logic        tx_tvalid,
  output logic        tx_tready,
  input  logic        tx_tuser,
  input  logic        tx_tlast,
  // MAC-Management Interface
  input  logic [1:0]  speed_mode,     // 1000(1Gbps)/100/10 Mbps
  input  logic        mac_address_filter,
  input  logic [47:0] mac_address,
  // MAC-GMII Interface
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

  logic [7:0]  rx_fifo_tdata;
  logic        rx_fifo_tvalid;
  logic        rx_fifo_tready;
  logic        rx_fifo_tuser;
  logic        rx_fifo_tlast;
  
  logic [7:0]  tx_fifo_tdata;
  logic        tx_fifo_tvalid;
  logic        tx_fifo_tready;
  logic        tx_fifo_tuser;
  logic        tx_fifo_tlast;
  
  ethernet_mac_top #(
    .MIN_PAYLOAD_LENGTH (MIN_PAYLOAD_LENGTH),
    .MAX_PAYLOAD_LENGTH (MAX_PAYLOAD_LENGTH)
  ) ethernet_mac_top_inst (
    .clk                (clk),
    .reset              (reset),
    .rx_tdata           (rx_fifo_tdata),
    .rx_tvalid          (rx_fifo_tvalid),
    .rx_tready          (rx_fifo_tready),
    .rx_tuser           (rx_fifo_tuser),
    .rx_tlast           (rx_fifo_tlast),
    .tx_tdata           (tx_fifo_tdata),
    .tx_tvalid          (tx_fifo_tvalid),
    .tx_tready          (tx_fifo_tready),
    .tx_tuser           (tx_fifo_tuser),
    .tx_tlast           (tx_fifo_tlast),

    .speed_mode         (speed_mode),
    .mac_address_filter (mac_address_filter),
    .mac_address        (mac_address),

    .gtx_clk            (gtx_clk),
    .tx_clk_enable      (tx_clk_enable),
    .gmii_txd           (gmii_txd),
    .gmii_txen          (gmii_txen),
    .gmii_txer          (gmii_txer),
    .col_detect         (col_detect),
    .carrier_sense      (carrier_sense),
    .rx_clk_enable      (rx_clk_enable),
    .gmii_rxd           (gmii_rxd),
    .gmii_rxdv          (gmii_rxdv),
    .gmii_rxer          (gmii_rxer)
  );
  
  axis_fifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_DEPTH (ADDR_DEPTH)
  ) axis_rx_fifo_inst (
    .s_aclk             (clk),
    .s_areset_n         (!reset),
    .s_tdata            (rx_fifo_tdata),
    .s_tkeep            (rx_fifo_tuser),
    .s_tvalid           (rx_fifo_tvalid),
    .s_tready           (rx_fifo_tready),
    .s_tlast            (rx_fifo_tlast),

    .m_aclk             (rx_clk),
    .m_areset_n         (rx_reset_n),
    .m_tdata            (rx_tdata),
    .m_tkeep            (rx_tuser),
    .m_tvalid           (rx_tvalid),
    .m_tready           (rx_tready),
    .m_tlast            (rx_tlast)
  );
  
  axis_fifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_DEPTH (ADDR_DEPTH)
  ) axis_tx_fifo_inst (
    .m_aclk             (clk),
    .m_areset_n         (!reset),
    .m_tdata            (tx_fifo_tdata),
    .m_tkeep            (tx_fifo_tuser),
    .m_tvalid           (tx_fifo_tvalid),
    .m_tready           (tx_fifo_tready),
    .m_tlast            (tx_fifo_tlast),

    .s_aclk             (tx_clk),
    .s_areset_n         (tx_reset_n),
    .s_tdata            (tx_tdata),
    .s_tkeep            (tx_tuser),
    .s_tvalid           (tx_tvalid),
    .s_tready           (tx_tready),
    .s_tlast            (tx_tlast)
  );
  
endmodule
