\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
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
   |default
      @0
         *o_ready = *rgnt | *i_wreq;
         $wcnt[CMSB : 0] = *rcnt - 4;
         $wtrig0 = *rtrig1;
         m5_if_eq_block(m5_cond_ratio_2, 1, ['
         $wtrig1 = $wcnt[0];
         '], ['
         $wtrig1 = *wtrig0_r;
         '])
         $wreg[raw - 1 : 0] = $wtrig1 ? *i_wreg1 : *i_wreg0;
         *o_wdata = $wtrig1 ? *wdata1_r[width - 1 : 0] : *wdata0_r;
         m5_if_eq_block(m5_cond_width_32, 1, ['
         *o_waddr = $wreg;
         '], ['
         *o_waddr = {$wreg, $wcnt[CMSB : l2r]};
         '])
         *o_wen = ($wtrig0 & *wen0_r) | ($wtrig1 & *wen1_r);
         
         \SV_plus   // YOU ARE HERE
            localparam ratio = width / W;
            localparam CMSB = 4 - \$clog2(W); //Counter MSB
            localparam l2r  = \$clog2(ratio);

            reg                                    rgnt;
            reg [CMSB : 0]           rcnt;

            reg                   rtrig1;
            /*
             ********** Write side ***********
             */

            reg [width - 1 : 0]   wdata0_r;
            reg [width + W - 1 : 0]   wdata1_r;

            reg                      wen0_r;
            reg                      wen1_r;
            // Simplified from generate if (ratio == 2)
            // wtrig0_r relevant if (ratio != 2)
            reg wtrig0_r;
            always @(posedge clk) wtrig0_r <= $wtrig0;

            always @(posedge clk) begin
               wen0_r    <= $wcnt[0] ? i_wen0 : wen0_r;
               wen1_r    <= $wcnt[0] ? i_wen1 : wen1_r;

               wdata0_r  <= {i_wdata0, wdata0_r[width - 1 : W]};
               wdata1_r  <= {i_wdata1, wdata1_r[width + W - 1 : W]};

            end

            /*
             ********** Read side ***********
             */


            wire           rtrig0;

            wire [raw - 1 : 0] rreg = rtrig0 ? i_rreg1 : i_rreg0;
            // Simplified from generate if (width == 32)
            m5_if_eq_block(m5_cond_width_32, 1, ['
            assign o_raddr = rreg;
            '], ['
            assign o_raddr = {rreg, rcnt[CMSB : l2r]};
            '])

            reg [width - 1 : 0]  rdata0;
            reg [width - 1 - W : 0]  rdata1;

            reg                     rgate;

            assign o_rdata0 = rdata0[B : 0];
            assign o_rdata1 = rtrig1 ? i_rdata[B : 0] : rdata1[B : 0];

            assign rtrig0 = (rcnt[l2r - 1 : 0] == 1);

            // Simplified from generate if (ratio == 2)
            m5_if_eq_block(m5_cond_ratio_2, 1, ['
            assign o_ren = rgate;
            '], ['
            assign o_ren = rgate & (rcnt[l2r - 1 : 1] == 0);
            '])

            reg               rreq_r;

            m5_if_eq_block(m5_cond_ratio_2, 0, ['
            always @(posedge clk) begin
               // Combined assignment to eliminate split assignment
               rdata1 <= rtrig1 ? i_rdata[width - 1 : W] : {{W{1'b0}}, rdata1[width - W - 1 : W]};
            end
            '], ['
            always @(posedge clk) rdata1 <= rtrig1 ? i_rdata[W * 2 - 1 : W] : rdata1;
            '])

            always @(posedge clk) begin
               // Compound ternary expressions combining normal operation and reset
               rgate <= (reset && (reset_strategy != "NONE")) ? 1'b0 : 
                        (& rcnt | i_rreq) ? i_rreq : rgate;

               rtrig1 <= rtrig0;
               
               rcnt <= (reset && (reset_strategy != "NONE")) ? {CMSB + 1{1'b0}} :
                       (i_rreq | i_wreq) ? {{CMSB - 1{1'b0}}, i_wreq, 1'b0} : rcnt + {{CMSB{1'b0}}, 1'b1};

               rreq_r <= (reset && (reset_strategy != "NONE")) ? 1'b0 : i_rreq;
               
               rgnt <= (reset && (reset_strategy != "NONE")) ? 1'b0 : rreq_r;

               rdata0 <= rtrig0 ? i_rdata : {{W{1'b0}}, rdata0[width - 1 : W]};
            end

\SV
endmodule
