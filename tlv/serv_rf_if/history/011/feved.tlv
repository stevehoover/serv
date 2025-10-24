\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
\SV
`default_nettype none
module serv_rf_if
  #(parameter WITH_CSR = 1,
    parameter W = 1,
    parameter B = W-1
  )
  (//RF Interface
   input wire                       i_cnt_en,
   output wire [4+WITH_CSR:0] o_wreg0,
   output wire [4+WITH_CSR:0] o_wreg1,
   output wire                       o_wen0,
   output wire                       o_wen1,
   output wire [B:0]  o_wdata0,
   output wire [B:0]  o_wdata1,
   output wire [4+WITH_CSR:0] o_rreg0,
   output wire [4+WITH_CSR:0] o_rreg1,
   input wire  [B:0] i_rdata0,
   input wire  [B:0] i_rdata1,

   //Trap interface
   input wire                       i_trap,
   input wire                       i_mret,
   input wire [B:0] i_mepc,
   input wire                      i_mtval_pc,
   input wire [B:0] i_bufreg_q,
   input wire [B:0] i_bad_pc,
   output wire [B:0] o_csr_pc,
   //CSR interface
   input wire                       i_csr_en,
   input wire [1:0]               i_csr_addr,
   input wire [B:0] i_csr,
   output wire [B:0] o_csr,
   //RD write port
   input wire                       i_rd_wen,
   input wire [4:0]               i_rd_waddr,
   input wire [B:0] i_ctrl_rd,
   input wire [B:0] i_alu_rd,
   input wire                       i_rd_alu_en,
   input wire [B:0] i_csr_rd,
   input wire                       i_rd_csr_en,
   input wire [B:0] i_mem_rd,
   input wire                       i_rd_mem_en,

   //RS1 read port
   input wire [4:0]               i_rs1_raddr,
   output wire [B:0] o_rs1,
   //RS2 read port
   input wire [4:0]               i_rs2_raddr,
   output wire [B:0] o_rs2);

\TLV
   |default
      @0
         // Connect Verilog inputs:
         $cnt_en = *i_cnt_en;
         $rdata0[B:0] = *i_rdata0;
         $rdata1[B:0] = *i_rdata1;
         $rd_wen_in = *i_rd_wen;
         $rd_waddr[4:0] = *i_rd_waddr;
         $ctrl_rd[B:0] = *i_ctrl_rd;
         $alu_rd[B:0] = *i_alu_rd;
         $rd_alu_en = *i_rd_alu_en;
         $mem_rd[B:0] = *i_mem_rd;
         $rd_mem_en = *i_rd_mem_en;
         $rs1_raddr[4:0] = *i_rs1_raddr;
         $rs2_raddr[4:0] = *i_rs2_raddr;
         
         m5_if_eq_block(m5_cond_with_csr, 1, ['
         // CSR-specific inputs (only when WITH_CSR=1)
         $trap = *i_trap;
         $mret = *i_mret;
         $mepc[B:0] = *i_mepc;
         $mtval_pc = *i_mtval_pc;
         $bufreg_q[B:0] = *i_bufreg_q;
         $bad_pc[B:0] = *i_bad_pc;
         $csr_en = *i_csr_en;
         $csr_addr[1:0] = *i_csr_addr;
         $csr[B:0] = *i_csr;
         $csr_rd[B:0] = *i_csr_rd;
         $rd_csr_en = *i_rd_csr_en;
         '])

         // Logic begins here:
         $rd_wen = $rd_wen_in & (\|$rd_waddr);

         m5_if_eq_block(m5_cond_with_csr, 1, ['
         // WITH_CSR logic
         $rd[B:0] =
             {W{$rd_alu_en}} & $alu_rd \|
             {W{$rd_csr_en}} & $csr_rd \|
             {W{$rd_mem_en}} & $mem_rd \|
                             $ctrl_rd;

         $mtval[B:0] = $mtval_pc ? $bad_pc : $bufreg_q;
         $sel_rs2 = !($trap \| $mret \| $csr_en);

         // Write side outputs
         $wdata0[B:0] = $trap ? $mtval : $rd;
         $wdata1[B:0] = $trap ? $mepc : $csr;
         $wreg0[4+WITH_CSR:0] = $trap ? {6'b100011} : {1'b0, $rd_waddr};
         $wreg1[4+WITH_CSR:0] = $trap ? {6'b100010} : {4'b1000, $csr_addr};
         $wen0 = $cnt_en & ($trap \| $rd_wen);
         $wen1 = $cnt_en & ($trap \| $csr_en);

         // Read side outputs  
         $rreg0[4+WITH_CSR:0] = {1'b0, $rs1_raddr};
         $rreg1[4+WITH_CSR:0] = {~$sel_rs2,
                                 $rs2_raddr[4:2] & {3{$sel_rs2}},
                                 {1'b0,$trap} \| {$mret,1'b0} \| ({2{$csr_en}} & $csr_addr) \| ({2{$sel_rs2}} & $rs2_raddr[1:0])};
         $csr_out[B:0] = $rdata1 & {W{$csr_en}};
         $csr_pc_out[B:0] = $rdata1;
         '], ['
         // NO_CSR logic
         $rd[B:0] = $ctrl_rd \|
             $alu_rd & {W{$rd_alu_en}} \|
             $mem_rd & {W{$rd_mem_en}};

         // Write side outputs
         $wdata0[B:0] = $rd;
         $wdata1[B:0] = {W{1'b0}};
         $wreg0[4+WITH_CSR:0] = $rd_waddr;
         $wreg1[4+WITH_CSR:0] = 5'd0;
         $wen0 = $cnt_en & $rd_wen;
         $wen1 = 1'b0;

         // Read side outputs
         $rreg0[4+WITH_CSR:0] = $rs1_raddr;
         $rreg1[4+WITH_CSR:0] = $rs2_raddr;
         $csr_out[B:0] = {W{1'b0}};
         $csr_pc_out[B:0] = {W{1'b0}};
         '])

         // Common outputs
         $rs1_out[B:0] = $rdata0;
         $rs2_out[B:0] = $rdata1;

         // Connect Verilog outputs:
         *o_wreg0 = $wreg0;
         *o_wreg1 = $wreg1;
         *o_wen0 = $wen0;
         *o_wen1 = $wen1;
         *o_wdata0 = $wdata0;
         *o_wdata1 = $wdata1;
         *o_rreg0 = $rreg0;
         *o_rreg1 = $rreg1;
         *o_rs1 = $rs1_out;
         *o_rs2 = $rs2_out;
         *o_csr = $csr_out;
         *o_csr_pc = $csr_pc_out;

\SV
endmodule