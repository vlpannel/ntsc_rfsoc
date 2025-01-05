`default_nettype none // prevents system from inferring an undeclared logic (good practice)
/*
Inputs visual
*/

module LUV_mod #
	(
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer STEP_FREQ = 200_000_000,
		parameter integer SUBCARRIER = 3_580_000
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

	localparam TAPS = 481;

	//Solve for I and Q
	logic signed [8:0] I, Q;
	logic [8:0] Y;

	assign I = ((s00_axis_tdata[15:8] * 2'b11) >> 2) - (s00_axis_tdata[7:0] >> 2);
	assign Q = (s00_axis_tdata[15:8] >> 1) + (s00_axis_tdata[7:0] >> 1);
	assign Y = s00_axis_tdata[23:16];

	//Pipeline Y to add at the end
	logic [TAPS-1:0][7:0] y_pipeline;

	//Outputs for the sine gen and filters
	logic Iout_tready, Iout_tvalid, Iout_tlast, Ifilter_tready, Ifilter_tvalid, Ifilter_tlast;
	logic signed [31 : 0] Iout_tdata, Ifilter_tdata;
	logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] Iout_tstrb, Ifilter_tstrb;

	logic Qout_tready, Qout_tvalid, Qout_tlast,Qfilter_tready, Qfilter_tvalid, Qfilter_tlast;
	logic signed [31 : 0] Qout_tdata, Qfilter_tdata;
	logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] Qout_tstrb, Qfilter_tstrb;

	assign s00_axis_tready = m00_axis_tready;

	assign m00_axis_tdata = Y + 8'd77;//((Iout_tdata + Qout_tdata + Y) <<< 6) + 15'd11108;// + (y_pipeline[TAPS-1]);// + 15'd11108; //Sum of Chromas
	assign m00_axis_tvalid = Iout_tvalid;
	assign m00_axis_tstrb = Iout_tstrb;
	assign m00_axis_tlast = Iout_tlast;

	// assign m00_axis_tdata = $signed(Ifilter_tdata[31:16]);// + $signed(Qfilter_tdata);//; + (y_pipeline[TAPS-1] << 6) + 15'd11108; //Sum of Chromas
	// assign m00_axis_tvalid = Ifilter_tvalid;
	// assign m00_axis_tstrb = Ifilter_tstrb;
	// assign m00_axis_tlast = Ifilter_tlast;

	always_ff @(posedge s00_axis_aclk)begin
		if (s00_axis_aresetn == 0) begin
			y_pipeline <= 0;
		end else if(m00_axis_tready) begin
			for (int i = 0; i < TAPS; i++) begin 
				y_pipeline[i] <= (i == 0)? s00_axis_tdata[23:16]: y_pipeline[i-1];
			end
		end
	end

	mixer #(.PHASE(0), .STEP_FREQ(STEP_FREQ), .FREQUENCY(SUBCARRIER)) in_phase(
				.s00_axis_aclk(s00_axis_aclk),
				.s00_axis_aresetn(s00_axis_aresetn),
				.s00_axis_tlast(s00_axis_tlast),
				.s00_axis_tvalid(s00_axis_tvalid),
				.s00_axis_tdata(I),
				.s00_axis_tstrb(s00_axis_tstrb),
				.s00_axis_tready(Iout_tready),
		
				// Ports of Axi Master Bus Interface M00_AXIS
				.m00_axis_aclk(m00_axis_aclk),
				.m00_axis_aresetn(m00_axis_aresetn),
				.m00_axis_tready(m00_axis_tready),
				.m00_axis_tvalid(Iout_tvalid), 
				.m00_axis_tlast(Iout_tlast),
				.m00_axis_tdata(Iout_tdata),
				.m00_axis_tstrb(Iout_tstrb)
				);

	mixer #(.PHASE(90), .STEP_FREQ(STEP_FREQ), .FREQUENCY(SUBCARRIER)) quadrature(
				.s00_axis_aclk(s00_axis_aclk),
				.s00_axis_aresetn(s00_axis_aresetn),
				.s00_axis_tlast(s00_axis_tlast),
				.s00_axis_tvalid(s00_axis_tvalid),
				.s00_axis_tdata(Q),
				.s00_axis_tstrb(s00_axis_tstrb),
				.s00_axis_tready(Qout_tready),
		
				// Ports of Axi Master Bus Interface M00_AXIS
				.m00_axis_aclk(m00_axis_aclk),
				.m00_axis_aresetn(m00_axis_aresetn),
				.m00_axis_tready(m00_axis_tready),
				.m00_axis_tvalid(Qout_tvalid), 
				.m00_axis_tlast(Qout_tlast),
				.m00_axis_tdata(Qout_tdata),
				.m00_axis_tstrb(Qout_tstrb)
				);

	// uvfilter #(.NUM_COEFFS(TAPS)) I_filter(
	// 			.s00_axis_aclk(s00_axis_aclk),
	// 			.s00_axis_aresetn(s00_axis_aresetn),
	// 			.s00_axis_tlast(Iout_tlast),
	// 			.s00_axis_tvalid(Iout_tvalid),
	// 			.s00_axis_tdata(Iout_tdata),
	// 			.s00_axis_tstrb(Iout_tstrb),
	// 			.s00_axis_tready(Ifilter_tready),
		
	// 			// Ports of Axi Master Bus Interface M00_AXIS
	// 			.m00_axis_aclk(m00_axis_aclk),
	// 			.m00_axis_aresetn(m00_axis_aresetn),
	// 			.m00_axis_tready(m00_axis_tready),
	// 			.m00_axis_tvalid(Ifilter_tvalid), 
	// 			.m00_axis_tlast(Ifilter_tlast),
	// 			.m00_axis_tdata(Ifilter_tdata),
	// 			.m00_axis_tstrb(Ifilter_tstrb)
	// 			);

	// uvfilter #(.NUM_COEFFS(TAPS)) Q_filter(
	// 			.s00_axis_aclk(s00_axis_aclk),
	// 			.s00_axis_aresetn(s00_axis_aresetn),
	// 			.s00_axis_tlast(Qout_tlast),
	// 			.s00_axis_tvalid(Qout_tvalid),
	// 			.s00_axis_tdata(Qout_tdata),
	// 			.s00_axis_tstrb(Qout_tstrb),
	// 			.s00_axis_tready(Qfilter_tready),
		
	// 			// Ports of Axi Master Bus Interface M00_AXIS
	// 			.m00_axis_aclk(m00_axis_aclk),
	// 			.m00_axis_aresetn(m00_axis_aresetn),
	// 			.m00_axis_tready(m00_axis_tready),
	// 			.m00_axis_tvalid(Qfilter_tvalid), 
	// 			.m00_axis_tlast(Qfilter_tlast),
	// 			.m00_axis_tdata(Qfilter_tdata),
	// 			.m00_axis_tstrb(Qfilter_tstrb)
	// 			);


endmodule


