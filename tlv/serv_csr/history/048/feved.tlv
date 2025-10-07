\TLV_version 1d: tl-x.org
\SV
`default_nettype none
module serv_csr
  #(
    parameter RESET_STRATEGY = "MINI",
    parameter W = 1,
    parameter B = W-1
  )
  (
   input wire 	    i_clk,
   input wire 	    i_rst,
   //State
   input wire 	    i_trig_irq,
   input wire 	    i_en,
   input wire 	    i_cnt0to3,
   input wire 	    i_cnt3,
   input wire 	    i_cnt7,
   input wire 	    i_cnt11,
   input wire 	    i_cnt12,
   input wire 	    i_cnt_done,
   input wire 	    i_mem_op,
   input wire 	    i_mtip,
   input wire 	    i_trap,
   output reg 	    o_new_irq,
   //Control
   input wire 	    i_e_op,
   input wire 	    i_ebreak,
   input wire 	    i_mem_cmd,
   input wire 	    i_mstatus_en,
   input wire 	    i_mie_en,
   input wire 	    i_mcause_en,
   input wire [1:0] i_csr_source,
   input wire 	    i_mret,
   input wire 	    i_csr_d_sel,
   //Data
   input wire 	[B:0]    i_rf_csr_out,
   output wire 	[B:0]    o_csr_in,
   input wire 	[B:0]    i_csr_imm,
   input wire 	[B:0]    i_rs1,
   output wire 	[B:0]    o_q);

\TLV
   |default
      @0
         // === SV-TLV Interface: Connect Verilog Inputs ===
         $i_rst = *i_rst;
         $i_trig_irq = *i_trig_irq;
         $i_en = *i_en;
         $i_cnt0to3 = *i_cnt0to3;
         $i_cnt3 = *i_cnt3;
         $i_cnt7 = *i_cnt7;
         $i_cnt11 = *i_cnt11;
         $i_cnt12 = *i_cnt12;
         $i_cnt_done = *i_cnt_done;
         $i_mem_op = *i_mem_op;
         $i_mtip = *i_mtip;
         $i_trap = *i_trap;
         $i_e_op = *i_e_op;
         $i_ebreak = *i_ebreak;
         $i_mem_cmd = *i_mem_cmd;
         $i_mstatus_en = *i_mstatus_en;
         $i_mie_en = *i_mie_en;
         $i_mcause_en = *i_mcause_en;
         $i_csr_source[1:0] = *i_csr_source;
         $i_mret = *i_mret;
         $i_csr_d_sel = *i_csr_d_sel;
         $i_rf_csr_out[B:0] = *i_rf_csr_out;
         $i_csr_imm[B:0] = *i_csr_imm;
         $i_rs1[B:0] = *i_rs1;
         
         // === CSR Data Processing ===
         // Select between immediate and rs1 for CSR data input
         $csr_data[B:0] = $i_csr_d_sel ? $i_csr_imm : $i_rs1;
         
         // CSR input processing based on operation type (read/set/clear)
         $csr_in[B:0] = ($i_csr_source == CSR_SOURCE_EXT) ? $csr_data :
                        ($i_csr_source == CSR_SOURCE_SET) ? $csr_out | $csr_data :
                        ($i_csr_source == CSR_SOURCE_CLR) ? $csr_out & ~ $csr_data :
                        ($i_csr_source == CSR_SOURCE_CSR) ? $csr_out :
                        {W{1'bx}};

         // === CSR Register Readout ===
         // mstatus register readout (parameterized for different widths)
         $mstatus[B:0] = (W == 1) ? (($mstatus_mie & $i_cnt3) | ($i_cnt11 | $i_cnt12)) :
                         (W == 4) ? {$i_cnt11 | ($mstatus_mie & $i_cnt3), 2'b00, $i_cnt12} :
                         {W{1'b0}};  // Default case for other W values

         // mcause register readout (bits 3:0 and bit 31) - now fully TLV
         $mcause[B:0] = $i_cnt0to3 ? $mcause3dot0[B:0] : //[3:0] - fully converted to TLV array
                        $i_cnt_done ? {$mcause31, {B{1'b0}}} //[31]
                        : {W{1'b0}};

         // === Interrupt Logic ===
         // Timer interrupt generation
         $timer_irq = $i_mtip & $mstatus_mie & $mie_mtie;

         // === CSR Output Multiplexing ===
         // Combine all CSR register outputs
         $csr_out[B:0] = ({W{$i_mstatus_en & $i_en}} & $mstatus) |
                         $i_rf_csr_out |
                         ({W{$i_mcause_en & $i_en}} & $mcause);
                        
         // === Module Outputs ===
         $o_q[B:0] = $csr_out;
         $o_csr_in[B:0] = $csr_in;
         
         // === State Elements (Incremental Conversion to TLV) ===
         // Step 1: Convert timer_irq_r (simplest register with no dependencies)
         <<1$timer_irq_r = $i_trig_irq ? $timer_irq : $timer_irq_r;
         
         // Step 2: Convert mcause31 (simple register without explicit reset)
         <<1$mcause31 = ($i_mcause_en & $i_cnt_done | $i_trap) ? 
                        ($i_trap ? $o_new_irq_tlv : $csr_in[B]) : $mcause31;
                        
         // Step 3: Convert mstatus_mpie (simple register, no reset needed)
         <<1$mstatus_mpie = ($i_trap & $i_cnt_done) ? $mstatus_mie : $mstatus_mpie;
         
         // Step 4: Convert mstatus_mie (register with complex conditions)
         <<1$mstatus_mie = (($i_trap & $i_cnt_done) | $i_mstatus_en & $i_cnt3 & $i_en | $i_mret) ? 
                           (!$i_trap & ($i_mret ? $mstatus_mpie : $csr_in[B])) : $mstatus_mie;
         
         // Step 5: Convert o_new_irq with explicit reset handling
         // Use reset pipesignal in TLV logic to match original behavior
         <<1$o_new_irq_tlv = ($i_rst & (RESET_STRATEGY != "NONE")) ? 1'b0 :
                             $i_trig_irq ? ($timer_irq & !$timer_irq_r) : $o_new_irq_tlv;

         // Step 6: Convert mie_mtie with explicit reset handling
         <<1$mie_mtie = ($i_rst & (RESET_STRATEGY != "NONE")) ? 1'b0 :
                        ($i_mie_en & $i_cnt7) ? $csr_in[B] : $mie_mtie;

         // Step 7: Prepare mcause3dot0 conversion with common condition signal
         $mcause_update_en = $i_mcause_en & $i_en & $i_cnt0to3 | ($i_trap & $i_cnt_done);

         // Step 8: Convert mcause3dot0[0] to TLV pipesignal (now fully TLV)
         <<1$mcause3dot0_0 = $mcause_update_en ? 
                             ($o_new_irq_tlv | $i_e_op | (! $i_trap & ((W == 1) ? $mcause3dot0_1 : $csr_in[0]))) : $mcause3dot0_0;

         // Step 9: Convert mcause3dot0[1] to TLV pipesignal (now fully TLV)
         <<1$mcause3dot0_1 = $mcause_update_en ? 
                             ($o_new_irq_tlv | $i_e_op | ($i_mem_op & $i_mem_cmd) | (! $i_trap & ((W == 1) ? $mcause3dot0_2 : $csr_in[(W == 1) ? 0 : 1]))) : $mcause3dot0_1;

         // Step 10: Convert mcause3dot0[2] to TLV pipesignal (now fully TLV)
         <<1$mcause3dot0_2 = $mcause_update_en ? 
                             ($o_new_irq_tlv | $i_mem_op | (! $i_trap & ((W == 1) ? $mcause3dot0_3 : $csr_in[(W == 1) ? 0 : 2]))) : $mcause3dot0_2;

         // Step 11: Convert mcause3dot0[3] to TLV pipesignal (final bit)
         <<1$mcause3dot0_3 = $mcause_update_en ? 
                             (($i_e_op & ! $i_ebreak) | (! $i_trap & $csr_in[B])) : $mcause3dot0_3;

         // Step 12: Create clean TLV array from individual TLV pipesignals  
         $mcause3dot0[3:0] = {$mcause3dot0_3, $mcause3dot0_2, $mcause3dot0_1, $mcause3dot0_0};

         
         // === CSR Source Constants ===
         // Define CSR operation type constants  
         \SV_plus
            localparam [1:0]
              CSR_SOURCE_CSR = 2'b00,
              CSR_SOURCE_EXT = 2'b01,
              CSR_SOURCE_SET = 2'b10,
              CSR_SOURCE_CLR = 2'b11;

            // Clock and reset assignments for TL-Verilog
            wire clk = i_clk;
            wire reset = i_rst;

         // === Legacy Comments for Reference ===
         // All state logic has been successfully converted to TLV pipesignals above:
         // - timer_irq_r: Simple register conversion
         // - mcause31: Register with trap logic  
         // - mstatus_mpie: Complex register with multiple conditions
         // - mstatus_mie: Complex register with multiple conditions
         // - o_new_irq_tlv: Register with explicit reset handling
         // - mie_mtie: Register with explicit reset handling
         // - mcause3dot0[3:0]: Complex interdependent register array
         
         /*
          Original SystemVerilog behavior preserved in TLV:
          
          The mie bit in mstatus gets updated under three conditions:
          - When a trap is taken, the bit is cleared
          - During an mret instruction, the bit is restored from mpie
          - During a mstatus CSR access instruction it's assigned when bit 3 gets updated
          These conditions are all mutually exclusive
          
          Note: To save resources mstatus_mpie (mstatus bit 7) is not
          readable or writable from sw
          
          The four lowest bits in mcause hold the exception code:
          - During an mcause CSR access function, assigned when bits 0 to 3 get updated
          - During an external interrupt the exception code is set to 7 (timer interrupts only)
          - During an exception, the exception code indicates the cause:
            ebreak=3, ecall=11, misaligned load=4, misaligned store=6, misaligned jump=0
          
          Truth table for exception codes:
          irq  => 0111 (timer=7)
          e_op => x011 (ebreak=3, ecall=11)  
          mem  => 01x0 (store=6, load=4)
          ctrl => 0000 (jump=0)
          */
         
         // === SV-TLV Interface: Connect Verilog Outputs ===
         *o_new_irq = $o_new_irq_tlv;
         *o_csr_in = $o_csr_in;
         *o_q = $o_q;

\SV
endmodule
