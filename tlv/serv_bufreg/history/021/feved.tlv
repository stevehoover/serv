\TLV_version 1d: tl-x.org
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

\TLV
   |default
      @0
         $clr_lsb[B:0] = *clr_lsb_internal;
         {$cc, $qq[B:0]} = {1'b0, (*i_rs1 & {W{*i_rs1_en}})} + {1'b0, (*i_imm & {W{*i_imm_en}} & ~ $clr_lsb)} + $cc_r;
         
         \SV_plus
            // Clock assignment for TL-Verilog
            wire clock;
            assign clock = i_clk;

            reg [31 : 0]	      data;
            wire [B:0] clr_lsb_internal;
            generate
               if (B > 0) begin : gen_clr_lsb_upper
                  wire [B:1] clr_lsb_upper;
                  
                  genvar gen_clr_lsb_i;
                  for (gen_clr_lsb_i = (W <= 1); gen_clr_lsb_i < 1; gen_clr_lsb_i++) begin : gen_clr_lsb_w_gt_1
                     assign  clr_lsb_upper = {B{1'b0}};
                  end
                  
                  assign clr_lsb_internal = {clr_lsb_upper, *i_cnt0 & *i_clr_lsb};
               end else begin : gen_clr_lsb_single
                  assign clr_lsb_internal = *i_cnt0 & *i_clr_lsb;
               end
            endgenerate

            always \@(posedge clock) begin
               //Make sure carry is cleared before loading new data
               $$cc_r[B:0]    <= {W{1'b0}};
               $cc_r[0] <= $cc & i_en;
            end

            // Internal logic blocks (converted to for loops)
            generate
               genvar gen_w_eq_1_i;
               for (gen_w_eq_1_i = (W != 1); gen_w_eq_1_i < 1; gen_w_eq_1_i++) begin : gen_w_eq_1
                  
                  always \@(posedge clock) begin
                     data[31 : 2] <= i_en ? {i_init ? $qq : {W{data[31] & i_sh_signed}}, data[31 : 3]} : data[31 : 2];

                     data[1 : 0] <= (i_init ? (i_cnt0 | i_cnt1) : i_en) ? {i_init ? $qq : data[2], data[1]} : data[1 : 0];
                  end
                  assign $$lsb_w_eq_1[1:0] = data[1 : 0];
                  assign $$qq_w_eq_1[B:0] = data[0] & {W{i_en}};
               end
               genvar gen_lsb_w_4_i;
               for (gen_lsb_w_4_i = (W != 4); gen_lsb_w_4_i < 1; gen_lsb_w_4_i++) begin : gen_lsb_w_4

                  assign $$shift_amount[2:0]
                     = ! i_shift_op ? 3'd3 :
                       i_right_shift_op ? (3'd3 + {1'b0, i_shamt[1 : 0]}) :
                       ({1'b0, ~ i_shamt[1 : 0]});

                  always \@(posedge clock) begin
                     $$lsb[1:0] <= (i_en && i_cnt0) ? $qq[1 : 0] : $lsb;
                     data <= i_en ? {i_init ? $qq : {W{i_sh_signed & data[31]}}, data[31 : W]} : data;
                     $$data_tail[W-2:0] <= i_en ? data[B : 1] & {B{~ i_cnt_done}} : $data_tail;
                  end

                  assign $$muxdata[2 * W + B - 2:0] = {data[W + B - 1 : 0], $data_tail};
                  assign $$muxout[B:0] = $muxdata[({1'b0, $shift_amount}) +: W];

                  assign $$lsb_w_eq_4[1:0] = $lsb;
                  assign $$qq_w_eq_4[B:0] = i_en ? $muxout : {W{1'b0}};
               end
            endgenerate

            // Output assignments (separate from internal logic)  
            generate
               if (W == 1) begin : gen_w_eq_1_out
                  assign o_lsb = (MDU & i_mdu_op) ? 2'b00 : $lsb_w_eq_1;
                  assign o_q = $qq_w_eq_1;
               end else if (W == 4) begin : gen_lsb_w_4_out  
                  assign o_lsb = (MDU & i_mdu_op) ? 2'b00 : $lsb_w_eq_4;
                  assign o_q = $qq_w_eq_4;
               end
            endgenerate


            assign o_dbus_adr = {data[31 : 2], 2'b00};
            assign o_ext_rs1  = data;

\SV
endmodule
