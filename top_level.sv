`default_nettype none // prevents system from inferring an undeclared logic (good practice)
/*

*/
module top_level #
	(
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
        parameter integer CLK_PERIOD = 5.3, //in ns
        parameter integer STEP_FREQ = 188_000_000
	)
	(
		// Ports of Axi Slave Bus Interface S00_AXIS
        //LUMA + CHROMA
		input wire  s00_axis_aclk, s00_axis_aresetn,
		input wire  s00_axis_tlast, s00_axis_tvalid,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1: 0] s00_axis_tstrb,
		output logic  s00_axis_tready,

        //AUDIO
        input wire  s01_axis_aclk, s01_axis_aresetn,
		input wire  s01_axis_tlast, s01_axis_tvalid,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s01_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1: 0] s01_axis_tstrb,
		output logic  s01_axis_tready,
 
		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk, m00_axis_aresetn,
		input wire  m00_axis_tready,
		output logic  m00_axis_tvalid, m00_axis_tlast,
		output logic [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] m00_axis_tstrb
	);

	logic LUV_tready, LUV_tvalid, LUV_tlast;
	logic [31 : 0] LUV_tdata;
	logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] LUV_tstrb;

    logic CMOD_tready, CMOD_tvalid, CMOD_tlast;
	logic [31 : 0] CMOD_tdata;
	logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] CMOD_tstrb;

    LUV_mod #(.STEP_FREQ(STEP_FREQ), .SUBCARRIER(3_580_000)) luv(
        .s00_axis_aclk(s00_axis_aclk),
        .s00_axis_aresetn(s00_axis_aresetn),
        .s00_axis_tlast(s00_axis_tlast),
        .s00_axis_tvalid(s00_axis_tvalid),
        .s00_axis_tdata(s00_axis_tdata),
        .s00_axis_tstrb(s00_axis_tstrb),
        .s00_axis_tready(s00_axis_tready), 

        .m00_axis_aclk(s00_axis_aclk),
        .m00_axis_aresetn(s00_axis_aresetn),
        .m00_axis_tlast(LUV_tlast),
        .m00_axis_tvalid(LUV_tvalid),
        .m00_axis_tdata(LUV_tdata),
        .m00_axis_tstrb(LUV_tstrb),
        .m00_axis_tready(LUV_tready)      
    );

    NTSC #(.CLK_PERIOD(CLK_PERIOD), .STEP_FREQ(STEP_FREQ)) ntsc(
        .s00_axis_aclk(s00_axis_aclk),
        .s00_axis_aresetn(s00_axis_aresetn),
        .s00_axis_tlast(LUV_tlast),
        .s00_axis_tvalid(LUV_tvalid),
        .s00_axis_tdata(LUV_tdata),
        .s00_axis_tstrb(LUV_tstrb),
        .s00_axis_tready(LUV_tready),

        .s01_axis_aclk(s00_axis_aclk),
        .s01_axis_aresetn(s00_axis_aresetn),
        .s01_axis_tlast(FM_tlast),
        .s01_axis_tvalid(FM_tvalid),
        .s01_axis_tdata(FM_tdata),
        .s01_axis_tstrb(FM_tstrb),
        .s01_axis_tready(FM_tready),

        .m00_axis_aclk(s00_axis_aclk),
        .m00_axis_aresetn(s00_axis_aresetn),
        .m00_axis_tlast(m00_axis_tlast),
        .m00_axis_tvalid(m00_axis_tvalid),
        .m00_axis_tdata(m00_axis_tdata),
        .m00_axis_tstrb(m00_axis_tstrb),
        .m00_axis_tready(m00_axis_tready)
    );

    logic FM_tready, FM_tvalid, FM_tlast;
    logic [C_M00_AXIS_TDATA_WIDTH-1 : 0] FM_tdata;
    logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] FM_tstrb;

    FM_mod #(.CARRIER_FREQ(4_500_000), .FREQ_DEV(25000), .STEP_FREQ(STEP_FREQ)) FM_audio(
        .s00_axis_aclk(s00_axis_aclk),
        .s00_axis_aresetn(s00_axis_aresetn),
        .s00_axis_tlast(s01_axis_tlast),
        .s00_axis_tvalid(s01_axis_tvalid),
        .s00_axis_tdata(s01_axis_tdata),
        .s00_axis_tready(s01_axis_tready),
        .s00_axis_tstrb(s01_axis_tstrb),

        .m00_axis_aclk(s00_axis_aclk),
        .m00_axis_aresetn(s00_axis_aresetn),
        .m00_axis_tready(FM_tready),
        .m00_axis_tlast(FM_tlast),
        .m00_axis_tvalid(FM_tvalid),
        .m00_axis_tdata(FM_tdata),
        .m00_axis_tstrb(FM_tstrb)
    );

    

endmodule


`default_nettype wire