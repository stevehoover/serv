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
         <<1$imm31 = *i_wb_en ? *i_wb_rdt[31] : $imm31;
         $signbit = $imm31 & ! *i_csr_imm_en;
         '], ['
         $signbit = $ii31 & ! *i_csr_imm_en;
         
         // Common - Initialization signals  
         {<<1$ii31, <<1$rs2_addr[4:0], <<1$rs1_addr[4:0], <<1$rd_addr[4:0]} = *i_wb_en ? {*i_wb_rdt[31], *i_wb_rdt[24:20], *i_wb_rdt[19:15], *i_wb_rdt[11:7]} : 
                                                                                            {$ii31, $rs2_addr, $rs1_addr, $rd_addr};
         
         // Bit lane 3
         <<1$ii7 = *i_cnt_en ? $signbit :
                    *i_wb_en ? *i_wb_rdt[7] :
                               $ii7;
         
         {<<1$ii23, <<1$ii10} = *i_cnt_en ? {$ii27, $ii27} :
                                 *i_wb_en ? {*i_wb_rdt[23], *i_wb_rdt[10]} :
                                            {$ii23, $ii10};
         
         <<1$ii27 = *i_cnt_en ? (*i_ctrl[2] ? $ii7 : *i_ctrl[1] ? $signbit : $ii20) :
                     *i_wb_en ? *i_wb_rdt[27] :
                                $ii27;
         
         {<<1$ii20, <<1$ii15} = *i_cnt_en ? {$ii15, $ii19} :
                                 *i_wb_en ? {*i_wb_rdt[20], *i_wb_rdt[15]} :
                                            {$ii20, $ii15};
         
         {<<1$ii19, <<1$ii18, <<1$ii17} = *i_cnt_en ? (*i_ctrl[3] ? {$signbit, $signbit, $signbit} : {$ii23, $ii22, $ii21}) :
                                           *i_wb_en ? {*i_wb_rdt[19], *i_wb_rdt[18], *i_wb_rdt[17]} :
                                                      {$ii19, $ii18, $ii17};
         
         // Bit lane 2
         {<<1$ii22, <<1$ii9} = *i_cnt_en ? {$ii26, $ii26} :
                                *i_wb_en ? {*i_wb_rdt[22], *i_wb_rdt[9]} :
                                           {$ii22, $ii9};
         
         {<<1$ii26, <<1$ii14} = *i_cnt_en ? {$ii30, $ii18} :
                                 *i_wb_en ? {*i_wb_rdt[26], *i_wb_rdt[14]} :
                                            {$ii26, $ii14};
         
         {<<1$ii30, <<1$ii29, <<1$ii28} = *i_cnt_en ? ((*i_ctrl[1] | *i_ctrl[2]) ? {$signbit, $signbit, $signbit} : {$ii14, $ii13, $ii12}) :
                                           *i_wb_en ? {*i_wb_rdt[30], *i_wb_rdt[29], *i_wb_rdt[28]} :
                                                      {$ii30, $ii29, $ii28};
         
         // Bit lane 1
         {<<1$ii21, <<1$ii8} = *i_cnt_en ? {$ii25, $ii25} :
                                *i_wb_en ? {*i_wb_rdt[21], *i_wb_rdt[8]} :
                                           {$ii21, $ii8};
         
         {<<1$ii25, <<1$ii13} = *i_cnt_en ? {$ii29, $ii17} :
                                 *i_wb_en ? {*i_wb_rdt[25], *i_wb_rdt[13]} :
                                            {$ii25, $ii13};
         
         // Bit lane 0
         {<<1$ii20_b2, <<1$ii7_b2} = *i_cnt_en ? {$ii24, $ii11} :
                                      *i_wb_en ? {*i_wb_rdt[20], *i_wb_rdt[7]} :
                                                 {$ii20_b2, $ii7_b2};
         
         {<<1$ii24, <<1$ii11} = *i_cnt_en ? {$ii28, $ii28} :
                                 *i_wb_en ? {*i_wb_rdt[24], *i_wb_rdt[11]} :
                                            {$ii24, $ii11};
         
         <<1$ii12 = *i_cnt_en ? $ii16 : *i_wb_en ? *i_wb_rdt[12] : $ii12;
         <<1$ii16 = *i_cnt_en ? (*i_ctrl[3] ? $signbit : $ii20_b2) : *i_wb_en ? *i_wb_rdt[16] : $ii16;
         '])
         
         // M5 conditional pipesignal assignments for W=1
         m5_if_eq_block(m5_cond_w_1, 1, ['
         
         // Assignments for SHARED=1 case
         m5_if_eq_block(m5_cond_shared, 1, ['
         <<1$imm_b19_b12_b20[8:0] = *i_wb_en ? {*i_wb_rdt[19:12], *i_wb_rdt[20]} :
                                   (*i_cnt_en & *i_immdec_en[1]) ? {*i_ctrl[3] ? $signbit : $imm_b24_b20[0], $imm_b19_b12_b20[8:1]} :
                                   $imm_b19_b12_b20;
         <<1$imm7 = *i_wb_en ? *i_wb_rdt[7] :
                    *i_cnt_en ? $signbit :
                    $imm7;
         <<1$imm_b30_b25[5:0] = *i_wb_en ? *i_wb_rdt[30:25] :
                               (*i_cnt_en & *i_immdec_en[3]) ? {*i_ctrl[2] ? $imm7 : *i_ctrl[1] ? $signbit : $imm_b19_b12_b20[0], $imm_b30_b25[5:1]} :
                               $imm_b30_b25;
         <<1$imm_b24_b20[4:0] = *i_wb_en ? *i_wb_rdt[24:20] :
                               (*i_cnt_en & *i_immdec_en[2]) ? {$imm_b30_b25[0], $imm_b24_b20[4:1]} :
                               $imm_b24_b20;
         <<1$imm_b11_b7[4:0] = *i_wb_en ? *i_wb_rdt[11:7] :
                              (*i_cnt_en & *i_immdec_en[0]) ? {$imm_b30_b25[0], $imm_b11_b7[4:1]} :
                              $imm_b11_b7;
         '], ['
         
         // Assignments for SHARED=0 case
         {<<1$rs2_addr_w1[4:0], <<1$rs1_addr_w1[4:0], <<1$rd_addr_w1[4:0]} = *i_wb_en ? {*i_wb_rdt[24:20], *i_wb_rdt[19:15], *i_wb_rdt[11:7]} : {$rs2_addr_w1, $rs1_addr_w1, $rd_addr_w1};
         
         <<1$imm7 = *i_cnt_en ? $signbit :
                     *i_wb_en ? *i_wb_rdt[7] : 
                                $imm7;
         
         {<<1$imm_b24_b20[4:0], <<1$imm_b11_b7[4:0]} = *i_cnt_en ? {{$imm_b30_b25[0], $imm_b24_b20[4:1]}, {$imm_b30_b25[0], $imm_b11_b7[4:1]}} :
                                                        *i_wb_en ? {*i_wb_rdt[24:20], *i_wb_rdt[11:7]} :
                                                                   {$imm_b24_b20, $imm_b11_b7};
         
         <<1$imm_b30_b25[5:0] = *i_cnt_en ? {*i_ctrl[2] ? $imm7 : *i_ctrl[1] ? $signbit : $imm_b19_b12_b20[0], $imm_b30_b25[5:1]} :
                                *i_wb_en ? *i_wb_rdt[30:25] :
                                           $imm_b30_b25;
         
         <<1$imm_b19_b12_b20[8:0] = *i_cnt_en ? {*i_ctrl[3] ? $signbit : $imm_b24_b20[0], $imm_b19_b12_b20[8:1]} :
                                    *i_wb_en ? {*i_wb_rdt[19:12], *i_wb_rdt[20]} :
                                               $imm_b19_b12_b20;
         '])
         '])
         
         // Output assignments
         m5_if_eq_block(m5_cond_w_1, 1, ['
         *o_csr_imm = $imm_b19_b12_b20[4];
         
         m5_if_eq_block(m5_cond_shared, 1, ['
         *o_rs1_addr = $imm_b19_b12_b20[8:4];
         *o_rs2_addr = $imm_b24_b20;
         *o_rd_addr  = $imm_b11_b7;
         '], ['
         *o_rd_addr  = $rd_addr_w1;
         *o_rs1_addr = $rs1_addr_w1;
         *o_rs2_addr = $rs2_addr_w1;
         '])
         
         *o_imm = *i_cnt_done ? $signbit : *i_ctrl[0] ? $imm_b11_b7[0] : $imm_b24_b20[0];
         '], ['
         *o_csr_imm = {$ii18, $ii17, $ii16, $ii15};
         *o_rd_addr  = $rd_addr;
         *o_rs1_addr = $rs1_addr;
         *o_rs2_addr = $rs2_addr;
         
         *o_imm = {(*i_cnt_done ? $signbit : (*i_ctrl[0] ? $ii10 : $ii23)),
                   *i_ctrl[0] ? $ii9 : $ii22,
                   *i_ctrl[0] ? $ii8 : $ii21,
                   *i_ctrl[0] ? $ii7_b2 : $ii20_b2};
         '])
         
         \SV_plus
            // Clock alias for TL-Verilog
            wire clk = i_clk;

\SV
endmodule
