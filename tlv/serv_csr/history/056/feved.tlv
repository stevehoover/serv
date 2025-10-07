\m5_TLV_version 1d: tl-x.org
\m5
use(m5-1.0)

// The guts of serv_csr module - TL-Verilog implementation  
\TLV serv_csr(/_top)
   |default
      @0
         // === Combinational Logic ===
         
         // CSR data input selection 
         $csr_data[B:0] = $i_csr_d_sel ? $i_csr_imm : $i_rs1;
         
         // CSR input processing based on operation type
         $csr_in[B:0] = ($i_csr_source == CSR_SOURCE_EXT) ? $csr_data :
                        ($i_csr_source == CSR_SOURCE_SET) ? $csr_out | $csr_data :
                        ($i_csr_source == CSR_SOURCE_CLR) ? $csr_out & ~ $csr_data :
                        ($i_csr_source == CSR_SOURCE_CSR) ? $csr_out :
                        {W{1'bx}};

         // MSTATUS register readout (parameterized for different widths)
         $mstatus[B:0] = (W == 1) ? (($mstatus_mie & $i_cnt3) | ($i_cnt11 | $i_cnt12)) :
                         (W == 4) ? {$i_cnt11 | ($mstatus_mie & $i_cnt3), 2'b00, $i_cnt12} :
                         {W{1'b0}};

         // Timer interrupt signal
         $timer_irq = $i_mtip & $mstatus_mie & $mie_mtie;

         // MCAUSE register readout
         $mcause[B:0] = $i_cnt0to3 ? $mcause3dot0[B:0] :    //[3:0]
                        $i_cnt_done ? {$mcause31, {B{1'b0}}} : //[31]
                        {W{1'b0}};

         // CSR output multiplexing
         $csr_out[B:0] = ({W{$i_mstatus_en & $i_en}} & $mstatus) |
                         $i_rf_csr_out |
                         ({W{$i_mcause_en & $i_en}} & $mcause);

         // Module outputs
         $o_q[B:0] = $csr_out;
         $o_csr_in[B:0] = $csr_in;

         // Combine individual mcause bits into array format
         $mcause3dot0[3:0] = {$mcause3dot0_3, $mcause3dot0_2, $mcause3dot0_1, $mcause3dot0_0};

         // === State Register Updates ===
         
         // Timer interrupt tracking
         <<1$timer_irq_r = $i_trig_irq ? $timer_irq : $timer_irq_r;
         <<1$o_new_irq_tlv = ($i_rst & (RESET_STRATEGY != "NONE")) ? 1'b0 :
                             $i_trig_irq ? ($timer_irq & !$timer_irq_r) : $o_new_irq_tlv;

         // MIE register update
         <<1$mie_mtie = ($i_rst & (RESET_STRATEGY != "NONE")) ? 1'b0 :
                        ($i_mie_en & $i_cnt7) ? $csr_in[B] : $mie_mtie;

         /*
          The mie bit in mstatus gets updated under three conditions
          
          When a trap is taken, the bit is cleared
          During an mret instruction, the bit is restored from mpie
          During a mstatus CSR access instruction it's assigned when
           bit 3 gets updated
          
          These conditions are all mutually exclusive
          */
         <<1$mstatus_mie = (($i_trap & $i_cnt_done) | $i_mstatus_en & $i_cnt3 & $i_en | $i_mret) ? 
                           (!$i_trap & ($i_mret ? $mstatus_mpie : $csr_in[B])) : $mstatus_mie;

         /*
          Note: To save resources mstatus_mpie (mstatus bit 7) is not
          readable or writable from sw
          */
         <<1$mstatus_mpie = ($i_trap & $i_cnt_done) ? $mstatus_mie : $mstatus_mpie;

         /*
          The four lowest bits in mcause hold the exception code
          
          These bits get updated under three conditions
          
          During an mcause CSR access function, they are assigned when
          bits 0 to 3 gets updated
          
          During an external interrupt the exception code is set to
          7, since SERV only support timer interrupts
          
          During an exception, the exception code is assigned to indicate
          if it was caused by an ebreak instruction (3),
          ecall instruction (11), misaligned load (4), misaligned store (6)
          or misaligned jump (0)
          
          The expressions below are derived from the following truth table
          irq  => 0111 (timer=7)
          e_op => x011 (ebreak=3, ecall=11)
          mem  => 01x0 (store=6, load=4)
          ctrl => 0000 (jump=0)
          */
         $mcause_update_en = $i_mcause_en & $i_en & $i_cnt0to3 | ($i_trap & $i_cnt_done);
         <<1$mcause3dot0_3 = $mcause_update_en ? (($i_e_op & !$i_ebreak) | (!$i_trap & $csr_in[B])) : $mcause3dot0_3;
         <<1$mcause3dot0_2 = $mcause_update_en ? ($o_new_irq_tlv | $i_mem_op | (!$i_trap & ((W == 1) ? $mcause3dot0_3 : $csr_in[(W == 1) ? 0 : 2]))) : $mcause3dot0_2;
         <<1$mcause3dot0_1 = $mcause_update_en ? ($o_new_irq_tlv | $i_e_op | ($i_mem_op & $i_mem_cmd) | (!$i_trap & ((W == 1) ? $mcause3dot0_2 : $csr_in[(W == 1) ? 0 : 1]))) : $mcause3dot0_1;
         <<1$mcause3dot0_0 = $mcause_update_en ? ($o_new_irq_tlv | $i_e_op | (!$i_trap & ((W == 1) ? $mcause3dot0_1 : $csr_in[0]))) : $mcause3dot0_0;

         <<1$mcause31 = ($i_mcause_en & $i_cnt_done | $i_trap) ? 
                        ($i_trap ? $o_new_irq_tlv : $csr_in[B]) : $mcause31;

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
   // Connect Verilog inputs to pipesignals
   |default
      @0
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

   // CSR Source Constants
   \SV_plus
      localparam [1:0]
        CSR_SOURCE_CSR = 2'b00,
        CSR_SOURCE_EXT = 2'b01,
        CSR_SOURCE_SET = 2'b10,
        CSR_SOURCE_CLR = 2'b11;

      // Clock and reset assignments for TL-Verilog
      wire clk = i_clk;
      wire reset = i_rst;
         
   // Instantiate the serv_csr macro
   m5+serv_csr(/top)
   
   // Connect pipesignals to Verilog outputs
   |default
      @0
         *o_new_irq = $o_new_irq_tlv;
         *o_csr_in = $o_csr_in;
         *o_q = $o_q;

\SV
endmodule
