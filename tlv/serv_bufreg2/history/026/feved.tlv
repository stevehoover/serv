\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)

// The guts of serv_bufreg2 module - TLV macro implementation
\TLV serv_bufreg2(/_top)
   |default
      @0
         // High and low data words form a 32-bit word

         /*
          Before a store operation, the data to be written needs to be shifted into
          place. Depending on the address alignment, we need to shift different
          amounts. One formula for calculating this is to say that we shift when
          i_lsb + i_bytecnt < 4. Unfortunately, the synthesis tools don't seem to be
          clever enough so the hideous expression below is used to achieve the same
          thing in a more optimal way.
          */
         $byte_valid
           = (!$lsb[0] & !$lsb[1])         |
             (!$bytecnt[0] & !$bytecnt[1]) |
             (!$bytecnt[1] & !$lsb[1])     |
             (!$bytecnt[1] & !$lsb[0])     |
             (!$bytecnt[0] & !$lsb[1]);

         $shift_en = $shift_op ? ($en & $init & ($bytecnt == 2'b00)) : ($en & $byte_valid);

         $cnt_en = ($shift_op & (!$init | ($cnt_done & $sh_right)));

         /* The dat register has three different use cases for store, load and
          shift operations.
          store : Data to be written is shifted to the correct position in dat during
                  init by shift_en and is presented on the data bus as o_wb_dat
          load  : Data from the bus gets latched into dat during i_wb_ack and is then
                  shifted out at the appropriate time to end up in the correct
                  position in rd
          shift : Data is shifted in during init. After that, the six LSB are used as
                  a downcounter (with bit 5 initially set to 0) that trigger
                  o_sh_done when they wrap around to indicate that
                  the requested number of shifts have been performed
          */

         // Note: cnt_next logic with parameter-dependent ranges kept in \SV_plus
         // to avoid out-of-bounds access issues while maintaining FEV compatibility

         // Create intermediate pipesignal to avoid using Verilog output signal in logic
         $op_b[B:0] = $op_b_sel ? $rs2 : $imm;
         $dat_combined[31:0] = {$data_hi, $data_lo};

         $dat_shamt[7:0] = $cnt_en ?
                //Down counter mode
                $cnt_next :
                //Shift reg mode
                {$op_b, $data_hi[7 : W]};

         <<1$data_hi[7:0] = ($shift_en | $cnt_en | $load) ? 
                            ($load ? $dat[31:24] : $dat_shamt & {2'b11, !($shift_op & $cnt7 & !$cnt_en), 5'b11111}) :
                            $data_hi;
         <<1$data_lo[23:0] = ($shift_en | $load) ? 
                             ($load ? $dat[23:0] : {$data_hi[B:0], $data_lo[23:W]}) :
                             $data_lo;

         \SV_plus
            // Parameter-dependent logic using pipesignals instead of Verilog outputs
            generate
               if (W == 1) begin : gen_cnt_w_eq_1
                  assign $$cnt_next_w_eq_1[7:0] = {$op_b, $data_hi[7], $data_hi[5:0]-6'd1};
               end
               if (W == 4) begin : gen_cnt_w_eq_4
                  assign $$cnt_next_w_eq_4[7:0] = {$op_b[3:2], $data_hi[5:0]-6'd4};
               end
            endgenerate

            assign $$cnt_next[7:0] = (W == 1) ? $cnt_next_w_eq_1 :
                                    (W == 4) ? $cnt_next_w_eq_4 :
                                              8'h00; // default case

         // Output computation
         $o_sh_done = $dat_shamt[5];
         $o_op_b[B:0] = $op_b;
         $o_q[B:0] = ({W{($lsb == 2'd3)}} & $dat_combined[W+23:24]) |
                     ({W{($lsb == 2'd2)}} & $dat_combined[W+15:16]) |
                     ({W{($lsb == 2'd1)}} & $dat_combined[W+7:8])   |
                     ({W{($lsb == 2'd0)}} & $dat_combined[W-1:0]);
         $o_dat[31:0] = $dat_combined;

\SV
module serv_bufreg2
  #(parameter W = 1,
    //Internally calculated. Do not touch
    parameter B=W-1)
  (
   input wire          clk,
   //State
   input wire          i_en,
   input wire          i_init,
   input wire          i_cnt7,
   input wire          i_cnt_done,
   input wire          i_sh_right,
   input wire [1:0]   i_lsb,
   input wire [1:0]   i_bytecnt,
   output wire          o_sh_done,
   //Control
   input wire          i_op_b_sel,
   input wire          i_shift_op,
   //Data
   input wire [B:0]   i_rs2,
   input wire [B:0]   i_imm,
   output wire [B:0]  o_op_b,
   output wire [B:0]  o_q,
   //External
   output wire [31:0] o_dat,
   input wire          i_load,
   input wire [31:0]  i_dat);
\TLV
   // Connect Verilog inputs:
   |default
      @0
         $en = *i_en;
         $init = *i_init;
         $cnt7 = *i_cnt7;
         $cnt_done = *i_cnt_done;
         $sh_right = *i_sh_right;
         $lsb[1:0] = *i_lsb;
         $bytecnt[1:0] = *i_bytecnt;
         $op_b_sel = *i_op_b_sel;
         $shift_op = *i_shift_op;
         $rs2[B:0] = *i_rs2;
         $imm[B:0] = *i_imm;
         $load = *i_load;
         $dat[31:0] = *i_dat;
         
   // Instantiate the serv_bufreg2 macro
   m5+serv_bufreg2(/top)
   
   // Connect Verilog outputs:
   |default
      @0
         *o_sh_done = $o_sh_done;
         *o_op_b = $o_op_b;
         *o_q = $o_q;
         *o_dat = $o_dat;
\SV
endmodule
