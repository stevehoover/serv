\m5_TLV_version 1d: tl-x.org
\m5
use(m5-1.0)
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
         // Connect Verilog inputs to pipesignals
         $new_irq = *i_new_irq;
         $alu_cmp = *i_alu_cmp;
         $ctrl_misalign = *i_ctrl_misalign;
         $mem_misalign = *i_mem_misalign;
         $bne_or_bge = *i_bne_or_bge;
         $cond_branch = *i_cond_branch;
         $dbus_en = *i_dbus_en;
         $two_stage_op = *i_two_stage_op;
         $branch_op = *i_branch_op;
         $e_op = *i_e_op;
         $rd_op = *i_rd_op;
         $ibus_ack = *i_ibus_ack;
         $rf_ready = *i_rf_ready;
         
         /cnt_w1[0:W != 1 ? -1 \: 0]
            // Sequential logic for cnt_lsb (will be conditionally instantiated by generate for loop)
            <<1$cnt_lsb[3:0] = (reset & (RESET_STRATEGY != "NONE")) ? 4'b0000 :
                               {$cnt_lsb[2:0],($cnt_lsb[3] & !*o_cnt_done) | |default<>0$rf_ready};
            
            // Combinational logic
            $cnt_r_w1[3:0] = $cnt_lsb;
            $o_cnt_en_w1 = | $cnt_lsb;
            $out_cnt_inc_w1[2:0] = {2'd0, $cnt_r_w1[3]};
         
         /cnt_w4[0:W != 4 ? -1 \: 0] 
            // Sequential logic for cnt_en (will be conditionally instantiated by generate for loop)
            <<1$cnt_en = (reset & (RESET_STRATEGY != "NONE")) ? 1'b0 :
                         |default<>0$rf_ready ? 1'b1 :
                         *o_cnt_done ? 1'b0 : $cnt_en;
            
            // Combinational logic
            $cnt_r_w4[3:0] = 4'b1111;
            $o_cnt_en_w4 = $cnt_en;
            $out_cnt_inc_w4[2:0] = {2'd0, $cnt_en};
            
         /csr[0:!WITH_CSR ? -1 \: 0]
            // Sequential logic for misalign_trap_sync_r (will be conditionally instantiated by generate for loop)  
            <<1$misalign_trap_sync_r = (|default<>0$ibus_ack | *o_cnt_done | reset) ? 
                                       (!(|default<>0$ibus_ack | reset) & ((|default<>0$trap_pending & |default<>0$init_out) | $misalign_trap_sync_r)) :
                                       $misalign_trap_sync_r;
         
         // Counter signal connections - parameter-dependent
         $cnt_r[3:0] = (W == 1) ? /cnt_w1[0]$cnt_r_w1 : /cnt_w4[0]$cnt_r_w4;
         $o_cnt_en = (W == 1) ? /cnt_w1[0]$o_cnt_en_w1 : /cnt_w4[0]$o_cnt_en_w4;
         $out_cnt_inc[2:0] = (W == 1) ? /cnt_w1[0]$out_cnt_inc_w1 : /cnt_w4[0]$out_cnt_inc_w4;
         
         //Take branch for jump or branch instructions (opcode == 1x0xx) if
         //a) It's an unconditional branch (opcode[0] == 1)
         //b) It's a conditional branch (opcode[0] == 0) of type beq,blt,bltu (funct3[0] == 0) and ALU compare is true
         //c) It's a conditional branch (opcode[0] == 0) of type bne,bge,bgeu (funct3[0] == 1) and ALU compare is false
         //Only valid during the last cycle of INIT, when the branch condition has
         //been calculated.
         $take_branch = $branch_op & (!$cond_branch | ($alu_cmp^$bne_or_bge));

         $last_init = *o_cnt_done & $init_out;
         
         //trap_pending is only guaranteed to have correct value during the
         // last cycle of the init stage
         $trap_pending = WITH_CSR & (($take_branch & $ctrl_misalign & !ALIGN) |
                                     ($dbus_en & $mem_misalign));
         
         // Output assignment based on parameter WITH_CSR
         $misalign_trap_sync = (WITH_CSR) ? /csr[0]$misalign_trap_sync_r : 1'b0;
         
         $ctrl_trap_out = WITH_CSR & ($e_op | $new_irq | $misalign_trap_sync);
         
         // Output pipesignals
         $ibus_cyc_out = $ibus_cyc & !reset;
         $init_out = $two_stage_op & !$new_irq & !$init_done;
         $rf_rd_en_out = $rd_op & !$init_out;
         $rf_rreq_out = $ibus_ack | ($trap_pending & $last_init);
         $cnt_done_out = ($out_cnt[4:2] == 3'b111) & $cnt_r[3];
         
         // Counter-based output pipesignals  
         $mem_bytecnt_out[1:0] = $out_cnt[4:3];
         
         // Counter bit output pipesignals
         $cnt0_out = ($out_cnt[4:2] == 3'd0) & $cnt_r[0];
         $cnt1_out = ($out_cnt[4:2] == 3'd0) & $cnt_r[1];
         $cnt2_out = ($out_cnt[4:2] == 3'd0) & $cnt_r[2];
         $cnt3_out = ($out_cnt[4:2] == 3'd0) & $cnt_r[3];
         $cnt7_out = ($out_cnt[4:2] == 3'd1) & $cnt_r[3];
         $cnt11_out = ($out_cnt[4:2] == 3'd2) & $cnt_r[3];
         $cnt12_out = ($out_cnt[4:2] == 3'd3) & $cnt_r[0];
         
         // Counter range output pipesignals
         $cnt0to3_out = ($out_cnt[4:2] == 3'd0);
         $cnt12to31_out = ($out_cnt[4] | ($out_cnt[3:2] == 2'b11));
         


         // Sequential logic migrated to TLV
         //ibus_cyc changes on three conditions.
         //1. i_rst is asserted. Together with the async gating above, o_ibus_cyc
         //   will be asserted as soon as the reset is released. This is how the
         //   first instruction is fetched
         //2. o_cnt_done and o_ctrl_pc_en are asserted. This means that SERV just
         //   finished updating the PC, is done with the current instruction and
         //   o_ibus_cyc gets asserted to fetch a new instruction
         //3. When i_ibus_ack, a new instruction is fetched and o_ibus_cyc gets
         //   deasserted to finish the transaction
         <<1$ibus_cyc = ($ibus_ack | *o_cnt_done | reset) ? (*o_ctrl_pc_en | reset) : $ibus_cyc;

         <<1$init_done = reset ? ((RESET_STRATEGY != "NONE") ? 1'b0 : $init_done) :
                         *o_cnt_done ? ($init_out & !$init_done) : $init_done;
         
         // Connect pipesignals to Verilog outputs
         *o_init = $init_out;
         *o_cnt_en = $o_cnt_en;
         *o_cnt0to3 = $cnt0to3_out;
         *o_cnt12to31 = $cnt12to31_out;
         *o_cnt0 = $cnt0_out;
         *o_cnt1 = $cnt1_out;
         *o_cnt2 = $cnt2_out;
         *o_cnt3 = $cnt3_out;
         *o_cnt7 = $cnt7_out;
         *o_cnt11 = $cnt11_out;
         *o_cnt12 = $cnt12_out;
         *o_cnt_done = $cnt_done_out;
         *o_ctrl_jump = $ctrl_jump;
         *o_ctrl_trap = $ctrl_trap_out;
         *o_mem_bytecnt = $mem_bytecnt_out;
         *o_ibus_cyc = $ibus_cyc_out;
         *o_rf_rreq = $rf_rreq_out;
         *o_rf_rd_en = $rf_rd_en_out;
         
         // Connect TLV signals to SV
         *init_done = $init_done;
         *last_init = $last_init;
         *trap_pending = $trap_pending;
         
         // Migrating assign statements to TLV
         *o_ctrl_pc_en = $o_cnt_en & !$init_out;
         *o_dbus_cyc = !$o_cnt_en & $init_done & *i_dbus_en & !*i_mem_misalign;
         *o_mdu_valid = MDU & !$o_cnt_en & $init_done & *i_mdu_op;
         *o_rf_wreq = (*i_shift_op & (*i_sh_right ? (*i_sh_done & ($last_init | (!$o_cnt_en & $init_done))) : $last_init)) |
                      *i_dbus_ack | (MDU & *i_mdu_ready) |
                      (*i_branch_op & ($last_init & !$trap_pending)) |
                      (*i_rd_alu_en & *i_alu_rd_sel1 & $last_init);


         // Migrated o_ctrl_jump sequential logic from SV_plus
         <<1$ctrl_jump = (reset && (RESET_STRATEGY != "NONE")) ? 1'b0 :
                          (*o_cnt_done) ? ($init_out & $take_branch) :
                          $ctrl_jump;  // retain previous value

         \SV_plus
            // Clock and reset signals for TL-Verilog convention
            wire clk = i_clk;
            wire reset = i_rst;
            

















            //valid signal for mdu


            //Prepare RF for writes when everything is ready to enter stage two
            // and the first stage didn't cause a misalign exception
            //Left shifts, SLT & Branch ops. First cycle after init
            //Right shift. o_sh_done
            //Mem ops. i_dbus_ack
            //MDU ops. i_mdu_ready




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

            // Counter implementation - sequential logic migrated to TLV scopes
            // Generate for loops no longer needed as TLV handles the scoping

            wire init_done;
            wire last_init;
            wire trap_pending;
            
            // Counter signals connected from TLV
            
            // Output assignments to match feved model structure
            // assign o_ctrl_pc_en - migrated to TLV
            // assign o_dbus_cyc - migrated to TLV
            // assign o_mdu_valid - migrated to TLV
            // assign o_rf_wreq - migrated to TLV
            assign o_bufreg_en = (o_cnt_en & (o_init | ((o_ctrl_trap | i_branch_op) & i_two_stage_op))) | (i_shift_op & init_done & (i_sh_right | i_sh_done));
            
            // Counter increment logic
            always @(posedge clk) begin
               $$out_cnt[4:2] <= (reset && (RESET_STRATEGY != "NONE")) ? 3'd0 : ($out_cnt[4:2] + $out_cnt_inc[2:0]);
            end







            // CSR misalign trap logic - sequential logic migrated to TLV scopes
            // Generate for loop no longer needed as TLV handles the scoping




\SV
endmodule
