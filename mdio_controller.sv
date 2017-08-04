// MII Management Interface compliant to IEEE 802.3 clause 22
module mdio_controller #(
  parameter integer PHYADDR_LENGTH = 5,
  parameter integer REGADDR_LENGTH = 5,
  parameter integer DATA_LENGTH = 16,
  parameter integer CLOCK_DIVIDER = 50 // (gmii-clk)125MHz/50 = 2.5MHz
  ) (
  input  logic                      clk,
  input  logic                      reset,
  
  output logic                      mdc_o,
  input  logic                      mdio_i,
  output logic                      mdio_o,
  output logic                      mdio_oe,
  
  input  logic                      read,
  input  logic                      write,
  input  logic [PHYADDR_LENGTH-1:0] phy_address,
  input  logic [REGADDR_LENGTH-1:0] reg_address,
  input  logic [DATA_LENGTH-1:0]    write_data,
  output logic [DATA_LENGTH-1:0]    read_data,
  output logic                      access_complete,
  
  output logic                      busy
  );

  typedef enum {
    IDLE,
    TX_PREAMBLE,
    TX_COMMAND,
    RX_TURNAROUND_Z,
    RX_TURNAROUND_Z_READLOW,
    RX_DATA,
    TX_TURNAROUND_HIGH,
    TX_TURNAROUND_LOW,
    TX_DATA,
    DONE
  } state_type;
  state_type state = IDLE;

  localparam PREAMBLE_LENGTH = 32;
  localparam START_LENGTH = 2;
  localparam OPERATION_LENGTH = 2;
  localapram TURNAROUND_LENGTH = 2;
  localparam COMMAND_LENGTH = START_LENGTH+OPERATION_LENGTH+PHYADDR_LENGTH+REGADDR_LENGTH;
  
  localparam bit [1:0] SOF      = 2'b01;
  localparam bit [1:0] OP_READ  = 2'b01;
  localparam bit [1:0] OP_WRITE = 2'b10;
  
  localparam COUNT_WIDTH = $clog2(PREAMBLE_LENGTH);
  logic [COUNT_WIDTH-1:0] count = {COUNT_WIDTH{1'b0}};

  logic [COMMAND_LENGTH-1:0] command;
  logic [DATA_LENGTH-1:0] data;

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
  end
  
  logic request_pending = 1'b0;
  logic write_operation = 1'b0;
  
  always_ff @(posedge clk) begin
    if (reset) begin
      request_pending <= 0;
      write_operation <= 0;
    end else if (state == DONE) begin
      request_pending <= 0;
      write_operation <= 0;
    end else if (!request_pending && state == IDLE && read) begin
      request_pending <= 1;
      write_operation <= 0;
    end else if (!request_pending && state == IDLE && write) begin
      request_pending <= 1;
      write_operation <= 1;
    end
  end
  
  assign busy = request_pending;
  
  always_ff @(posedge clk) begin
    if (!request_pending && state == IDLE && write) begin
      command <= {SOF,OP_WRITE,phy_address,reg_address};
    end else if (!request_pending && state == IDLE && read) begin
      command <= {SOF,OP_READ,phy_address,reg_address};
    end else if (state == TX_COMMAND && clk_div == CLOCK_DIVIDER-1) begin
      command <= {command[COMMAND_LENGTH-2:0],1'b0};
    end
  end

  always_ff @(posedge clk) begin
    if (!request_pending && state == IDLE && write) begin
      data <= write_data;
    end else if (state == TX_DATA && clk_div == CLOCK_DIVIDER-1) begin
      data <= {data[DATA_LENGTH-2:0],1'b0};
    end
  end
  
  always_ff @(posedge clk) begin
    if (state == RX_DATA && clk_div == CLOCK_DIVIDER/4) begin
      read_data <= {read_data[DATA_LENGTH-2:0],mdio_i};
    end
  end
  
  always_ff @(posedge clk) begin
    if (state == DONE && clk_div == CLOCK_DIVIDER-1) begin
      access_complete <= 1'b1;
    end else begin
      access_complete <= 1'b0;
    end
  end
  
  // Driving MDIO-clk
  always_ff @(posedge clk) begin
    if (!(state == IDLE | state == DONE) && clk_div => CLOCK_DIVIDER/2) begin
      mdc_o <= 1'b1;
    end else begin
      mdc_o <= 1'b0;
    end
  end
  
  // Driving MDIO-data
  always_ff @(posedge clk) begin
    case (state)
      TX_PREAMBLE : begin
        mdio_o  <= 1'b1;
        mdio_oe <= 1'b1;
      end
      TX_COMMAND : begin
        mdio_o  <= command[COMMAND_LENGTH-1];
        mdio_oe <= 1'b1;
      end
      TX_TURNAROUND_HIGH : begin
        mdio_o  <= 1'b1;
        mdio_oe <= 1'b1;
      end
      TX_TURNAROUND_LOW : begin
        mdio_o  <= 1'b0;
        mdio_oe <= 1'b1;
      end
      TX_DATA : begin
        mdio_o  <= data[DATA_LENGTH-1];
        mdio_oe <= 1'b1;
      end
      default : begin
        mdio_o  <= 1'b0;
        mdio_oe <= 1'b0;
      end
    endcase
  end
  
  // mdio state-machine for PHY interface
  always_ff @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      count <= {COUNT_WIDTH{1'b0}};
    end else if (clk_div == CLOCK_DIVIDER-1) begin
      case (state)
        IDLE : begin
          if (request_pending) begin
            state <= TX_PREAMBLE;
          end
        end
        TX_PREAMBLE : begin
          if (count >= PREAMBLE_LENGTH-1) begin
            state <= TX_COMMAND;
            count <= {COUNT_WIDTH{1'b0}};
          end else begin
            count <= count + 1;
          end
        end
        TX_COMMAND : begin
          if (count >= COMMAND_LENGTH-1 && write_operation) begin
            state <= TX_TURNAROUND_HIGH;
            count <= {COUNT_WIDTH{1'b0}};
          end else if (count >= COMMAND_LENGTH-1) begin
            state <= RX_TURNAROUND_Z;
            count <= {COUNT_WIDTH{1'b0}};
          end else begin
            count <= count + 1;
          end
        end
        RX_TURNAROUND_Z : begin
          state <= RX_TURNAROUND_Z_READLOW;
        end
        RX_TURNAROUND_Z_READLOW : begin
          state <= RX_DATA;
        end
        TX_TURNAROUND_HIGH : begin
          state <= TX_TURNAROUND_LOW;
        end
        TX_TURNAROUND_LOW : begin
          state <= TX_DATA;
        end
        RX_DATA, TX_DATA : begin
          if (count >= DATA_LENGTH-1) begin
            state <= DONE;
            count <= {COUNT_WIDTH{1'b0}};
          end else begin
            count <= count + 1;
          end
        end
        DONE : begin
          state <= IDLE;
        end
        default : begin
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
