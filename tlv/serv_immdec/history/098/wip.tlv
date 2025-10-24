\TLV_version 1d: tl-x.org
\SV
// SPDX-License-Identifier: ISC
`default_nettype none
module serv_immdec
  #(parameter SHARED_RFADDR_IMM_REGS = 1,
    parameter W = 1)
  (
      input wire              i_clk,
   //State
   input wire        i_cnt_en,
   input wire        i_cnt_done,
   //Control
   input wire [3:0]  i_immdec_en,
   input wire        i_csr_imm_en,
   input wire [3:0]  i_ctrl,
   output wire [4:0] o_rd_addr,
   output wire [4:0] o_rs1_addr,
   output wire [4:0] o_rs2_addr,
   //Data
   output wire [W-1:0] o_csr_imm,
   output wire [W-1:0] o_imm,
   //External
   input wire        i_wb_en,
   input wire [31:7] i_wb_rdt);
\TLV
   |default
      @0
         /gen_immdec_w_eq1[W == 1 ? 0 \: -1 : 0]
            /gen_shared_imm_regs[!SHARED_RFADDR_IMM_REGS ? 0 \: -1 : 0]
            /gen_separate_imm_regs[SHARED_RFADDR_IMM_REGS ? 0 \: -1 : 0]
         /gen_immdec_w_eq4[W != 1 ? 0 \: -1 : 0]
         \SV_plus

            // Clock alias for TL-Verilog
            wire clk = i_clk;

            generate
               // if (W == 1)
               genvar gen_w1;
               for (gen_w1 = (W != 1); gen_w1 < 1; gen_w1++) begin : gen_immdec_w_eq1
               reg               imm31;
            
               reg [8:0]  imm_b19_b12_b20;
               reg        imm7;
               reg [5:0]  imm_b30_b25;
               reg [4:0]  imm_b24_b20;
               reg [4:0]  imm_b11_b7;
            
               wire       signbit = imm31 & !i_csr_imm_en;
            
            
            
                  // if (SHARED_RFADDR_IMM_REGS)
                  genvar gen_shared;
                  for (gen_shared = !SHARED_RFADDR_IMM_REGS; gen_shared < 1; gen_shared++) begin : gen_shared_imm_regs
                     always \@(posedge i_clk) begin
                        /* CSR immediates are always zero-extended, hence clear the signbit */
                        imm31     <= i_wb_en ? i_wb_rdt[31] : imm31;
                        imm_b19_b12_b20 <= (i_wb_en | (i_cnt_en & i_immdec_en[1])) ? 
                                          (i_wb_en ? {i_wb_rdt[19:12],i_wb_rdt[20]} : {i_ctrl[3] ? signbit : imm_b24_b20[0], imm_b19_b12_b20[8:1]}) : 
                                          imm_b19_b12_b20;
                        imm7 <= (i_wb_en | i_cnt_en) ? 
                               (i_wb_en ? i_wb_rdt[7] : signbit) : 
                               imm7;
            
                        imm_b30_b25 <= (i_wb_en | (i_cnt_en & i_immdec_en[3])) ? 
                                      (i_wb_en ? i_wb_rdt[30:25] : {i_ctrl[2] ? imm7 : i_ctrl[1] ? signbit : imm_b19_b12_b20[0], imm_b30_b25[5:1]}) : 
                                      imm_b30_b25;
            
                        imm_b24_b20 <= (i_wb_en | (i_cnt_en & i_immdec_en[2])) ? 
                                      (i_wb_en ? i_wb_rdt[24:20] : {imm_b30_b25[0], imm_b24_b20[4:1]}) : 
                                      imm_b24_b20;
            
                        imm_b11_b7 <= (i_wb_en | (i_cnt_en & i_immdec_en[0])) ? 
                                     (i_wb_en ? i_wb_rdt[11:7] : {imm_b30_b25[0], imm_b11_b7[4:1]}) : 
                                     imm_b11_b7;
                     end
                  end
                  // if (!SHARED_RFADDR_IMM_REGS)
                  genvar gen_separate;
                  for (gen_separate = SHARED_RFADDR_IMM_REGS; gen_separate < 1; gen_separate++) begin : gen_separate_imm_regs
                     reg [4:0]  rd_addr;
                     reg [4:0]  rs1_addr;
                     reg [4:0]  rs2_addr;

                     always \@(posedge i_clk) begin
                        /* CSR immediates are always zero-extended, hence clear the signbit */
                        imm31       <= i_wb_en ? i_wb_rdt[31] : imm31;
                        rd_addr     <= i_wb_en ? i_wb_rdt[11:7] : rd_addr;
                        rs1_addr    <= i_wb_en ? i_wb_rdt[19:15] : rs1_addr;
                        rs2_addr    <= i_wb_en ? i_wb_rdt[24:20] : rs2_addr;
                        
                        imm7 <= i_cnt_en ? signbit :
                                i_wb_en  ? i_wb_rdt[7] : 
                                           imm7;
                        
                        imm_b11_b7 <= i_cnt_en ? {imm_b30_b25[0], imm_b11_b7[4:1]} :
                                     i_wb_en  ? i_wb_rdt[11:7] :
                                                imm_b11_b7;
                        
                        imm_b24_b20 <= i_cnt_en ? {imm_b30_b25[0], imm_b24_b20[4:1]} :
                                      i_wb_en  ? i_wb_rdt[24:20] :
                                                 imm_b24_b20;
                        
                        imm_b30_b25 <= i_cnt_en ? {i_ctrl[2] ? imm7 : i_ctrl[1] ? signbit : imm_b19_b12_b20[0], imm_b30_b25[5:1]} :
                                      i_wb_en  ? i_wb_rdt[30:25] :
                                                 imm_b30_b25;
                        
                        imm_b19_b12_b20 <= i_cnt_en ? {i_ctrl[3] ? signbit : imm_b24_b20[0], imm_b19_b12_b20[8:1]} :
                                          i_wb_en  ? {i_wb_rdt[19:12],i_wb_rdt[20]} :
                                                     imm_b19_b12_b20;
                     end
                  end
            
                  // Output assignments for address signals
                  // if (SHARED_RFADDR_IMM_REGS)
                  genvar gen_shared_addr;
                  for (gen_shared_addr = !SHARED_RFADDR_IMM_REGS; gen_shared_addr < 1; gen_shared_addr++) begin : gen_shared_addr_out
                     assign o_rs1_addr = imm_b19_b12_b20[8:4];
                     assign o_rs2_addr = imm_b24_b20;
                     assign o_rd_addr  = imm_b11_b7;
                  end
                  // if (!SHARED_RFADDR_IMM_REGS)
                  genvar gen_separate_addr;
                  for (gen_separate_addr = SHARED_RFADDR_IMM_REGS; gen_separate_addr < 1; gen_separate_addr++) begin : gen_separate_addr_out
                     assign o_rd_addr  = gen_separate_imm_regs[0].rd_addr;
                     assign o_rs1_addr = gen_separate_imm_regs[0].rs1_addr;
                     assign o_rs2_addr = gen_separate_imm_regs[0].rs2_addr;
                  end
            
            
               end
               // if (W != 1)
               genvar gen_w4;
               for (gen_w4 = (W == 1); gen_w4 < 1; gen_w4++) begin : gen_immdec_w_eq4
               reg [4:0]         rd_addr;
               reg [4:0]         rs1_addr;
               reg [4:0]         rs2_addr;

               reg               i31;

               reg               i30;
               reg               i29;
               reg               i28;

               reg               i27;
               reg               i26;
               reg               i25;
               reg               i24;
               reg               i23;
               reg               i22;
               reg               i21;
               reg               i20;
               reg               i19;
               reg               i18;
               reg               i17;
               reg               i16;
               reg               i15;
               reg               i14;
               reg               i13;
               reg               i12;
               reg               i11;
               reg               i10;
               reg               i9;
               reg               i8;
               reg               i7;

               reg               ii7_b2;
               reg               ii20_b2;

               wire              signbit = i31 & !i_csr_imm_en;

               assign o_rd_addr  = rd_addr;
               assign o_rs1_addr = rs1_addr;
               assign o_rs2_addr = rs2_addr;
               always \@(posedge i_clk) begin
                  //Common
                  i31 <= i_wb_en ? i_wb_rdt[31] : i31;
                  rs1_addr <= i_wb_en ? i_wb_rdt[19:15] : rs1_addr;
                  rs2_addr <= i_wb_en ? i_wb_rdt[24:20] : rs2_addr;
                  rd_addr <= i_wb_en ? i_wb_rdt[11:7] : rd_addr;
                  
                  //Bit lane 3
                  i7  <= i_cnt_en ? signbit :
                         i_wb_en  ? i_wb_rdt[7] :
                                    i7;
                  
                  i10 <= i_cnt_en ? i27 :
                         i_wb_en  ? i_wb_rdt[10] :
                                    i10;
                  
                  i23 <= i_cnt_en ? i27 :
                         i_wb_en  ? i_wb_rdt[23] :
                                    i23;
                  
                  if (i_wb_en) begin
                     i19 <= i_wb_rdt[19];
                     i15 <= i_wb_rdt[15];
                     i20 <= i_wb_rdt[20];
                     i27 <= i_wb_rdt[27];
            
                     //Bit lane 2
                     i9  <= i_wb_rdt[ 9];
                     i14 <= i_wb_rdt[14];
                     i22 <= i_wb_rdt[22];
                     i26 <= i_wb_rdt[26];
                     i30 <= i_wb_rdt[30];
                  end
                  
                  //More Bit lane 2 conversions
                  i9  <= i_cnt_en ? i26 :
                         i_wb_en  ? i_wb_rdt[9] :
                                    i9;
                  
                  i22 <= i_cnt_en ? i26 :
                         i_wb_en  ? i_wb_rdt[22] :
                                    i22;
                  
                  if (i_wb_en) begin
                     i18 <= i_wb_rdt[18];
            
                     //Bit lane 1
                     i21 <= i_wb_rdt[21];
                     i8  <= i_wb_rdt[ 8];
                     i25 <= i_wb_rdt[25];
                     i29 <= i_wb_rdt[29];
                     i13 <= i_wb_rdt[13];
                     i17 <= i_wb_rdt[17];
            
                     //Bit lane 0
                     i11 <= i_wb_rdt[11];
                     ii7_b2  <= i_wb_rdt[7 ];
                     ii20_b2   <= i_wb_rdt[20];
                     i24   <= i_wb_rdt[24];
                     i28   <= i_wb_rdt[28];
                     i12   <= i_wb_rdt[12];
                     i16   <= i_wb_rdt[16];
                     rd_addr <= i_wb_rdt[11:7];
                  end
                  if (i_cnt_en) begin
                     //Bit lane 3
                     i27 <= i_ctrl[2] ? i7 : i_ctrl[1] ? signbit : i20;
                     i20 <= i15;
                     i15 <= i19;
                     i19 <= i_ctrl[3] ? signbit : i23;
            
                     //Bit lane 2
                     i26 <= i30;
                     i30 <= (i_ctrl[1] | i_ctrl[2]) ? signbit : i14;
                     i14 <= i18;
                     i18 <= i_ctrl[3] ? signbit : i22;
            
                     //Bit lane 1
                     i21 <= i25;
                     i8  <= i25;
                     i25 <= i29;
                     i29 <= (i_ctrl[1] | i_ctrl[2]) ? signbit : i13;
                     i13 <= i17;
                     i17 <= i_ctrl[3] ? signbit : i21;
            
                     //Bit lane 0
                     ii7_b2  <= i11;
                     i11   <= i28;
                     ii20_b2   <= i24;
                     i24   <= i28;
                     i28 <= (i_ctrl[1] | i_ctrl[2]) ? signbit : i12;

                     i12   <= i16;
                     i16   <= i_ctrl[3] ? signbit : ii20_b2;
            
                  end
               end
            
            
            
               end
            endgenerate
            
            // Output assignments for CSR immediate and immediate outputs
            generate
               // if (W == 1)
               genvar gen_w1_csr;
               for (gen_w1_csr = (W != 1); gen_w1_csr < 1; gen_w1_csr++) begin : gen_w1_csr_imm_out
                  assign o_csr_imm = gen_immdec_w_eq1[0].imm_b19_b12_b20[4];
               end
               // if (W != 1)
               genvar gen_w4_csr;
               for (gen_w4_csr = (W == 1); gen_w4_csr < 1; gen_w4_csr++) begin : gen_w4_csr_imm_out
                  assign o_csr_imm = {gen_immdec_w_eq4[0].i18, gen_immdec_w_eq4[0].i17, gen_immdec_w_eq4[0].i16, gen_immdec_w_eq4[0].i15};
               end
            endgenerate
            
            generate
               // if (W == 1)
               genvar gen_w1_imm;
               for (gen_w1_imm = (W != 1); gen_w1_imm < 1; gen_w1_imm++) begin : gen_w1_imm_out
                  assign o_imm = i_cnt_done ? gen_immdec_w_eq1[0].signbit : i_ctrl[0] ? gen_immdec_w_eq1[0].imm_b11_b7[0] : gen_immdec_w_eq1[0].imm_b24_b20[0];
               end
               // if (W != 1)
               genvar gen_w4_imm;
               for (gen_w4_imm = (W == 1); gen_w4_imm < 1; gen_w4_imm++) begin : gen_w4_imm_out
                  assign o_imm = {(i_cnt_done ? gen_immdec_w_eq4[0].signbit : (i_ctrl[0] ? gen_immdec_w_eq4[0].i10 : gen_immdec_w_eq4[0].i23)),
                                  i_ctrl[0] ? gen_immdec_w_eq4[0].i9 : gen_immdec_w_eq4[0].i22,
                      i_ctrl[0] ? gen_immdec_w_eq4[0].i8 : gen_immdec_w_eq4[0].i21,
                      i_ctrl[0] ? gen_immdec_w_eq4[0].ii7_b2 : gen_immdec_w_eq4[0].ii20_b2};
   end
            endgenerate
\SV
endmodule
