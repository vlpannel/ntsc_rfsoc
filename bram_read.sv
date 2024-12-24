`timescale 1ns / 1ps

module bram_read # (
                    parameter NUM_PIXELS = 720 * 480,
                    parameter DATA_WIDTH = 32
                   )
    (
      
      // interface with BRAM
      input logic [DATA_WIDTH-1:0] bram_data,
      output logic bram_clk,
      output logic [$clog2(NUM_PIXELS)-1:0] read_addr,
      
      // to be fed to NTSC
      input logic m00_axis_aclk, m00_axis_aresetn,
      input logic m00_axis_tready,
      output logic m00_axis_tvalid,
      output logic m00_axis_tlast,
      output logic [(DATA_WIDTH/8)-1:0] m00_axis_tstrb,
      output logic [DATA_WIDTH-1:0] m00_axis_tdata,
      
      output logic [3:0] probe_out

    );
    
    logic [DATA_WIDTH-1:0] intmdt1, intmdt2;
    logic [$clog2(NUM_PIXELS)-1:0] output_addr1, output_addr2, addr_out;
    
    assign bram_clk = m00_axis_aclk;
    assign m00_axis_tstrb = 32'hFFFF;
    
    enum {IDLE, LOAD, TX} state;
    
    assign probe_out = {1'b0, state == TX, state == LOAD, state == IDLE}; // should be always off, 50% on, always on, rarely on
    
    always @(posedge m00_axis_aclk) begin
      if (~m00_axis_aresetn) begin
        state <= IDLE;
        
        read_addr <= 0;
        m00_axis_tvalid <= 0;
        m00_axis_tdata <= 0;
        m00_axis_tlast <= 0;
        
        intmdt1 <= 0;
        intmdt2 <= 0;
        
        output_addr1 <= -1;
        output_addr2 <= -1;
        addr_out <= -1;
      end else begin
        case (state)
          IDLE: begin
            state <= LOAD;
            
            read_addr <= 0;
            m00_axis_tvalid <= 0;
            m00_axis_tdata <= 0;
            m00_axis_tlast <= 0;
        
            intmdt1 <= 0;
            intmdt2 <= 0;
            
            output_addr1 <= -1;
            output_addr2 <= -1;
            addr_out <= -1;
          end
          LOAD: begin // assuming this stage is way faster than SYNC stages
            if (output_addr2 == 0) state <= TX;
            
            read_addr <= read_addr + 1;
            m00_axis_tvalid <= (output_addr2 == 0)? 1 : 0;
            m00_axis_tdata <= intmdt2;
            m00_axis_tlast <= 0;
            
            intmdt1 <= bram_data;
            intmdt2 <= intmdt1;
            
            output_addr1 <= read_addr;
            output_addr2 <= output_addr1;
            addr_out <= output_addr2;
          end
          TX: begin
            if (m00_axis_tready) begin
              if (addr_out >= NUM_PIXELS - 1) begin // sending last begin
                state <= IDLE;
                
                read_addr <= 0;
                m00_axis_tvalid <= 0;
                m00_axis_tdata <= 0;
                m00_axis_tlast <= 0;
                
                intmdt1 <= 0;
                intmdt2 <= 0;
                
                output_addr1 <= 0;
                output_addr2 <= 0;
                addr_out <= 0;
              end else begin // continually stream bits
                state <= TX;
                
                read_addr <= (read_addr < NUM_PIXELS - 1)? read_addr + 1 : 0;
                m00_axis_tvalid <= 1;
                m00_axis_tdata <= intmdt2;
                m00_axis_tlast <= (output_addr2 >= NUM_PIXELS - 1);
                
                intmdt1 <= bram_data;
                intmdt2 <= intmdt1;
                
                output_addr1 <= read_addr;
                output_addr2 <= output_addr1;
                addr_out <= output_addr2;
              end
            end
          end
        endcase
      end
    end
endmodule
