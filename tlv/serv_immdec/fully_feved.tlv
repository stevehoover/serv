\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)

// SERV Immediate Decoder TLV Macro
// Decodes and shifts immediate values from RISC-V instructions
// Supports both bit-serial (W=1) and parallel (W=4) operation modes
\TLV serv_immdec(/_top)
   |default
      @0
         // Main immediate decoder logic
         // Handles parameterized width (W=1 bit-serial, W=4 parallel)
         // and shared/separate RF address register modes
         
         // Signal assignments for immediate decoder
         
         // W=1 case: bit-serial processing with immediate shift registers
         m5_if_eq_block(m5_cond_w_1, 1, ['
         /* CSR immediates are always zero-extended, hence clear the signbit */
         <<1$imm31 = $wb_en ? $wb_rdt[31] : $imm31;
         $signbit = $imm31 & ! $csr_imm_en;
         '], ['
         $signbit = $ii31 & ! $csr_imm_en;
         
         // Common initialization for address registers
         {<<1$ii31, <<1$rs2_addr[4:0], <<1$rs1_addr[4:0], <<1$rd_addr[4:0]} = $wb_en ? {$wb_rdt[31], $wb_rdt[24:20], $wb_rdt[19:15], $wb_rdt[11:7]} : 
                                                                                            {$ii31, $rs2_addr, $rs1_addr, $rd_addr};
         
         // Bit lane 3
         <<1$ii7 = $cnt_en ? $signbit :
                    $wb_en ? $wb_rdt[7] :
                             $ii7;
         
         {<<1$ii23, <<1$ii10} = $cnt_en ? {$ii27, $ii27} :
                                 $wb_en ? {$wb_rdt[23], $wb_rdt[10]} :
                                          {$ii23, $ii10};
         
         <<1$ii27 = $cnt_en ? ($ctrl[2] ? $ii7 : $ctrl[1] ? $signbit : $ii20) :
                     $wb_en ? $wb_rdt[27] :
                              $ii27;
         
         {<<1$ii20, <<1$ii15} = $cnt_en ? {$ii15, $ii19} :
                                 $wb_en ? {$wb_rdt[20], $wb_rdt[15]} :
                                          {$ii20, $ii15};
         
         {<<1$ii19, <<1$ii18, <<1$ii17} = $cnt_en ? ($ctrl[3] ? {$signbit, $signbit, $signbit} : {$ii23, $ii22, $ii21}) :
                                           $wb_en ? {$wb_rdt[19], $wb_rdt[18], $wb_rdt[17]} :
                                                    {$ii19, $ii18, $ii17};
         
         // Bit lane 2
         {<<1$ii22, <<1$ii9} = $cnt_en ? {$ii26, $ii26} :
                                $wb_en ? {$wb_rdt[22], $wb_rdt[9]} :
                                         {$ii22, $ii9};
         
         {<<1$ii26, <<1$ii14} = $cnt_en ? {$ii30, $ii18} :
                                 $wb_en ? {$wb_rdt[26], $wb_rdt[14]} :
                                          {$ii26, $ii14};
         
         {<<1$ii30, <<1$ii29, <<1$ii28} = $cnt_en ? (($ctrl[1] | $ctrl[2]) ? {$signbit, $signbit, $signbit} : {$ii14, $ii13, $ii12}) :
                                           $wb_en ? {$wb_rdt[30], $wb_rdt[29], $wb_rdt[28]} :
                                                    {$ii30, $ii29, $ii28};
         
         // Bit lane 1
         {<<1$ii21, <<1$ii8} = $cnt_en ? {$ii25, $ii25} :
                                $wb_en ? {$wb_rdt[21], $wb_rdt[8]} :
                                         {$ii21, $ii8};
         
         {<<1$ii25, <<1$ii13} = $cnt_en ? {$ii29, $ii17} :
                                 $wb_en ? {$wb_rdt[25], $wb_rdt[13]} :
                                          {$ii25, $ii13};
         
         // Bit lane 0
         {<<1$ii20_b2, <<1$ii7_b2} = $cnt_en ? {$ii24, $ii11} :
                                      $wb_en ? {$wb_rdt[20], $wb_rdt[7]} :
                                               {$ii20_b2, $ii7_b2};
         
         {<<1$ii24, <<1$ii11} = $cnt_en ? {$ii28, $ii28} :
                                 $wb_en ? {$wb_rdt[24], $wb_rdt[11]} :
                                          {$ii24, $ii11};
         
         <<1$ii12 = $cnt_en ? $ii16 : $wb_en ? $wb_rdt[12] : $ii12;
         <<1$ii16 = $cnt_en ? ($ctrl[3] ? $signbit : $ii20_b2) : $wb_en ? $wb_rdt[16] : $ii16;
         '])
         
         // Immediate register assignments for W=1 case
         m5_if_eq_block(m5_cond_w_1, 1, ['
         
         // Shared RF address and immediate registers case (SHARED_RFADDR_IMM_REGS=1)
         m5_if_eq_block(m5_cond_shared, 1, ['
         $immdec_en[3:0] = $immdec_en_in;
         <<1$imm_b19_b12_b20[8:0] = $wb_en ? {$wb_rdt[19:12], $wb_rdt[20]} :
                                   ($cnt_en & $immdec_en[1]) ? {$ctrl[3] ? $signbit : $imm_b24_b20[0], $imm_b19_b12_b20[8:1]} :
                                   $imm_b19_b12_b20;
         <<1$imm7 = $wb_en ? $wb_rdt[7] :
                    $cnt_en ? $signbit :
                    $imm7;
         <<1$imm_b30_b25[5:0] = $wb_en ? $wb_rdt[30:25] :
                               ($cnt_en & $immdec_en[3]) ? {$ctrl[2] ? $imm7 : $ctrl[1] ? $signbit : $imm_b19_b12_b20[0], $imm_b30_b25[5:1]} :
                               $imm_b30_b25;
         <<1$imm_b24_b20[4:0] = $wb_en ? $wb_rdt[24:20] :
                               ($cnt_en & $immdec_en[2]) ? {$imm_b30_b25[0], $imm_b24_b20[4:1]} :
                               $imm_b24_b20;
         <<1$imm_b11_b7[4:0] = $wb_en ? $wb_rdt[11:7] :
                              ($cnt_en & $immdec_en[0]) ? {$imm_b30_b25[0], $imm_b11_b7[4:1]} :
                              $imm_b11_b7;
         '], ['
         
         // Separate immediate registers case (SHARED_RFADDR_IMM_REGS=0)
         {<<1$rs2_addr_w1[4:0], <<1$rs1_addr_w1[4:0], <<1$rd_addr_w1[4:0]} = $wb_en ? {$wb_rdt[24:20], $wb_rdt[19:15], $wb_rdt[11:7]} : 
                                                                                         {$rs2_addr_w1, $rs1_addr_w1, $rd_addr_w1};
         
         <<1$imm7 = $cnt_en ? $signbit :
                     $wb_en ? $wb_rdt[7] : 
                              $imm7;
         
         {<<1$imm_b24_b20[4:0], <<1$imm_b11_b7[4:0]} = $cnt_en ? {{$imm_b30_b25[0], $imm_b24_b20[4:1]}, 
                                                               {$imm_b30_b25[0], $imm_b11_b7[4:1]}} :
                                                        $wb_en ? {$wb_rdt[24:20], $wb_rdt[11:7]} :
                                                                 {$imm_b24_b20, $imm_b11_b7};
         
         <<1$imm_b30_b25[5:0] = $cnt_en ? {$ctrl[2] ? $imm7 : $ctrl[1] ? $signbit : $imm_b19_b12_b20[0], $imm_b30_b25[5:1]} :
                                $wb_en ? $wb_rdt[30:25] :
                                         $imm_b30_b25;
         
         <<1$imm_b19_b12_b20[8:0] = $cnt_en ? {$ctrl[3] ? $signbit : $imm_b24_b20[0], $imm_b19_b12_b20[8:1]} :
                                    $wb_en ? {$wb_rdt[19:12], $wb_rdt[20]} :
                                             $imm_b19_b12_b20;
         '])
         '])
         
         // Output logic assignments
         m5_if_eq_block(m5_cond_w_1, 1, ['
         $csr_imm[W-1:0] = $imm_b19_b12_b20[4];
         
         m5_if_eq_block(m5_cond_shared, 1, ['
         $rs1_addr_out[4:0] = $imm_b19_b12_b20[8:4];
         $rs2_addr_out[4:0] = $imm_b24_b20;
         $rd_addr_out[4:0]  = $imm_b11_b7;
         '], ['
         $rd_addr_out[4:0]  = $rd_addr_w1;
         $rs1_addr_out[4:0] = $rs1_addr_w1;
         $rs2_addr_out[4:0] = $rs2_addr_w1;
         '])
         
         $imm[W-1:0] = $cnt_done ? $signbit : $ctrl[0] ? $imm_b11_b7[0] : $imm_b24_b20[0];
         '], ['
         // W=4 case: parallel processing with individual bit registers
         $csr_imm[W-1:0] = {$ii18, $ii17, $ii16, $ii15};
         $rd_addr_out[4:0]  = $rd_addr;
         $rs1_addr_out[4:0] = $rs1_addr;
         $rs2_addr_out[4:0] = $rs2_addr;
         
         $imm[W-1:0] = {($cnt_done ? $signbit : ($ctrl[0] ? $ii10 : $ii23)),
                        $ctrl[0] ? $ii9 : $ii22,
                        $ctrl[0] ? $ii8 : $ii21,
                        $ctrl[0] ? $ii7_b2 : $ii20_b2};
         '])

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

   // Clock alias for TL-Verilog
   wire clk = i_clk;

\TLV
   |default
      @0
         // SERV Immediate Decoder
         // Decodes and shifts immediate values from RISC-V instructions
         // Supports both bit-serial (W=1) and parallel (W=4) operation modes
         
         // Connect Verilog inputs:
         $cnt_en = *i_cnt_en;
         $cnt_done = *i_cnt_done;
         $csr_imm_en = *i_csr_imm_en;
         $ctrl[3:0] = *i_ctrl;
         $wb_en = *i_wb_en;
         $wb_rdt[31:7] = *i_wb_rdt;
         
         // Connect immdec_en input only when needed in shared case
         m5_if_eq_block(m5_cond_w_1, 1, ['
         m5_if_eq_block(m5_cond_shared, 1, ['
         $immdec_en_in[3:0] = *i_immdec_en;
         '])
         '])
         
   m5+serv_immdec(/top)
   
   // Connect Verilog outputs:
   |default
      @0
         *o_csr_imm = $csr_imm;
         *o_imm = $imm;
         *o_rd_addr = $rd_addr_out;
         *o_rs1_addr = $rs1_addr_out;
         *o_rs2_addr = $rs2_addr_out;
         
\SV
endmodule
