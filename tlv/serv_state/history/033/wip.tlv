\TLV_version 1d: tl-x.org
\SV
module serv_state
  #(parameter RESET_STRATEGY = "MINI",
    parameter [0:0] WITH_CSR = 1,
    parameter [0:0] ALIGN =0,
    parameter [0:0] MDU = 0,
    parameter       W = 1
  )
  (
   input wire              i_clk,
   input wire              i_rst,
   //State
   input wire              i_new_irq,
   input wire              i_alu_cmp,
   output wire              o_init,
   output wire             o_cnt_en,
   output wire              o_cnt0to3,
   output wire              o_cnt12to31,
   output wire              o_cnt0,
   output wire              o_cnt1,
   output wire              o_cnt2,
   output wire              o_cnt3,
   output wire              o_cnt7,
   output wire              o_cnt11,
   output wire              o_cnt12,
   output wire              o_cnt_done,
   output wire              o_bufreg_en,
   output wire              o_ctrl_pc_en,
   output reg              o_ctrl_jump,
   output wire              o_ctrl_trap,
   input wire              i_ctrl_misalign,
   input wire              i_sh_done,
   output wire [1:0] o_mem_bytecnt,
   input wire              i_mem_misalign,
   //Control
   input wire              i_bne_or_bge,
   input wire              i_cond_branch,
   input wire              i_dbus_en,
   input wire              i_two_stage_op,
   input wire              i_branch_op,
   input wire              i_shift_op,
   input wire              i_sh_right,
   input wire              i_alu_rd_sel1,
   input wire              i_rd_alu_en,
   input wire              i_e_op,
   input wire              i_rd_op,
   //MDU
   input wire              i_mdu_op,
   output wire              o_mdu_valid,
   //Extension
   input wire              i_mdu_ready,
   //External
   output wire              o_dbus_cyc,
   input wire              i_dbus_ack,
   output wire              o_ibus_cyc,
   input wire              i_ibus_ack,
   //RF Interface
   output wire              o_rf_rreq,
   output wire              o_rf_wreq,
   input wire              i_rf_ready,
   output wire              o_rf_rd_en);

