`default_nettype none // prevents system from inferring an undeclared logic (good practice)
/*
INFO:
30fps
720x480p, 525 total vertical lines used for formatting 
248 lines
*/
module NTSC #
	(
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 16,
        parameter integer CLK_PERIOD = 4, //in ns
        parameter integer STEP_FREQ = 250_000_000
	)
	(
		// Ports of Axi Slave Bus Interface S00_AXIS
        //LUMA + CHROMA
		input wire  s00_axis_aclk, s00_axis_aresetn,
		input wire  s00_axis_tlast, s00_axis_tvalid,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1: 0] s00_axis_tstrb,
		output logic  s00_axis_tready,

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

    assign m00_axis_tstrb = 2'b11;
    assign m00_axis_tdata = video_out; //+ audio_out;

    //Test Probe
    int probe;
    assign probe = SYNC_PERIOD;

    ////SCREEN LIMITS//////
    localparam WIDTH = 20;//720;
    localparam FRAME_LIMIT = 2;//240; //Value will depend on the number for vertical sync signals
    localparam VERTICAL_LIMIT = 11;
    ///////////////////////

    ///TIMING/////
    localparam SYNC_PERIOD = int'(4700/CLK_PERIOD);
    localparam HALF_SYNC_PERIOD = int'(2350/CLK_PERIOD);
    localparam BEFORE_CB_PERIOD = int'(500/CLK_PERIOD);
    localparam COLOR_BURST_PERIOD = int'(2500/CLK_PERIOD);
    localparam AFTER_CB_PERIOD = int'(1700/CLK_PERIOD);
    localparam VISIBLE_PERIOD = int'(52600/CLK_PERIOD);
    localparam PIXEL_PERIOD = int'(VISIBLE_PERIOD/WIDTH); //Clock Cycles per priod
    localparam FRONT_PORCH_PERIOD = int'(1500/CLK_PERIOD);
    localparam TOTAL_PERIOD = int'(63500/CLK_PERIOD);
    localparam HALF_PERIOD = int'(31750/CLK_PERIOD);
    localparam AUDIO_PERIOD = int'(22675/CLK_PERIOD);
    //////////////

    ///STATES/////
    localparam HSYNC = 4'b0000;
    localparam COLOR_BURST = 4'b0001;
    localparam VISIBLE = 4'b0010;
    localparam FRONT = 4'b0011;
    localparam VSYNC = 4'b0100;
    localparam IDLE = 4'b0101;
    localparam EQUAL = 4'b0110;
    //////////////

    logic [31:0] video_out;
    logic [31:0] audio_out;
    logic [31:0] counter;
    logic [31:0] pixel_counter;
    logic [31:0] pixel;
    logic [31:0] audio_counter;
    logic [3:0] state;
    logic [31:0] vcount;
    logic signed [15:0] bp;
    logic signed [15:0] cb;
    logic parity;

    //Sine generator for Color Burst
    sine_generator #(.PHASE(180), .FREQUENCY(3_580_000), .STEP_FREQ(STEP_FREQ)) color_burst(
                    .clk_in(s00_axis_aclk), 
                    .rst_in(!s00_axis_aresetn),
                    .step_in(m00_axis_tready),  
                    .amp_out(cb)
                    ); 

    always_ff @(posedge s00_axis_aclk)begin
        if (s00_axis_aresetn == 0)begin
            vcount <= 0;
            state <= IDLE;
            counter <= 0;
            vcount <= 0;
            parity <= 0;
            pixel_counter <= 0;
            s00_axis_tready <= 0;
            pixel <= 0;
            audio_out <= 0;
            video_out <= 0;
        end else if (m00_axis_tready) begin

            //AUDIO STUFF
            case(state)
                IDLE: begin
                    s01_axis_tready <= 1;
                    audio_out <= 0;
                end

                default: begin
                    audio_out <= (s01_axis_tdata + 16'd32768) >> 2;
                    if (audio_counter < AUDIO_PERIOD - 1) begin
                        audio_counter <= audio_counter + 1;
                        s01_axis_tready <= 0;
                    end else begin
                        audio_counter <= 0;
                        s01_axis_tready <= 1;
                    end
                end
            endcase

            //VIDEO STUFF.
            //Total Time 63.5us
            case(state)
                IDLE: begin //Await a valid data stream, signaling the start of a frame
                    m00_axis_tvalid <= 0;
                    s00_axis_tready <= 1;
                    if (s00_axis_tvalid) begin
                        state <= EQUAL;
                        s00_axis_tready <= 0;
                        parity <= ~parity;
                        vcount <= 0;
                        counter <= 0;
                    end
                end

                HSYNC: begin //During HSYNC, pull signal low, no output for 4.7us
                    m00_axis_tlast <= 0; 
                    video_out <= 0; //Set output to 0.
                    m00_axis_tvalid <= 1; //All values should be valid
                    counter <= counter + 1; //Increment Timer
                    if (counter == SYNC_PERIOD - 1) begin //After 4.7us synce, moves to blanking period
                        counter <= 0; //Reset timer
                        state <= COLOR_BURST;
                        video_out <= 8'd77;//15'd9362; //Luma Depth is 12 bits, blanking level is 0.2857*2^12
                    end
                end

                COLOR_BURST: begin //Back Porch incldues Blanking Level + Color Burst
                    m00_axis_tvalid <= 1;
                    counter <= counter + 1;
                    if (counter < BEFORE_CB_PERIOD - 1) begin //Sets the blanking level to 0.2857*2^12 for ~500ns
                        video_out <= 8'd77;//15'd9362;
                    end else if (counter < BEFORE_CB_PERIOD + COLOR_BURST_PERIOD - 1) begin //Color Burst for 2.5us
                        ///COLOR BURST HERE. Color burst is 180deg, I = (U*cos(180)+V*sin(180)), set U = ~0.2, burst is 0.4Vpp
                        video_out <= 8'd77;// + $signed(cb >>> 1);//15'd9362;// + $signed(cb >>> 2); //COLOR BURST @ 0.2857 DC
                    end else if (counter < BEFORE_CB_PERIOD + COLOR_BURST_PERIOD + AFTER_CB_PERIOD - 1) begin //Sets blanking level after CB for 1.7us
                        video_out <= 8'd77;//15'd9362;
                    end else begin
                        counter <= 0;
                        state <= VISIBLE; 
                        s00_axis_tready <= 1; //Load the pixel L, I, Q combined value to the input.
                        pixel <= 0; //Reset Pixel Count
                    end
                end

                VISIBLE: begin
                    m00_axis_tvalid <= 1;
                    video_out <= s00_axis_tdata; //Set the output to be the pixel value.
                    counter <= counter + 1; // increment the counter ever cycle
                    if (counter < VISIBLE_PERIOD - 1) begin //Visible period lasts for 52.6us
                        if (pixel < WIDTH - 1) begin //Keep track of # of pixels, if the number of pixels reaches 720, stop flow.
                            if (pixel_counter < PIXEL_PERIOD - 1) begin //Keeps track of how long pixels are output for. 
                                s00_axis_tready <= 0;
                                pixel_counter <= pixel_counter + 1;
                            end else begin 
                                s00_axis_tready <= 1;
                                pixel <= pixel + 1; //Increase pixel count
                                pixel_counter <= 0;
                            end
                        end else begin
                            s00_axis_tready <= 0; //Stops new data coming in
                            video_out <= 8'd77;//15'd11108; //Produces black when end of row.
                        end
                    end else begin //Change state to FRONT
                        video_out <= 8'd77;//15'd9362; 
                        pixel <= 0;
                        s00_axis_tready <= 0;
                        pixel_counter <= 0;
                        counter <= 0;
                        state <= FRONT;
                    end
                end

                FRONT: begin //Transmit a blanking level for 1.5us
                    video_out <= 8'd77;//15'd9362;
                    counter <= counter + 1;
                    m00_axis_tvalid <= 1;
                    if (counter == FRONT_PORCH_PERIOD - 1) begin //Holds the output at blanking level for 1.5us
                        counter <= 0;
                        vcount <= (vcount < FRAME_LIMIT - 1) ? vcount + 1: 0; //Increment the row count
                        state <= (vcount < FRAME_LIMIT - 1) ? HSYNC : EQUAL; //If end of frame, do a vertical sync for 22/23 rows.
                        m00_axis_tlast <= 1;
                    end
                end
                
                EQUAL: begin
                    video_out <= 0;
                    counter <= counter + 1;
                    m00_axis_tvalid <= 1;
                    m00_axis_tlast <= 0;
                    s00_axis_tready <= 0;
                    if (counter < HALF_SYNC_PERIOD - 1) begin
                        video_out <= (3 <= vcount && vcount < 6)? 8'd77: 0;//15'd9362;
                    end else if (counter < HALF_PERIOD - 1) begin
                        video_out <= (3 <= vcount && vcount < 6)? 0: 8'd77;
                    end else if (counter < HALF_SYNC_PERIOD + HALF_PERIOD - 1) begin
                        video_out <= (3 <= vcount && vcount < 6)? 8'd77: 0;//15'd9362;
                    end else if (counter < TOTAL_PERIOD - 1) begin
                        video_out <= (3 <= vcount && vcount < 6)? 0: 8'd77;
                    end else begin
                        counter <= 0;
                        video_out <= (3 <= vcount && vcount < 6)? 0: 8'd77;
                        vcount <= vcount + 1;
                        state <= (vcount < 9)? EQUAL: VSYNC; 
                    end
                end
                

                VSYNC: begin //Vertical syncing for 23 (odd)/22 (even) rows.
                    video_out <= 0;
                    counter <= counter + 1;
                    m00_axis_tvalid <= 1;
                    m00_axis_tlast <= 0;
                    s00_axis_tready <= 0;
                    if (counter < SYNC_PERIOD - 1) begin
                        video_out <= 8'd77;//15'd9362;
                    end else if (counter < TOTAL_PERIOD - 1) begin
                        video_out <= 0;
                    end else begin //End of Horizontal Line
                        counter <= 0;
                        if (vcount < VERTICAL_LIMIT - 1) begin //If not at the end, keep print blank lines
                            vcount <= vcount + 1;
                            m00_axis_tlast <= 1;
                            video_out <= 8'd77;//15'd9362;
                        end else begin //If at end, swap parity and restart from beginning
                            vcount <= 0;
                            parity <= ~parity;
                            state <= HSYNC;
                        end 
                    end
                end
            endcase
        end 
    end

endmodule

`default_nettype wire
