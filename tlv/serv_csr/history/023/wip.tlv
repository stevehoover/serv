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
         // TLV expressions converted from assign statements
         $dd[B:0] = *i_csr_d_sel ? *i_csr_imm : *i_rs1;
         
         $csr_in[B:0] = (*i_csr_source == CSR_SOURCE_EXT) ? $dd :
                        (*i_csr_source == CSR_SOURCE_SET) ? $csr_out | $dd :
                        (*i_csr_source == CSR_SOURCE_CLR) ? $csr_out & ~ $dd :
                        (*i_csr_source == CSR_SOURCE_CSR) ? $csr_out :
                        {W{1'bx}};

         $mstatus[B:0] = (W == 1) ? ((*mstatus_mie & *i_cnt3) | (*i_cnt11 | *i_cnt12)) :
                         (W == 4) ? {*i_cnt11 | (*mstatus_mie & *i_cnt3), 2'b00, *i_cnt12} :
                         {W{1'b0}};  // Default case for other W values

         $csr_out[B:0] = ({W{*i_mstatus_en & *i_en}} & $mstatus) |
                         *i_rf_csr_out |
                         ({W{*i_mcause_en & *i_en}} & $mcause);

         *o_q = $csr_out;

         $timer_irq = *i_mtip & *mstatus_mie & *mie_mtie;

         $mcause[B:0] = *i_cnt0to3 ? *mcause3dot0[B:0] : //[3:0]
                        *i_cnt_done ? {*mcause31, {B{1'b0}}} //[31]
                        : {W{1'b0}};

         *o_csr_in = $csr_in;
         
         \SV_plus
            localparam [1:0]
              CSR_SOURCE_CSR = 2'b00,
              CSR_SOURCE_EXT = 2'b01,
              CSR_SOURCE_SET = 2'b10,
              CSR_SOURCE_CLR = 2'b11;

            reg               mstatus_mie;
            reg               mstatus_mpie;
            reg               mie_mtie;

            reg               mcause31;
            reg [3:0]         mcause3dot0;
            // CSR updates

            reg               timer_irq_r;

            // Clock and reset assignments for TL-Verilog
            wire clk = i_clk;
            wire reset = i_rst;

            always @(posedge clk) begin
               timer_irq_r <= i_trig_irq ? $timer_irq : timer_irq_r;
               o_new_irq <= (reset & RESET_STRATEGY != "NONE") ? 1'b0 :
                            i_trig_irq ? ($timer_irq & ! timer_irq_r) : 
                            o_new_irq;

               mie_mtie <= (reset & RESET_STRATEGY != "NONE") ? 1'b0 :
                           (i_mie_en & i_cnt7) ? $csr_in[B] : 
                           mie_mtie;

               /*
                The mie bit in mstatus gets updated under three conditions

                When a trap is taken, the bit is cleared
                During an mret instruction, the bit is restored from mpie
                During a mstatus CSR access instruction it's assigned when
                 bit 3 gets updated

                These conditions are all mutually exclusive
                */
               mstatus_mie <= ((i_trap & i_cnt_done) | i_mstatus_en & i_cnt3 & i_en | i_mret) ? 
                              (! i_trap & (i_mret ?  mstatus_mpie : $csr_in[B])) : mstatus_mie;

               /*
                Note: To save resources mstatus_mpie (mstatus bit 7) is not
                readable or writable from sw
                */
               mstatus_mpie <= (i_trap & i_cnt_done) ? mstatus_mie : mstatus_mpie;

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
               mcause3dot0[3] <= (i_mcause_en & i_en & i_cnt0to3 | (i_trap & i_cnt_done)) ? 
                                 ((i_e_op & ! i_ebreak) | (! i_trap & $csr_in[B])) : mcause3dot0[3];
               mcause3dot0[2] <= (i_mcause_en & i_en & i_cnt0to3 | (i_trap & i_cnt_done)) ? 
                                 (o_new_irq | i_mem_op | (! i_trap & ((W == 1) ? mcause3dot0[3] : $csr_in[(W == 1) ? 0 : 2]))) : mcause3dot0[2];
               mcause3dot0[1] <= (i_mcause_en & i_en & i_cnt0to3 | (i_trap & i_cnt_done)) ? 
                                 (o_new_irq | i_e_op | (i_mem_op & i_mem_cmd) | (! i_trap & ((W == 1) ? mcause3dot0[2] : $csr_in[(W == 1) ? 0 : 1]))) : mcause3dot0[1];
               mcause3dot0[0] <= (i_mcause_en & i_en & i_cnt0to3 | (i_trap & i_cnt_done)) ? 
                                 (o_new_irq | i_e_op | (! i_trap & ((W == 1) ? mcause3dot0[1] : $csr_in[0]))) : mcause3dot0[0];
               mcause31 <= (i_mcause_en & i_cnt_done | i_trap) ? 
                           (i_trap ? o_new_irq : $csr_in[B]) : mcause31;

            end

\SV
endmodule
