\TLV_version 1d: tl-x.org
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
   |default
      @0
         \SV_plus
            wire clk = i_clk;
            
            assign $$dat_valid =
                 i_mdu_op |
                 i_word |
                 (i_bytecnt == 2'b00) |
                 (i_half & ! i_bytecnt[1]);

            assign o_rd = $dat_valid ? i_bufreg2_q : {W{i_signed & $signbit}};

            assign o_wb_sel = {
                (i_lsb == 2'b11) | i_word | (i_half & i_lsb[1]),     // [3]
                (i_lsb == 2'b10) | i_word,                           // [2]
                (i_lsb == 2'b01) | i_word | (i_half & ! i_lsb[1]),   // [1]
                (i_lsb == 2'b00)                                     // [0]
            };

            always \@(posedge clk) begin
               $$signbit <= $dat_valid ? i_bufreg2_q[B] : $signbit;
            end

            /*
             mem_misalign is checked after the init stage to decide whether to do a data
             bus transaction or go to the trap state. It is only guaranteed to be correct
             at this time
             */
            assign o_misalign = WITH_CSR & ((i_lsb[0] & (i_word | i_half)) | (i_lsb[1] & i_word));
\SV
endmodule
