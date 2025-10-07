\m5_TLV_version 1d: tl-x.org
\m5
use(m5-1.0)
\SV
module serv_bufreg #(
      parameter [0:0] MDU = 0,
      parameter W = 1,
      parameter B = W-1
)(
   input wire 	      i_clk,
   //State
   input wire 	      i_cnt0,
   input wire 	      i_cnt1,
   input wire 	      i_cnt_done,
   input wire 	      i_en,
   input wire 	      i_init,
   input wire           i_mdu_op,
   output wire [1:0]    o_lsb,
   //Control
   input wire 	      i_rs1_en,
   input wire 	      i_imm_en,
   input wire 	      i_clr_lsb,
   input wire 	      i_shift_op,
   input wire 	      i_right_shift_op,
   input wire [2:0]   i_shamt,
   input wire 	      i_sh_signed,
   //Data
   input wire [B:0] i_rs1,
   input wire [B:0] i_imm,
   output wire [B:0] o_q,
   //External
   output wire [31:0] o_dbus_adr,
   //Extension
   output wire [31:0] o_ext_rs1);

   // Clock assignment for TL-Verilog
   wire clk;
   assign clk = i_clk;
\TLV
   |default
      @0
         // === INPUT STAGE ===
         // Connect Verilog inputs to pipesignals
         $i_en = *i_en;
         $i_cnt0 = *i_cnt0;
         $i_cnt1 = *i_cnt1;
         $i_cnt_done = *i_cnt_done;
         $i_init = *i_init;
         $i_mdu_op = *i_mdu_op;
         $i_rs1_en = *i_rs1_en;
         $i_imm_en = *i_imm_en;
         $i_clr_lsb = *i_clr_lsb;
         $i_shift_op = *i_shift_op;
         $i_right_shift_op = *i_right_shift_op;
         $i_shamt[2:0] = *i_shamt;
         $i_sh_signed = *i_sh_signed;
         $i_rs1[B:0] = *i_rs1;
         $i_imm[B:0] = *i_imm;
         
         // === COMPUTATION STAGE ===
         // Clear LSB computation (simplified from clr_lsb_internal)
         $clr_lsb[B:0] = (B > 0) ? {{B{1'b0}}, ($i_cnt0 & $i_clr_lsb)} : ($i_cnt0 & $i_clr_lsb);
         
         // Adder computation for buffer register
         {$cc, $qq[B:0]} = {1'b0, ($i_rs1 & {W{$i_rs1_en}})} + {1'b0, ($i_imm & {W{$i_imm_en}} & ~ $clr_lsb)} + $cc_r;
         
         // Shift amount computation for W==4 case
         $shift_amount[2:0] = ! $i_shift_op ? 3'd3 : 
                              $i_right_shift_op ? (3'd3 + {1'b0, $i_shamt[1 : 0]}) :
                              ({1'b0, ~ $i_shamt[1 : 0]});
         
         // Mux data preparation and selection for W==4 case
         $muxdata[2 * W + B - 2:0] = {$data[W + B - 1 : 0], $data_tail};
         $muxout[B:0] = $muxdata[({1'b0, $shift_amount}) +: W];
         
         // Output computation for different width cases
         $lsb_w_eq_1[1:0] = $data[1 : 0];
         $qq_w_eq_1[B:0] = $data[0] & {W{$i_en}};
         $qq_w_eq_4[B:0] = $i_en ? $muxout : {W{1'b0}};
         
         // === OUTPUT STAGE ===
         // Final output selection based on module parameters
         $o_lsb[1:0] = (*MDU & $i_mdu_op) ? 2'b00 : 
                       (W == 1) ? $lsb_w_eq_1 : $lsb;
         $o_q[B:0] = (W == 1) ? $qq_w_eq_1 : $qq_w_eq_4;
         $o_dbus_adr[31:0] = {$data[31 : 2], 2'b00};
         $o_ext_rs1[31:0] = $data;
         
         // === SEQUENTIAL UPDATE STAGE ===
         // State updates for next cycle (using <<1 for register behavior)
         <<1$lsb[1:0] = ($i_en && $i_cnt0) ? |default$qq[1 : 0] : $lsb;
         <<1$data_tail[W-2:0] = $i_en ? (|default$data[B : 1] & {B{~ $i_cnt_done}}) : $data_tail;
         <<1$cc_r[B:0] = {{B{1'b0}}, $cc & $i_en};
         <<1$data[31:0] = (W == 1) ? 
                          {($i_en ? {$i_init ? $qq : {W{$data[31] & $i_sh_signed}}, $data[31 : 3]} : $data[31 : 2]),
                           (($i_init ? ($i_cnt0 | $i_cnt1) : $i_en) ? {$i_init ? $qq : $data[2], $data[1]} : $data[1 : 0])} :
                          ($i_en ? {$i_init ? $qq : {W{$i_sh_signed & $data[31]}}, $data[31 : W]} : $data);
         
         // Connect pipesignals to Verilog outputs
         *o_lsb = $o_lsb;
         *o_q = $o_q;
         *o_dbus_adr = $o_dbus_adr;
         *o_ext_rs1 = $o_ext_rs1;


\SV
endmodule
