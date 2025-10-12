\m5_TLV_version 1d: tl-x.org
\m5
use(m5-1.0)

// The guts of module serv_mem_if.
\TLV serv_mem_if(/_top)
   |default
      @0
         $dat_valid =
              $mdu_op |
              $word |
              ($bytecnt == 2'b00) |
              ($half & ! $bytecnt[1]);
              
         <<1$signbit = $dat_valid ? $bufreg2_q[B] : $signbit;
            
         $rd[B:0] = $dat_valid ? $bufreg2_q : {W{$signed & $signbit}};
         
         $wb_sel[3:0] = {($lsb == 2'b11) | $word | ($half & $lsb[1]), ($lsb == 2'b10) | $word, ($lsb == 2'b01) | $word | ($half & ! $lsb[1]), ($lsb == 2'b00)};
         
         /*
          mem_misalign is checked after the init stage to decide whether to do a data
          bus transaction or go to the trap state. It is only guaranteed to be correct
          at this time
          */
         $misalign = WITH_CSR & (($lsb[0] & ($word | $half)) | ($lsb[1] & $word));

\SV
`default_nettype none
module serv_mem_if
  #(
    parameter [0:0] WITH_CSR = 1,
    parameter       W = 1,
    parameter       B = W-1
  )
  (
   input wire        i_clk,
   //State
   input wire [1:0]  i_bytecnt,
   input wire [1:0]  i_lsb,
   output wire       o_misalign,
   //Control
   input wire        i_signed,
   input wire        i_word,
   input wire        i_half,
   //MDU
   input wire        i_mdu_op,
   //Data
   input wire [B:0] i_bufreg2_q,
   output wire [B:0] o_rd,
   //External interface
   output wire [3:0] o_wb_sel);
\TLV
   \SV_plus
      wire clk = i_clk;
      
   // Connect Verilog inputs:
   |default
      @0
         $bytecnt[1:0] = *i_bytecnt;
         $lsb[1:0] = *i_lsb;
         $signed = *i_signed;
         $word = *i_word;
         $half = *i_half;
         $mdu_op = *i_mdu_op;
         $bufreg2_q[B:0] = *i_bufreg2_q;
         
   m5+serv_mem_if(/top)
   
   // Connect Verilog outputs:
   |default
      @0
         *o_misalign = $misalign;
         *o_rd = $rd;
         *o_wb_sel = $wb_sel;
         
\SV
endmodule
