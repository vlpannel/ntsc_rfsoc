module mixer #
	(
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
        parameter integer PHASE = 0,
		parameter integer STEP_FREQ = 200_000_000, //Hz
		parameter integer FREQUENCY = 3_580_000 //Hz
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

    assign s00_axis_tready = m00_axis_tready;
	assign m00_axis_tvalid = s00_axis_tvalid;
	assign m00_axis_tstrb = s00_axis_tstrb;
	assign m00_axis_tlast = s00_axis_tlast;
	assign m00_axis_tdata = ($signed(s00_axis_tdata) * $signed(lo_out)) >>> 16;

    sine_generator #(.PHASE(PHASE), .FREQUENCY(FREQUENCY), .STEP_FREQ(STEP_FREQ)) lo(
                    .clk_in(s00_axis_aclk), 
                    .rst_in(!s00_axis_aresetn),
                    .step_in(m00_axis_tready),  
                    .amp_out(lo_out)
                    );
endmodule