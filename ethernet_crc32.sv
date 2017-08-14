//-----------------------------------------------------------------------------
// As defined in IEEE 802.3 clause 3.2.9
// CRC module for data[7:0] ,   crc[31:0]=1+x^1+x^2+x^4+x^5+x^7+x^8+x^10+x^11+x^12+x^16+x^22+x^23+x^26+x^32;
//-----------------------------------------------------------------------------
module ethernet_crc32 #(
  parameter DATA_WIDTH = 8,
  parameter POLY_WIDTH = 32,
  parameter POLYNOMIAL = 33'h104C11DB7
  ) (
  input  logic                  clk,
  input  logic                  reset,
  input  logic                  crc_en,
  input  logic [DATA_WIDTH-1:0] data_in,
  output logic [POLY_WIDTH-1:0] crc_out
  );
  
  function [POLY_WIDTH-1:0] update_crc;
    input [POLY_WIDTH-1:0] old_crc;
    input data_in;
    input [POLY_WIDTH-0:0] polynomial;
    reg [POLY_WIDTH-1:0] new_crc;
    reg feedback;
    begin
      feedback = old_crc[POLY_WIDTH-1] ^ data_in;
      new_crc = old_crc << 1;
      update_crc = feedback ? new_crc ^ polynomial[POLY_WIDTH-1:0] : new_crc;
    end
  endfunction

  function [POLY_WIDTH-1:0] update_crc_parallel;
    input [POLY_WIDTH-1:0] old_crc;
    input [DATA_WIDTH-1:0] data_in;
    input [POLY_WIDTH-0:0] polynomial;
    reg [POLY_WIDTH-1:0] new_crc;
    integer i;
    begin
      new_crc = old_crc;
      for (i=0; i<DATA_WIDTH; i=i+1) begin
        new_crc = update_crc(new_crc, data_in[i], polynomial);
      end
      update_crc_parallel = new_crc;
    end
  endfunction
  
  always_ff @(posedge clk) begin
    if (reset) begin
      crc_out <= {32{1'b1}};
    end else if (crc_en) begin
      crc_out <= update_crc_parallel(crc_out,data_in,POLYNOMIAL);
    end
  end
  
endmodule
