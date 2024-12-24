module fir_param #
  (
    parameter integer C_S00_AXIS_TDATA_WIDTH  = 32,
    parameter integer C_M00_AXIS_TDATA_WIDTH  = 32,
    parameter integer NUM_COEFFS = 15,
    parameter logic [NUM_COEFFS*8-1:0] COEFFS = {8'd254, 8'd253, 8'd252, 8'd0, 8'd9, 8'd21, 8'd32, 8'd36, 8'd32, 8'd21, 8'd9, 8'd0, 8'd252, 8'd253, 8'd254} // 256 - abs(num) for negative numbers
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

  logic signed [7:0] coeffs [NUM_COEFFS-1 : 0];
  logic signed [C_M00_AXIS_TDATA_WIDTH+NUM_COEFFS:0] intmdt_term [NUM_COEFFS-1:0];
  logic [(C_S00_AXIS_TDATA_WIDTH/8)-1:0] strb [NUM_COEFFS-1:0];
  logic [$clog2(NUM_COEFFS)-1:0] first_ix, last_ix;
  logic me_ready;

  // for viewing in gtkwave
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term0; assign intmdt_term0 = intmdt_term[0];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term1; assign intmdt_term1 = intmdt_term[1];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term2; assign intmdt_term2 = intmdt_term[2];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term3; assign intmdt_term3 = intmdt_term[3];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term4; assign intmdt_term4 = intmdt_term[4];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term5; assign intmdt_term5 = intmdt_term[5];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term6; assign intmdt_term6 = intmdt_term[6];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term7; assign intmdt_term7 = intmdt_term[7];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term8; assign intmdt_term8 = intmdt_term[8];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term9; assign intmdt_term9 = intmdt_term[9];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term10; assign intmdt_term10 = intmdt_term[10];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term11; assign intmdt_term11 = intmdt_term[11]; 
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term12; assign intmdt_term12 = intmdt_term[12]; 
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term13; assign intmdt_term13 = intmdt_term[13]; 
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_term14; assign intmdt_term14 = intmdt_term[14];
  logic signed [(C_M00_AXIS_TDATA_WIDTH)-1:0] intmdt_last; assign intmdt_last = intmdt_term[NUM_COEFFS-1]; 
  logic signed [7:0] coeff0; assign coeff0 = coeffs[0];
  logic signed [7:0] coeff1; assign coeff1 = coeffs[1];
  logic signed [7:0] coeff2; assign coeff2  = coeffs[2];
  logic signed [7:0] coeff3; assign coeff3  = coeffs[3];
  logic signed [7:0] coeff_last; assign coeff_last = coeffs[NUM_COEFFS-1];

  logic rst = (~s00_axis_aresetn) | (~m00_axis_aresetn);
  logic new_intake = (s00_axis_tready & s00_axis_tvalid);
  logic last_vals = ((last_ix > 0) & m00_axis_tready);

  //initializing values                                   
  initial begin
    for(int i=0; i<NUM_COEFFS; i++)begin
      coeffs[i] = $signed(COEFFS >> (8*i));
      intmdt_term[i] = 0;
    end
    $display("DONE!");
  end

  assign s00_axis_tready = m00_axis_tready & me_ready;

  always_ff @(posedge s00_axis_aclk) begin

    if ((~s00_axis_aresetn) | (~m00_axis_aresetn)) begin
      for (int i = 0; i < NUM_COEFFS; i++) begin
        intmdt_term[i] <= 0;
        strb[i] <= -1;
      end

      first_ix <= 0;
      last_ix <= 0;

      me_ready <= 1;
      m00_axis_tvalid <= 0;
      m00_axis_tlast <= 0;
      m00_axis_tdata <= 0;
      m00_axis_tstrb <= -1; // default strobe is 0xF

    end else if (s00_axis_tready & s00_axis_tvalid) begin // intake new value
      intmdt_term[0] <= $signed(s00_axis_tdata) * coeffs[0];
      strb[0] <= s00_axis_tstrb;
      for (int i = 1; i < NUM_COEFFS; i++) begin
        intmdt_term[i] <= ($signed(s00_axis_tdata) * coeffs[i]) + intmdt_term[i-1];
        strb[i] <= strb[i-1];
      end

      m00_axis_tdata <= intmdt_term[NUM_COEFFS-1];
      m00_axis_tstrb <= strb[NUM_COEFFS-1];

      if (s00_axis_tlast) begin // handle last signals
        last_ix <= last_ix + 1;
        me_ready <= 0; // don't ask for new data once last is passed through
      end else begin
        me_ready <= 1;
      end

      if ((first_ix >= NUM_COEFFS)) begin // handle output validity (first sample passthrough)
        m00_axis_tvalid <= 1;
      end else if (first_ix < NUM_COEFFS) begin // first sample not yet through
        m00_axis_tvalid <= 0;
        first_ix <= first_ix + 1;
      end

    end else if (((last_ix > 0) | (~me_ready)) & m00_axis_tready) begin // passing in last data, zero-padding
      intmdt_term[0] <= 0;
      strb[0] <= -1;
      for (int i = 1; i < NUM_COEFFS; i++) begin
        intmdt_term[i] <= ($signed(0) * coeffs[i]) + intmdt_term[i-1]; // 0 is "new input"
        strb[i] <= strb[i-1];
      end

      m00_axis_tdata <= intmdt_term[NUM_COEFFS-1];
      m00_axis_tstrb <= strb[NUM_COEFFS-1];

      if (last_ix <= NUM_COEFFS) begin // normal passing through last part of fir signal
        me_ready <= (last_ix == NUM_COEFFS)? 1 : 0;
        m00_axis_tvalid <= (first_ix < NUM_COEFFS - 1)? 0 : 1;
        m00_axis_tlast <= (last_ix == NUM_COEFFS)? 1 : 0;
        last_ix <= last_ix + 1;
        first_ix <= (first_ix < NUM_COEFFS)? first_ix + 1 : first_ix;
      end else begin // done passing through
        me_ready <= 1;
        m00_axis_tvalid <= 0;
		m00_axis_tlast <= 0;
        last_ix <= 0;
        first_ix <= 0;
        for (int i = 0; i < NUM_COEFFS; i++) intmdt_term[i] <= 0;
      end
       

    end else begin // dunno what case this would be--I guess "default" behavior
      me_ready <= 1;
      m00_axis_tvalid <= 0;
      m00_axis_tlast <= 0;
      m00_axis_tstrb <= -1;
    end

  end
 
endmodule
