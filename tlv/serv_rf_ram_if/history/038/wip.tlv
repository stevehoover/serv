\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)

// The guts of module serv_rf_ram_if.
\TLV serv_rf_ram_if(/_top)
   |default
      @0
         \SV_plus
            localparam ratio = width / W;
            localparam CMSB = 4 - \$clog2(W); //Counter MSB
            localparam l2r  = \$clog2(ratio);

         /*
          ********** Write side ***********
          */
         
         $wcnt[CMSB : 0] = $rcnt - 4;
         $wtrig0 = $rtrig1;
         
         m5_if_eq_block(m5_cond_ratio_2, 1, ['
         $wtrig1 = $wcnt[0];
         '], ['
         $wtrig1 = $wtrig0_r;
         '])
         
         $o_wdata[width - 1 : 0] = $wtrig1 ? $wdata1_r[width - 1 : 0] : $wdata0_r;
         
         $wreg[raw - 1 : 0] = $wtrig1 ? $wreg1 : $wreg0;
         m5_if_eq_block(m5_cond_width_32, 1, ['
         $o_waddr[aw - 1 : 0] = $wreg;
         '], ['
         $o_waddr[aw - 1 : 0] = {$wreg, $wcnt[CMSB : l2r]};
         '])
         
         $o_wen = ($wtrig0 & $wen0_r) | ($wtrig1 & $wen1_r);
         
         m5_if_eq_block(m5_cond_ratio_2, 1, [''], ['
         <<1$wtrig0_r = $wtrig0;
         '])
         <<1$wen0_r = $wcnt[0] ? $wen0 : $wen0_r;
         <<1$wen1_r = $wcnt[0] ? $wen1 : $wen1_r;
         <<1$wdata0_r[width - 1 : 0] = {$wdata0, $wdata0_r[width - 1 : W]};
         <<1$wdata1_r[width + W - 1 : 0] = {$wdata1, $wdata1_r[width + W - 1 : W]};
         
         /*
          ********** Read side ***********
          */
          
         $rtrig0 = ($rcnt[l2r - 1 : 0] == 1);
         
         $rreg[raw - 1 : 0] = $rtrig0 ? $rreg1 : $rreg0;
         m5_if_eq_block(m5_cond_width_32, 1, ['
         $o_raddr[aw - 1 : 0] = $rreg;
         '], ['
         $o_raddr[aw - 1 : 0] = {$rreg, $rcnt[CMSB : l2r]};
         '])
         
         $o_rdata0[B : 0] = $rdata0[B : 0];
         $o_rdata1[B : 0] = $rtrig1 ? $rdata[B : 0] : $rdata1[B : 0];
         
         m5_if_eq_block(m5_cond_ratio_2, 1, ['
         $o_ren = $rgate;
         '], ['
         $o_ren = $rgate & ($rcnt[l2r - 1 : 1] == 0);
         '])
         
         $o_ready = $rgnt | $wreq;
         
         m5_if_eq_block(m5_cond_ratio_2, 0, ['
         <<1$rdata1[width - 1 - W : 0] = $rtrig1 ? $rdata[width - 1 : W] : {{W{1'b0}}, $rdata1[width - W - 1 : W]};
         '], ['
         <<1$rdata1[width - 1 - W : 0] = $rtrig1 ? $rdata[W * 2 - 1 : W] : $rdata1;
         '])
         
         <<1$rtrig1 = $rtrig0;
         <<1$rreq_r = (reset && (reset_strategy != "NONE")) ? 1'b0 : $rreq;
         <<1$rgnt = (reset && (reset_strategy != "NONE")) ? 1'b0 : $rreq_r;
         <<1$rdata0[width - 1 : 0] = $rtrig0 ? $rdata : {{W{1'b0}}, $rdata0[width - 1 : W]};
         <<1$rcnt[CMSB : 0] = (reset && (reset_strategy != "NONE")) ? {CMSB + 1{1'b0}} :
                              ($rreq | $wreq) ? {{CMSB - 1{1'b0}}, $wreq, 1'b0} : $rcnt + {{CMSB{1'b0}}, 1'b1};
         <<1$rgate = (reset && (reset_strategy != "NONE")) ? 1'b0 : 
                     (& $rcnt | $rreq) ? $rreq : $rgate;

\SV
`default_nettype none
module serv_rf_ram_if
  #(//Data width. Adjust to preferred width of SRAM data interface
    parameter width=8,

    parameter W = 1,
    //Select reset strategy.
    // "MINI" for resetting minimally required FFs
    // "NONE" for relying on FFs having a defined value on startup
    parameter reset_strategy="MINI",

    //Number of CSR registers. These are allocated after the normal
    // GPR registers in the RAM.
    parameter csr_regs=4,

    //Internal parameters calculated from above values. Do not change
    parameter B=W-1,
    parameter raw=$clog2(32+csr_regs), //Register address width
    parameter l2w=$clog2(width), //log2 of width
    parameter aw=5+raw-l2w) //Address width
  (
   //SERV side
   input wire                   i_clk,
   input wire                   i_rst,
   input wire                   i_wreq,
   input wire                   i_rreq,
   output wire                   o_ready,
   input wire [raw-1:0]           i_wreg0,
   input wire [raw-1:0]           i_wreg1,
   input wire                   i_wen0,
   input wire                   i_wen1,
   input wire [B:0]           i_wdata0,
   input wire [B:0]           i_wdata1,
   input wire [raw-1:0]           i_rreg0,
   input wire [raw-1:0]           i_rreg1,
   output wire [B:0]           o_rdata0,
   output wire [B:0]           o_rdata1,
   //RAM side
   output wire [aw-1:0]           o_waddr,
   output wire [width-1:0] o_wdata,
   output wire                   o_wen,
   output wire [aw-1:0]           o_raddr,
   output wire                   o_ren,
   input wire [width-1:0]  i_rdata);

   // Clock and reset signals for TL-Verilog
   wire clk;
   wire reset;
   assign clk = i_clk;
   assign reset = i_rst;

\TLV
   // Connect Verilog inputs:
   |default
      @0
         $wreq = *i_wreq;
         $wreg1[raw - 1 : 0] = *i_wreg1;
         $wreg0[raw - 1 : 0] = *i_wreg0;
         $wen0 = *i_wen0;
         $wen1 = *i_wen1;
         $wdata0[B : 0] = *i_wdata0;
         $wdata1[B : 0] = *i_wdata1;
         $rreg1[raw - 1 : 0] = *i_rreg1;
         $rreg0[raw - 1 : 0] = *i_rreg0;
         $rdata[width - 1 : 0] = *i_rdata;
         $rreq = *i_rreq;
   m5+serv_rf_ram_if(/top)
   // Connect Verilog outputs:
   |default
      @0
         *o_ready = $o_ready;
         *o_wdata = $o_wdata;
         *o_waddr = $o_waddr;
         *o_wen = $o_wen;
         *o_raddr = $o_raddr;
         *o_rdata0 = $o_rdata0;
         *o_rdata1 = $o_rdata1;
         *o_ren = $o_ren;

\SV
endmodule
