// MII Management Interface compliant to IEEE 802.3 clause 22
module mdio_controller #(
  parameter integer CLOCK_DIVIDER = 50 // (gmii-clk)125MHz/50 = 2.5MHz
  ) (
  input  logic clk,
  input  logic reset,
  output logic busy
);

typedef enum {
  IDLE,
  PREAMBLE,
  START,
  OPERATION,
  PHYADDR,
  REGADDR,
  TURNAROUND,
  DATA,
  DONE
} state_type;
state_type state = IDLE;

localparam PREAMBLE_LENGTH = 32;
localparam START_LENGTH = 2;
localparam OPERATION_LENGTH = 2;
localparam PHYADDR_LENGTH = 5;
localparam REGADDR_LENGTH = 5;
localapram TURNAROUND_LENGTH = 2;
localapram DATA_LENGTH = 16;

localparam COUNT_WIDTH = $clog2(PREAMBLE_LENGTH);
logic [COUNT_WIDTH-1:0] count = {COUNT_WIDTH{1'b0}};

// clock divider logic for MDC
localparam CLKDIV_WIDTH = $clog2(CLOCK_DIVIDER);
logic [CLKDIV_WIDTH-1:0] clk_div = {CLKDIV_WIDTH{1'b0}};

always_ff @(posedge clk) begin
  if (reset) begin
    clk_div <= {CLKDIV_WIDTH{1'b0}};
  end else begin
    if (clk_div >= CLOCK_DIVIDER-1) begin
      clk_div <= {CLKDIV_WIDTH{1'b0}};
    end else begin
      clk_div <= clk_div + 1;
    end
end

always_ff @(posedge clk) begin
  if (reset) begin
    state <= IDLE;
  end else if (clk_div == CLOCK_DIVIDER-1) begin
    case (state)
      IDLE : begin
      end
      default : begin
        state <= IDLE;
      end
    endcase
  end
end

endmodule