\TLV
   |default
      @0
         /cnt_w1[0:0]
         /cnt_w4[0:0] 
         /csr[0:0]
         
         //Take branch for jump or branch instructions (opcode == 1x0xx) if
         //a) It's an unconditional branch (opcode[0] == 1)
         //b) It's a conditional branch (opcode[0] == 0) of type beq,blt,bltu (funct3[0] == 0) and ALU compare is true
         //c) It's a conditional branch (opcode[0] == 0) of type bne,bge,bgeu (funct3[0] == 1) and ALU compare is false
         //Only valid during the last cycle of INIT, when the branch condition has
         //been calculated.
         $take_branch = *i_branch_op & (!*i_cond_branch | (*i_alu_cmp^*i_bne_or_bge));

         $last_init = *o_cnt_done & *o_init;
         
         //trap_pending is only guaranteed to have correct value during the
         // last cycle of the init stage
         $trap_pending = WITH_CSR & (($take_branch & *i_ctrl_misalign & !ALIGN) |
                                     (*i_dbus_en & *i_mem_misalign));
         
         // Output assignment based on parameter WITH_CSR
         $misalign_trap_sync = (WITH_CSR) ? /csr[0]$misalign_trap_sync_r : 1'b0;
         
         *o_ctrl_trap = WITH_CSR & (*i_e_op | *i_new_irq | $misalign_trap_sync);
         
         // Simple output assignments
         *o_ibus_cyc = ibus_cyc & !reset;
         *o_init = *i_two_stage_op & !*i_new_irq & !init_done;
         *o_rf_rd_en = *i_rd_op & !*o_init;
         *o_rf_rreq = *i_ibus_ack | ($trap_pending & $last_init);
         *o_cnt_done = (out_cnt[4:2] == 3'b111) & cnt_r[3];
         
         // Simple counter-based outputs  
         *o_ctrl_pc_en = o_cnt_en & !*o_init;
         *o_mem_bytecnt = out_cnt[4:3];
         
         \SV_plus
            // Clock and reset signals for TL-Verilog convention
            wire clk = i_clk;
            wire reset = i_rst;

            reg         init_done;
            reg              ibus_cyc;










            assign o_cnt0to3   = (out_cnt[4:2] == 3'd0);
            assign o_cnt12to31 = (out_cnt[4] | (out_cnt[3:2] == 2'b11));
            assign o_cnt0 = (out_cnt[4:2] == 3'd0) & cnt_r[0];
            assign o_cnt1 = (out_cnt[4:2] == 3'd0) & cnt_r[1];
            assign o_cnt2 = (out_cnt[4:2] == 3'd0) & cnt_r[2];
            assign o_cnt3 = (out_cnt[4:2] == 3'd0) & cnt_r[3];
            assign o_cnt7 = (out_cnt[4:2] == 3'd1) & cnt_r[3];
            assign o_cnt11 = (out_cnt[4:2] == 3'd2) & cnt_r[3];
            assign o_cnt12 = (out_cnt[4:2] == 3'd3) & cnt_r[0];



            //valid signal for mdu
            assign o_mdu_valid = MDU & !o_cnt_en & init_done & i_mdu_op;

            //Prepare RF for writes when everything is ready to enter stage two
            // and the first stage didn't cause a misalign exception
            //Left shifts, SLT & Branch ops. First cycle after init
            //Right shift. o_sh_done
            //Mem ops. i_dbus_ack
            //MDU ops. i_mdu_ready
            assign o_rf_wreq = (i_shift_op & (i_sh_right ? (i_sh_done & ($last_init | !o_cnt_en & init_done)) : $last_init)) |
                                   i_dbus_ack | (MDU & i_mdu_ready) |
                                  (i_branch_op & ($last_init & !$trap_pending)) |
                                  (i_rd_alu_en & i_alu_rd_sel1 & $last_init);

            assign o_dbus_cyc = !o_cnt_en & init_done & i_dbus_en & !i_mem_misalign;

            //Prepare RF for reads when a new instruction is fetched
            // or when stage one caused an exception (rreq implies a write request too)




            /*
             bufreg is used during mem, branch, and shift operations

             mem : bufreg is used for dbus address. Shift in data during phase 1.
                   Shift out during phase 2 if there was a misalignment exception.

             branch : Shift in during phase 1. Shift out during phase 2

             shift : Shift in during phase 1. Continue shifting between phases (except
                     for the first cycle after init). Shift out during phase 2
             */
            
            assign o_bufreg_en = (o_cnt_en & (o_init | ((*o_ctrl_trap | i_branch_op) & i_two_stage_op))) | (i_shift_op & init_done & (i_sh_right | i_sh_done));





            always @(posedge clk) begin
               //ibus_cyc changes on three conditions.
               //1. i_rst is asserted. Together with the async gating above, o_ibus_cyc
               //   will be asserted as soon as the reset is released. This is how the
               //   first instruction is fetched
               //2. o_cnt_done and o_ctrl_pc_en are asserted. This means that SERV just
               //   finished updating the PC, is done with the current instruction and
               //   o_ibus_cyc gets asserted to fetch a new instruction
               //3. When i_ibus_ack, a new instruction is fetched and o_ibus_cyc gets
               //   deasserted to finish the transaction
               ibus_cyc <= (i_ibus_ack | o_cnt_done | reset) ? (o_ctrl_pc_en | reset) : ibus_cyc;

               init_done <= reset ? ((RESET_STRATEGY != "NONE") ? 1'b0 : init_done) :
                           o_cnt_done ? (o_init & !init_done) : init_done;

               o_ctrl_jump <= reset ? ((RESET_STRATEGY != "NONE") ? 1'b0 : o_ctrl_jump) :
                              o_cnt_done ? (o_init & $take_branch) : o_ctrl_jump;
            end

            /*
             Because SERV is 32-bit bit-serial we need a counter than can count 0-31
             to keep track of which bit we are currently processing. out_cnt and cnt_r
             are used together to create such a counter.
             The top three bits (out_cnt) are implemented as a normal counter, but
             instead of the two LSB, cnt_r is a 4-bit shift register which loops 0-3
             When cnt_r[3] is 1, out_cnt will be increased.

             The counting starts when the core is idle and the i_rf_ready signal
             comes in from the RF module by shifting in the i_rf_ready bit as LSB of
             the shift register. Counting is stopped by using o_cnt_done to block the
             bit that was supposed to be shifted into bit 0 of cnt_r.

             There are two benefit of doing the counter this way
             1. We only need to check four bits instead of five when we want to check
             if the counter is at a certain value. For 4-LUT architectures this means
             we only need one LUT instead of two for each comparison.
             2. We don't need a separate enable signal to turn on and off the counter
             between stages, which saves an extra FF and a unique control signal. We
             just need to check if cnt_r is not zero to see if the counter is
             currently running
             */

            // Counter implementation using for loops instead of generate if
            genvar gen_cnt_w_eq_1;
            for (gen_cnt_w_eq_1 = 0; gen_cnt_w_eq_1 < (W == 1); gen_cnt_w_eq_1++) begin : gen_cnt_w_eq_1
               always @(posedge clk) begin
                  /cnt_w1[gen_cnt_w_eq_1]$$cnt_lsb[3:0] <= (reset & (RESET_STRATEGY != "NONE")) ? 4'b0000 :
                                                            {/cnt_w1[gen_cnt_w_eq_1]$cnt_lsb[2:0],(/cnt_w1[gen_cnt_w_eq_1]$cnt_lsb[3] & !o_cnt_done) | i_rf_ready};
               end
               assign /cnt_w1[gen_cnt_w_eq_1]$$cnt_r_w1[3:0] = /cnt_w1[gen_cnt_w_eq_1]$cnt_lsb;
               assign /cnt_w1[gen_cnt_w_eq_1]$$o_cnt_en_w1 = | /cnt_w1[gen_cnt_w_eq_1]$cnt_lsb;
               assign /cnt_w1[gen_cnt_w_eq_1]$$out_cnt_inc_w1[2:0] = {2'd0,/cnt_w1[gen_cnt_w_eq_1]$cnt_r_w1[3]};
            end
            
            genvar gen_cnt_w_eq_4;
            for (gen_cnt_w_eq_4 = 0; gen_cnt_w_eq_4 < (W == 4); gen_cnt_w_eq_4++) begin : gen_cnt_w_eq_4
               always @(posedge clk) begin
                  /cnt_w4[gen_cnt_w_eq_4]$$cnt_en <= (reset & (RESET_STRATEGY != "NONE")) ? 1'b0 :
                                                      i_rf_ready ? 1'b1 :
                                                      o_cnt_done ? 1'b0 : /cnt_w4[gen_cnt_w_eq_4]$cnt_en;
               end
               assign /cnt_w4[gen_cnt_w_eq_4]$$cnt_r_w4[3:0] = 4'b1111;
               assign /cnt_w4[gen_cnt_w_eq_4]$$o_cnt_en_w4 = /cnt_w4[gen_cnt_w_eq_4]$cnt_en;
               assign /cnt_w4[gen_cnt_w_eq_4]$$out_cnt_inc_w4[2:0] = { 2'd0, /cnt_w4[gen_cnt_w_eq_4]$cnt_en };
            end

            reg [4:2] out_cnt;
            wire [3:0] cnt_r;

            // Unified counter logic 
            wire [2:0] out_cnt_increment;
            assign out_cnt_increment = (W == 1) ? |default/cnt_w1[0]$out_cnt_inc_w1 : 
                                       (W == 4) ? |default/cnt_w4[0]$out_cnt_inc_w4 : 3'd0;
                                       
            always @(posedge clk) begin
               out_cnt <= (reset & (RESET_STRATEGY != "NONE")) ? 3'd0 : (out_cnt + out_cnt_increment);
            end

            // Output assignments based on parameter W
            assign cnt_r = (W == 1) ? |default/cnt_w1[0]$cnt_r_w1 : 
                           (W == 4) ? |default/cnt_w4[0]$cnt_r_w4 : 4'b0;
            assign o_cnt_en = (W == 1) ? |default/cnt_w1[0]$o_cnt_en_w1 : 
                              (W == 4) ? |default/cnt_w4[0]$o_cnt_en_w4 : 1'b0;





            // CSR misalign trap logic - converted from generate if to conditional logic
            genvar gen_csr;
            for (gen_csr = 0; gen_csr < (WITH_CSR); gen_csr++) begin : gen_csr
               always @(posedge clk) begin
                  /csr[gen_csr]$$misalign_trap_sync_r <= (i_ibus_ack | o_cnt_done | reset) ? 
                                                         (!(i_ibus_ack | reset) & (($trap_pending & o_init) | /csr[gen_csr]$misalign_trap_sync_r)) :
                                                         /csr[gen_csr]$misalign_trap_sync_r;
               end
            end

            wire misalign_trap_sync;


\SV
endmodule
