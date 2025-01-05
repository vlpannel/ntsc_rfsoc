module yfilter #
  (
    parameter integer C_S00_AXIS_TDATA_WIDTH  = 32,
    parameter integer C_M00_AXIS_TDATA_WIDTH  = 32,
    parameter integer NUM_COEFFS = 15
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

  logic rst = (~s00_axis_aresetn) | (~m00_axis_aresetn);
  logic new_intake = (s00_axis_tready & s00_axis_tvalid);
  logic last_vals = ((last_ix > 0) & m00_axis_tready);

  //initializing values                                   
  initial begin
    coeffs[0] = 0;
    coeffs[1] = 0;
    coeffs[2] = 0;
    coeffs[3] = 0;
    coeffs[4] = 0;
    coeffs[5] = 0;
    coeffs[6] = 0;
    coeffs[7] = 0;
    coeffs[8] = 0;
    coeffs[9] = 0;
    coeffs[10] = 0;
    coeffs[11] = 0;
    coeffs[12] = 0;
    coeffs[13] = 0;
    coeffs[14] = 0;
    coeffs[15] = 0;
    coeffs[16] = 0;
    coeffs[17] = 0;
    coeffs[18] = 0;
    coeffs[19] = 0;
    coeffs[20] = 0;
    coeffs[21] = 0;
    coeffs[22] = -1;
    coeffs[23] = -1;
    coeffs[24] = -1;
    coeffs[25] = -1;
    coeffs[26] = -1;
    coeffs[27] = -1;
    coeffs[28] = -1;
    coeffs[29] = -1;
    coeffs[30] = -1;
    coeffs[31] = -1;
    coeffs[32] = 0;
    coeffs[33] = 0;
    coeffs[34] = 0;
    coeffs[35] = 0;
    coeffs[36] = 0;
    coeffs[37] = 0;
    coeffs[38] = 0;
    coeffs[39] = 0;
    coeffs[40] = 0;
    coeffs[41] = 0;
    coeffs[42] = 0;
    coeffs[43] = 0;
    coeffs[44] = 0;
    coeffs[45] = 0;
    coeffs[46] = 0;
    coeffs[47] = 0;
    coeffs[48] = 0;
    coeffs[49] = 0;
    coeffs[50] = 0;
    coeffs[51] = 0;
    coeffs[52] = 0;
    coeffs[53] = 0;
    coeffs[54] = 0;
    coeffs[55] = 0;
    coeffs[56] = 0;
    coeffs[57] = 0;
    coeffs[58] = 0;
    coeffs[59] = 0;
    coeffs[60] = 0;
    coeffs[61] = 0;
    coeffs[62] = 0;
    coeffs[63] = 0;
    coeffs[64] = 0;
    coeffs[65] = 0;
    coeffs[66] = 0;
    coeffs[67] = 0;
    coeffs[68] = 0;
    coeffs[69] = 0;
    coeffs[70] = 0;
    coeffs[71] = 0;
    coeffs[72] = 0;
    coeffs[73] = 0;
    coeffs[74] = 0;
    coeffs[75] = 0;
    coeffs[76] = 0;
    coeffs[77] = 0;
    coeffs[78] = 0;
    coeffs[79] = 0;
    coeffs[80] = 0;
    coeffs[81] = 0;
    coeffs[82] = 0;
    coeffs[83] = 0;
    coeffs[84] = 0;
    coeffs[85] = 0;
    coeffs[86] = 0;
    coeffs[87] = 0;
    coeffs[88] = 0;
    coeffs[89] = 0;
    coeffs[90] = 0;
    coeffs[91] = 0;
    coeffs[92] = 0;
    coeffs[93] = 0;
    coeffs[94] = 0;
    coeffs[95] = 0;
    coeffs[96] = 0;
    coeffs[97] = 0;
    coeffs[98] = 0;
    coeffs[99] = 0;
    coeffs[100] = 0;
    coeffs[101] = 0;
    coeffs[102] = 0;
    coeffs[103] = 0;
    coeffs[104] = 0;
    coeffs[105] = 0;
    coeffs[106] = 0;
    coeffs[107] = 0;
    coeffs[108] = 0;
    coeffs[109] = 0;
    coeffs[110] = 0;
    coeffs[111] = 0;
    coeffs[112] = 0;
    coeffs[113] = 0;
    coeffs[114] = 0;
    coeffs[115] = 0;
    coeffs[116] = 0;
    coeffs[117] = 0;
    coeffs[118] = 0;
    coeffs[119] = 0;
    coeffs[120] = 0;
    coeffs[121] = 0;
    coeffs[122] = 0;
    coeffs[123] = 0;
    coeffs[124] = 0;
    coeffs[125] = 0;
    coeffs[126] = 0;
    coeffs[127] = 0;
    coeffs[128] = 0;
    coeffs[129] = 0;
    coeffs[130] = 0;
    coeffs[131] = 0;
    coeffs[132] = 0;
    coeffs[133] = 0;
    coeffs[134] = 0;
    coeffs[135] = 0;
    coeffs[136] = 0;
    coeffs[137] = 0;
    coeffs[138] = 0;
    coeffs[139] = 0;
    coeffs[140] = 0;
    coeffs[141] = 0;
    coeffs[142] = 0;
    coeffs[143] = 0;
    coeffs[144] = 0;
    coeffs[145] = 0;
    coeffs[146] = 0;
    coeffs[147] = 0;
    coeffs[148] = 0;
    coeffs[149] = 0;
    coeffs[150] = 0;
    coeffs[151] = 0;
    coeffs[152] = 0;
    coeffs[153] = 0;
    coeffs[154] = 0;
    coeffs[155] = 0;
    coeffs[156] = 0;
    coeffs[157] = 0;
    coeffs[158] = 0;
    coeffs[159] = 0;
    coeffs[160] = 0;
    coeffs[161] = 0;
    coeffs[162] = 0;
    coeffs[163] = 0;
    coeffs[164] = 0;
    coeffs[165] = 0;
    coeffs[166] = 0;
    coeffs[167] = 0;
    coeffs[168] = 0;
    coeffs[169] = 0;
    coeffs[170] = 0;
    coeffs[171] = 0;
    coeffs[172] = 0;
    coeffs[173] = 0;
    coeffs[174] = -1;
    coeffs[175] = -1;
    coeffs[176] = -1;
    coeffs[177] = -1;
    coeffs[178] = -1;
    coeffs[179] = -1;
    coeffs[180] = -1;
    coeffs[181] = 0;
    coeffs[182] = 0;
    coeffs[183] = 0;
    coeffs[184] = 0;
    coeffs[185] = 0;
    coeffs[186] = 0;
    coeffs[187] = 0;
    coeffs[188] = 0;
    coeffs[189] = 0;
    coeffs[190] = 1;
    coeffs[191] = 1;
    coeffs[192] = 1;
    coeffs[193] = 1;
    coeffs[194] = 1;
    coeffs[195] = 1;
    coeffs[196] = 1;
    coeffs[197] = 1;
    coeffs[198] = 1;
    coeffs[199] = 1;
    coeffs[200] = 1;
    coeffs[201] = 0;
    coeffs[202] = 0;
    coeffs[203] = 0;
    coeffs[204] = 0;
    coeffs[205] = 0;
    coeffs[206] = 0;
    coeffs[207] = -1;
    coeffs[208] = -1;
    coeffs[209] = -1;
    coeffs[210] = -1;
    coeffs[211] = -1;
    coeffs[212] = -1;
    coeffs[213] = -1;
    coeffs[214] = -2;
    coeffs[215] = -2;
    coeffs[216] = -1;
    coeffs[217] = -1;
    coeffs[218] = -1;
    coeffs[219] = -1;
    coeffs[220] = -1;
    coeffs[221] = 0;
    coeffs[222] = 0;
    coeffs[223] = 0;
    coeffs[224] = 1;
    coeffs[225] = 1;
    coeffs[226] = 2;
    coeffs[227] = 2;
    coeffs[228] = 3;
    coeffs[229] = 3;
    coeffs[230] = 4;
    coeffs[231] = 5;
    coeffs[232] = 5;
    coeffs[233] = 5;
    coeffs[234] = 6;
    coeffs[235] = 6;
    coeffs[236] = 6;
    coeffs[237] = 7;
    coeffs[238] = 7;
    coeffs[239] = 7;
    coeffs[240] = 7;
    coeffs[241] = 7;
    coeffs[242] = 7;
    coeffs[243] = 7;
    coeffs[244] = 6;
    coeffs[245] = 6;
    coeffs[246] = 6;
    coeffs[247] = 5;
    coeffs[248] = 5;
    coeffs[249] = 5;
    coeffs[250] = 4;
    coeffs[251] = 3;
    coeffs[252] = 3;
    coeffs[253] = 2;
    coeffs[254] = 2;
    coeffs[255] = 1;
    coeffs[256] = 1;
    coeffs[257] = 0;
    coeffs[258] = 0;
    coeffs[259] = 0;
    coeffs[260] = -1;
    coeffs[261] = -1;
    coeffs[262] = -1;
    coeffs[263] = -1;
    coeffs[264] = -1;
    coeffs[265] = -2;
    coeffs[266] = -2;
    coeffs[267] = -1;
    coeffs[268] = -1;
    coeffs[269] = -1;
    coeffs[270] = -1;
    coeffs[271] = -1;
    coeffs[272] = -1;
    coeffs[273] = -1;
    coeffs[274] = 0;
    coeffs[275] = 0;
    coeffs[276] = 0;
    coeffs[277] = 0;
    coeffs[278] = 0;
    coeffs[279] = 0;
    coeffs[280] = 1;
    coeffs[281] = 1;
    coeffs[282] = 1;
    coeffs[283] = 1;
    coeffs[284] = 1;
    coeffs[285] = 1;
    coeffs[286] = 1;
    coeffs[287] = 1;
    coeffs[288] = 1;
    coeffs[289] = 1;
    coeffs[290] = 1;
    coeffs[291] = 0;
    coeffs[292] = 0;
    coeffs[293] = 0;
    coeffs[294] = 0;
    coeffs[295] = 0;
    coeffs[296] = 0;
    coeffs[297] = 0;
    coeffs[298] = 0;
    coeffs[299] = 0;
    coeffs[300] = -1;
    coeffs[301] = -1;
    coeffs[302] = -1;
    coeffs[303] = -1;
    coeffs[304] = -1;
    coeffs[305] = -1;
    coeffs[306] = -1;
    coeffs[307] = 0;
    coeffs[308] = 0;
    coeffs[309] = 0;
    coeffs[310] = 0;
    coeffs[311] = 0;
    coeffs[312] = 0;
    coeffs[313] = 0;
    coeffs[314] = 0;
    coeffs[315] = 0;
    coeffs[316] = 0;
    coeffs[317] = 0;
    coeffs[318] = 0;
    coeffs[319] = 0;
    coeffs[320] = 0;
    coeffs[321] = 0;
    coeffs[322] = 0;
    coeffs[323] = 0;
    coeffs[324] = 0;
    coeffs[325] = 0;
    coeffs[326] = 0;
    coeffs[327] = 0;
    coeffs[328] = 0;
    coeffs[329] = 0;
    coeffs[330] = 0;
    coeffs[331] = 0;
    coeffs[332] = 0;
    coeffs[333] = 0;
    coeffs[334] = 0;
    coeffs[335] = 0;
    coeffs[336] = 0;
    coeffs[337] = 0;
    coeffs[338] = 0;
    coeffs[339] = 0;
    coeffs[340] = 0;
    coeffs[341] = 0;
    coeffs[342] = 0;
    coeffs[343] = 0;
    coeffs[344] = 0;
    coeffs[345] = 0;
    coeffs[346] = 0;
    coeffs[347] = 0;
    coeffs[348] = 0;
    coeffs[349] = 0;
    coeffs[350] = 0;
    coeffs[351] = 0;
    coeffs[352] = 0;
    coeffs[353] = 0;
    coeffs[354] = 0;
    coeffs[355] = 0;
    coeffs[356] = 0;
    coeffs[357] = 0;
    coeffs[358] = 0;
    coeffs[359] = 0;
    coeffs[360] = 0;
    coeffs[361] = 0;
    coeffs[362] = 0;
    coeffs[363] = 0;
    coeffs[364] = 0;
    coeffs[365] = 0;
    coeffs[366] = 0;
    coeffs[367] = 0;
    coeffs[368] = 0;
    coeffs[369] = 0;
    coeffs[370] = 0;
    coeffs[371] = 0;
    coeffs[372] = 0;
    coeffs[373] = 0;
    coeffs[374] = 0;
    coeffs[375] = 0;
    coeffs[376] = 0;
    coeffs[377] = 0;
    coeffs[378] = 0;
    coeffs[379] = 0;
    coeffs[380] = 0;
    coeffs[381] = 0;
    coeffs[382] = 0;
    coeffs[383] = 0;
    coeffs[384] = 0;
    coeffs[385] = 0;
    coeffs[386] = 0;
    coeffs[387] = 0;
    coeffs[388] = 0;
    coeffs[389] = 0;
    coeffs[390] = 0;
    coeffs[391] = 0;
    coeffs[392] = 0;
    coeffs[393] = 0;
    coeffs[394] = 0;
    coeffs[395] = 0;
    coeffs[396] = 0;
    coeffs[397] = 0;
    coeffs[398] = 0;
    coeffs[399] = 0;
    coeffs[400] = 0;
    coeffs[401] = 0;
    coeffs[402] = 0;
    coeffs[403] = 0;
    coeffs[404] = 0;
    coeffs[405] = 0;
    coeffs[406] = 0;
    coeffs[407] = 0;
    coeffs[408] = 0;
    coeffs[409] = 0;
    coeffs[410] = 0;
    coeffs[411] = 0;
    coeffs[412] = 0;
    coeffs[413] = 0;
    coeffs[414] = 0;
    coeffs[415] = 0;
    coeffs[416] = 0;
    coeffs[417] = 0;
    coeffs[418] = 0;
    coeffs[419] = 0;
    coeffs[420] = 0;
    coeffs[421] = 0;
    coeffs[422] = 0;
    coeffs[423] = 0;
    coeffs[424] = 0;
    coeffs[425] = 0;
    coeffs[426] = 0;
    coeffs[427] = 0;
    coeffs[428] = 0;
    coeffs[429] = 0;
    coeffs[430] = 0;
    coeffs[431] = 0;
    coeffs[432] = 0;
    coeffs[433] = 0;
    coeffs[434] = 0;
    coeffs[435] = 0;
    coeffs[436] = 0;
    coeffs[437] = 0;
    coeffs[438] = 0;
    coeffs[439] = 0;
    coeffs[440] = 0;
    coeffs[441] = 0;
    coeffs[442] = 0;
    coeffs[443] = 0;
    coeffs[444] = 0;
    coeffs[445] = 0;
    coeffs[446] = 0;
    coeffs[447] = 0;
    coeffs[448] = 0;
    coeffs[449] = -1;
    coeffs[450] = -1;
    coeffs[451] = -1;
    coeffs[452] = -1;
    coeffs[453] = -1;
    coeffs[454] = -1;
    coeffs[455] = -1;
    coeffs[456] = -1;
    coeffs[457] = -1;
    coeffs[458] = -1;
    coeffs[459] = 0;
    coeffs[460] = 0;
    coeffs[461] = 0;
    coeffs[462] = 0;
    coeffs[463] = 0;
    coeffs[464] = 0;
    coeffs[465] = 0;
    coeffs[466] = 0;
    coeffs[467] = 0;
    coeffs[468] = 0;
    coeffs[469] = 0;
    coeffs[470] = 0;
    coeffs[471] = 0;
    coeffs[472] = 0;
    coeffs[473] = 0;
    coeffs[474] = 0;
    coeffs[475] = 0;
    coeffs[476] = 0;
    coeffs[477] = 0;
    coeffs[478] = 0;
    coeffs[479] = 0;
    coeffs[480] = 0;

    for(int i=0; i<NUM_COEFFS; i++)begin
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
