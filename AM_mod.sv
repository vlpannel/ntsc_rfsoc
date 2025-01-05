module AM_mod #
  (
    parameter integer C_S00_AXIS_TDATA_WIDTH  = 32,
    parameter integer C_M00_AXIS_TDATA_WIDTH  = 32,
    parameter STEP_FREQ = 1_000_000_000, // in Hz
    parameter CARRIER_FREQ = 55_250_000 // in Hz
  )
  (
  // Ports of Axi Slave Bus Interface S00_AXIS
  input wire  s00_axis_aclk, s00_axis_aresetn,
  input wire  s00_axis_tlast, s00_axis_tvalid,
  input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
  input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1: 0] s00_axis_tstrb,
  output logic  s00_axis_tready,
 
  // Ports of Axi Master Bus Interface M00_AXIS
  input wire  m00_axis_aclk, m00_axis_aresetn,
  input wire  m00_axis_tready,
  output logic  m00_axis_tvalid, m00_axis_tlast,
  output logic [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
  output logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] m00_axis_tstrb
  );

  logic signed [15:0] lo_out;

  assign s00_axis_tready = m00_axis_tready; // ready if slave ready and not resetting
  assign m00_axis_tvalid = s00_axis_tvalid; // output valid if input valid and not resetting
  assign m00_axis_tlast = s00_axis_tlast;
  assign m00_axis_tdata = (s00_axis_tdata * lo_out) >> 16;  // use only MSBs
  assign m00_axis_tstrb = s00_axis_tstrb;


  sine_generator #(.STEP_FREQUENCY(CLK_FREQ), .FREQUENCY(CARRIER_FREQ)) sg // step freq is clk, freq is sine
                     ( .clk_in(s00_axis_aclk),
                       .rst_in(!s00_axis_aresetn),
                       .step_in(1),//m00_tready & m00_tvalid),
                       .amp_out(lo_out)
                     );

endmodule
