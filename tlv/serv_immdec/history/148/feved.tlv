\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
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
         // Pipesignal assignments
         m5_if_eq_block(m5_cond_w_1, 1, ['
         $signbit = *imm31 & ! *i_csr_imm_en;
         '], ['
         $signbit = *ii31 & ! *i_csr_imm_en;
         <<1$ii12 = *i_cnt_en ? $ii16 : *i_wb_en ? *i_wb_rdt[12] : $ii12;
         <<1$ii16 = *i_cnt_en ? (*i_ctrl[3] ? $signbit : *ii20_b2) : *i_wb_en ? *i_wb_rdt[16] : $ii16;
         <<1$ii24 = *i_cnt_en ? *ii28 : *i_wb_en ? *i_wb_rdt[24] : $ii24;
         '])
         
         
         \SV_plus

            // Clock alias for TL-Verilog
            wire clk = i_clk;

            m5_if_eq_block(m5_cond_w_1, 1, ['
               reg               imm31;
            
               reg [8:0]  imm_b19_b12_b20;
               reg        imm7;
               reg [5:0]  imm_b30_b25;
               reg [4:0]  imm_b24_b20;
               reg [4:0]  imm_b11_b7;
            
               assign o_csr_imm = imm_b19_b12_b20[4];

                  m5_if_eq_block(m5_cond_shared, 1, ['
                     assign o_rs1_addr = imm_b19_b12_b20[8:4];
                     assign o_rs2_addr = imm_b24_b20;
                     assign o_rd_addr  = imm_b11_b7;

                     always \@(posedge i_clk) begin
                        /* CSR immediates are always zero-extended, hence clear the signbit */
                        imm31     <= i_wb_en ? i_wb_rdt[31] : imm31;
                        imm_b19_b12_b20 <= i_wb_en ? {i_wb_rdt[19:12], i_wb_rdt[20]} :
                                          (i_cnt_en & i_immdec_en[1]) ? {i_ctrl[3] ? $signbit : imm_b24_b20[0], imm_b19_b12_b20[8:1]} :
                                          imm_b19_b12_b20;
                        imm7 <= i_wb_en ? i_wb_rdt[7] :
                               i_cnt_en ? $signbit :
                               imm7;
            
                        imm_b30_b25 <= i_wb_en ? i_wb_rdt[30:25] :
                                      (i_cnt_en & i_immdec_en[3]) ? {i_ctrl[2] ? imm7 : i_ctrl[1] ? $signbit : imm_b19_b12_b20[0], imm_b30_b25[5:1]} :
                                      imm_b30_b25;
            
                        imm_b24_b20 <= i_wb_en ? i_wb_rdt[24:20] :
                                      (i_cnt_en & i_immdec_en[2]) ? {imm_b30_b25[0], imm_b24_b20[4:1]} :
                                      imm_b24_b20;
            
                        imm_b11_b7 <= i_wb_en ? i_wb_rdt[11:7] :
                                     (i_cnt_en & i_immdec_en[0]) ? {imm_b30_b25[0], imm_b11_b7[4:1]} :
                                     imm_b11_b7;
                     end
                  '], ['
                     reg [4:0]  rd_addr;
                     reg [4:0]  rs1_addr;
                     reg [4:0]  rs2_addr;

                     assign o_rd_addr  = rd_addr;
                     assign o_rs1_addr = rs1_addr;
                     assign o_rs2_addr = rs2_addr;

                     always \@(posedge i_clk) begin
                        /* CSR immediates are always zero-extended, hence clear the signbit */
                        imm31       <= i_wb_en ? i_wb_rdt[31] : imm31;
                        {rs2_addr, rs1_addr, rd_addr} <= i_wb_en ? {i_wb_rdt[24:20], i_wb_rdt[19:15], i_wb_rdt[11:7]} : {rs2_addr, rs1_addr, rd_addr};
                        
                        imm7 <= i_cnt_en ? $signbit :
                                i_wb_en  ? i_wb_rdt[7] : 
                                           imm7;
                        
                        {imm_b24_b20, imm_b11_b7} <= i_cnt_en ? {{imm_b30_b25[0], imm_b24_b20[4:1]}, {imm_b30_b25[0], imm_b11_b7[4:1]}} :
                                                     i_wb_en  ? {i_wb_rdt[24:20], i_wb_rdt[11:7]} :
                                                                {imm_b24_b20, imm_b11_b7};
                        
                        imm_b30_b25 <= i_cnt_en ? {i_ctrl[2] ? imm7 : i_ctrl[1] ? $signbit : imm_b19_b12_b20[0], imm_b30_b25[5:1]} :
                                      i_wb_en  ? i_wb_rdt[30:25] :
                                                 imm_b30_b25;
                        
                        imm_b19_b12_b20 <= i_cnt_en ? {i_ctrl[3] ? $signbit : imm_b24_b20[0], imm_b19_b12_b20[8:1]} :
                                          i_wb_en  ? {i_wb_rdt[19:12],i_wb_rdt[20]} :
                                                     imm_b19_b12_b20;
                     end
                  '])

                  assign o_imm = i_cnt_done ? $signbit : i_ctrl[0] ? imm_b11_b7[0] : imm_b24_b20[0];
            '], ['
               reg [4:0]         rd_addr;
               reg [4:0]         rs1_addr;
               reg [4:0]         rs2_addr;

               reg               ii31;

               reg               ii30;
               reg               ii29;
               reg               ii28;

               reg               ii27;
               reg               ii26;
               reg               ii25;
               reg               ii23;
               reg               ii22;
               reg               ii21;
               reg               ii20;
               reg               ii19;
               reg               ii18;
               reg               ii17;
               reg               ii15;
               reg               ii14;
               reg               ii13;
               reg               ii11;
               reg               ii10;
               reg               ii9;
               reg               ii8;
               reg               ii7;

               reg               ii7_b2;
               reg               ii20_b2;

               assign o_csr_imm = {ii18, ii17, $ii16, ii15};
               assign o_rd_addr  = rd_addr;
               assign o_rs1_addr = rs1_addr;
               assign o_rs2_addr = rs2_addr;
               always \@(posedge i_clk) begin
                  //Common - Initialization signals
                  {ii31, rs2_addr, rs1_addr, rd_addr} <= i_wb_en ? {i_wb_rdt[31], i_wb_rdt[24:20], i_wb_rdt[19:15], i_wb_rdt[11:7]} : 
                                                                   {ii31, rs2_addr, rs1_addr, rd_addr};
                  
                  //Bit lane 3
                  ii7  <= i_cnt_en ? $signbit :
                         i_wb_en  ? i_wb_rdt[7] :
                                    ii7;
                  
                  {ii23, ii10} <= i_cnt_en ? {ii27, ii27} :
                                i_wb_en  ? {i_wb_rdt[23], i_wb_rdt[10]} :
                                           {ii23, ii10};
                  
                  ii27 <= i_cnt_en ? (i_ctrl[2] ? ii7 : i_ctrl[1] ? $signbit : ii20) :
                         i_wb_en  ? i_wb_rdt[27] :
                                    ii27;
                  
                  {ii20, ii15} <= i_cnt_en ? {ii15, ii19} :
                                i_wb_en  ? {i_wb_rdt[20], i_wb_rdt[15]} :
                                           {ii20, ii15};
                  
                  {ii19, ii18, ii17} <= i_cnt_en ? (i_ctrl[3] ? {$signbit, $signbit, $signbit} : {ii23, ii22, ii21}) :
                                     i_wb_en  ? {i_wb_rdt[19], i_wb_rdt[18], i_wb_rdt[17]} :
                                                {ii19, ii18, ii17};
            
                  //Bit lane 2
                  {ii22, ii9} <= i_cnt_en ? {ii26, ii26} :
                               i_wb_en  ? {i_wb_rdt[22], i_wb_rdt[9]} :
                                          {ii22, ii9};
                  
                  {ii26, ii14} <= i_cnt_en ? {ii30, ii18} :
                                i_wb_en  ? {i_wb_rdt[26], i_wb_rdt[14]} :
                                           {ii26, ii14};
                  
                  {ii30, ii29, ii28} <= i_cnt_en ? ((i_ctrl[1] | i_ctrl[2]) ? {$signbit, $signbit, $signbit} : {ii14, ii13, $ii12}) :
                                     i_wb_en  ? {i_wb_rdt[30], i_wb_rdt[29], i_wb_rdt[28]} :
                                                {ii30, ii29, ii28};
            
                  //Bit lane 1
                  {ii21, ii8} <= i_cnt_en ? {ii25, ii25} :
                               i_wb_en  ? {i_wb_rdt[21], i_wb_rdt[8]} :
                                          {ii21, ii8};
                  
                  {ii25, ii13} <= i_cnt_en ? {ii29, ii17} :
                                i_wb_en  ? {i_wb_rdt[25], i_wb_rdt[13]} :
                                           {ii25, ii13};
                  
                  //Bit lane 0
                  {ii20_b2, ii7_b2} <= i_cnt_en ? {$ii24, ii11} :
                                        i_wb_en  ? {i_wb_rdt[20], i_wb_rdt[7]} :
                                                   {ii20_b2, ii7_b2};
                  
                  ii11 <= i_cnt_en ? ii28 :
                         i_wb_en  ? i_wb_rdt[11] :
                                    ii11;
               end

               assign o_imm = {(i_cnt_done ? $signbit : (i_ctrl[0] ? ii10 : ii23)),
                               i_ctrl[0] ? ii9 : ii22,
                               i_ctrl[0] ? ii8 : ii21,
                               i_ctrl[0] ? ii7_b2 : ii20_b2};
            '])

\SV
endmodule
