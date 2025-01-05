module fir_15 #
  (
    parameter integer C_S00_AXIS_TDATA_WIDTH  = 32,
    parameter integer C_M00_AXIS_TDATA_WIDTH  = 32
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
 
  localparam NUM_COEFFS = 15;
  logic signed [7:0] coeffs [NUM_COEFFS-1 : 0];
  logic signed [NUM_COEFFS - 1:0][C_S00_AXIS_TDATA_WIDTH - 1:0] intmdt_term;
  logic [NUM_COEFFS - 1:0] m00_axis_tvalid_reg;
  logic [NUM_COEFFS - 1:0] m00_axis_tlast_reg;
  logic [NUM_COEFFS - 1:0][(C_S00_AXIS_TDATA_WIDTH/8)-1: 0] m00_axis_tstrb_reg;

  assign s00_axis_tready = m00_axis_tready;
  assign m00_axis_tvalid = m00_axis_tvalid_reg[NUM_COEFFS-1];
  assign m00_axis_tlast = m00_axis_tlast_reg[NUM_COEFFS-1];
  assign m00_axis_tstrb = m00_axis_tstrb_reg[NUM_COEFFS-1];
  assign m00_axis_tdata = intmdt_term[NUM_COEFFS-1];

  //initializing values
  initial begin //updated you coefficients
    coeffs[0] = -2;
    coeffs[1] = -3;
    coeffs[2] = -4;
    coeffs[3] = 0;
    coeffs[4] = 9;
    coeffs[5] = 21;
    coeffs[6] = 32;
    coeffs[7] = 36;
    coeffs[8] = 32;
    coeffs[9] = 21;
    coeffs[10] = 9;
    coeffs[11] = 0;
    coeffs[12] = -4;
    coeffs[13] = -3;
    coeffs[14] = -2;
    for(int i=0; i < NUM_COEFFS; i++)begin
      intmdt_term[i] = 0;
    end
    $display("DONE!");
  end

  always_ff @(posedge s00_axis_aclk) begin
    if (s00_axis_aresetn == 0)begin
        m00_axis_tvalid_reg <= 0;
        m00_axis_tlast_reg <= 0;
        m00_axis_tstrb_reg <= 0;
        intmdt_term <= 0;
    end else begin
        for (int i = 0; i < NUM_COEFFS; i++) begin
            //Move registers
            if (s00_axis_tvalid) begin
                intmdt_term[i] <= (i > 0 && m00_axis_tready)? $signed(intmdt_term[i-1]) + ($signed(s00_axis_tdata) * $signed(coeffs[i])): (i == 0 && m00_axis_tready)? ($signed(s00_axis_tdata) * $signed(coeffs[i])) : $signed(intmdt_term[i]);
            end else begin
                intmdt_term[i] <= (i > 0 && m00_axis_tready)? $signed(intmdt_term[i-1]) + (0 * $signed(coeffs[i])): (i == 0 && m00_axis_tready)? (0 * $signed(coeffs[i])) :intmdt_term[i];
            end
        end
        if (s00_axis_tvalid) begin
            intmdt_term[NUM_COEFFS-1] <= (m00_axis_tready)? $signed(intmdt_term[NUM_COEFFS-2]) + ($signed(s00_axis_tdata) * $signed(coeffs[NUM_COEFFS-1])): $signed(intmdt_term[NUM_COEFFS-1]);
        end else begin
            intmdt_term[NUM_COEFFS-1] <= (m00_axis_tready)? $signed(intmdt_term[NUM_COEFFS-2]) + (0 * $signed(coeffs[NUM_COEFFS-1])): $signed(intmdt_term[NUM_COEFFS-1]);
        end 
        m00_axis_tvalid_reg <= (m00_axis_tready)? {m00_axis_tvalid_reg[NUM_COEFFS-2:0], s00_axis_tvalid}: m00_axis_tvalid_reg;
        m00_axis_tlast_reg <= (m00_axis_tready)? {m00_axis_tlast_reg[NUM_COEFFS-2:0], s00_axis_tlast}: m00_axis_tlast_reg;
        m00_axis_tstrb_reg <= (m00_axis_tready)? {m00_axis_tstrb_reg[NUM_COEFFS-2:0], s00_axis_tstrb}: m00_axis_tstrb_reg;
    end
  end
 
endmodule