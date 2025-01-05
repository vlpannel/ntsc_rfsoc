`default_nettype none // prevents system from inferring an undeclared logic (good practice)
/*
Module is intended to take a steam of audio and frequency modulate witha ~5.75MHz carrier. 
*/
module FM_mod #
	(
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
        parameter integer CARRIER_FREQ = 4500000, 
		parameter integer FREQ_DEV = 25000,
		parameter integer STEP_FREQ = 250_000_000
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

    assign m00_axis_tvalid = s00_axis_tvalid;
    assign m00_axis_tlast = s00_axis_tlast;
    assign m00_axis_tstrb = s00_axis_tstrb;
    assign m00_axis_tdata = lo_out;
    assign s00_axis_tready = m00_axis_tready;

    FM_sine_generator #(.STEP_FREQ(STEP_FREQ), .FREQUENCY(CARRIER_FREQ), .FREQ_DEV(FREQ_DEV)) lo(
                .clk_in(s00_axis_aclk), 
                .rst_in(!s00_axis_aresetn),
                .step_in(m00_axis_tready),  
				.audio_mod(s00_axis_tdata),
                .amp_out(lo_out)
                );

endmodule

`default_nettype wire