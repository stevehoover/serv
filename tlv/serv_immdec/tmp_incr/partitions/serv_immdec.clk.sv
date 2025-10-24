module miter (
  input  [  0:0] \__pi_i_clk ,
  input  [  0:0] \__pi_i_cnt_done ,
  input  [  0:0] \__pi_i_cnt_en ,
  input  [  0:0] \__pi_i_csr_imm_en ,
  input  [  3:0] \__pi_i_ctrl ,
  input  [  3:0] \__pi_i_immdec_en ,
  input  [  0:0] \__pi_i_wb_en ,
  input  [ 24:0] \__pi_i_wb_rdt ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [  0:0] \__po_clk__gold ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].imm31__gold ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].imm7__gold ,
  output [  4:0] \__po_gen_immdec_w_eq1[0].imm_b11_b7__gold ,
  output [  8:0] \__po_gen_immdec_w_eq1[0].imm_b19_b12_b20__gold ,
  output [  4:0] \__po_gen_immdec_w_eq1[0].imm_b24_b20__gold ,
  output [  5:0] \__po_gen_immdec_w_eq1[0].imm_b30_b25__gold ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].signbit__gold ,
  output [  0:0] \__po_o_csr_imm__gold ,
  output [  0:0] \__po_o_imm__gold ,
  output [  4:0] \__po_o_rd_addr__gold ,
  output [  4:0] \__po_o_rs1_addr__gold ,
  output [  4:0] \__po_o_rs2_addr__gold ,
  output [  0:0] \__po_clk__gate ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].imm31__gate ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].imm7__gate ,
  output [  4:0] \__po_gen_immdec_w_eq1[0].imm_b11_b7__gate ,
  output [  8:0] \__po_gen_immdec_w_eq1[0].imm_b19_b12_b20__gate ,
  output [  4:0] \__po_gen_immdec_w_eq1[0].imm_b24_b20__gate ,
  output [  5:0] \__po_gen_immdec_w_eq1[0].imm_b30_b25__gate ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].signbit__gate ,
  output [  0:0] \__po_o_csr_imm__gate ,
  output [  0:0] \__po_o_imm__gate ,
  output [  4:0] \__po_o_rd_addr__gate ,
  output [  4:0] \__po_o_rs1_addr__gate ,
  output [  4:0] \__po_o_rs2_addr__gate
);
  \gold.serv_immdec.clk gold (
    .\__pi_i_clk (\__pi_i_clk ),
    .\__pi_i_cnt_done (\__pi_i_cnt_done ),
    .\__pi_i_cnt_en (\__pi_i_cnt_en ),
    .\__pi_i_csr_imm_en (\__pi_i_csr_imm_en ),
    .\__pi_i_ctrl (\__pi_i_ctrl ),
    .\__pi_i_immdec_en (\__pi_i_immdec_en ),
    .\__pi_i_wb_en (\__pi_i_wb_en ),
    .\__pi_i_wb_rdt (\__pi_i_wb_rdt ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_clk (\__po_clk__gold ),
    .\__po_gen_immdec_w_eq1[0].imm31 (\__po_gen_immdec_w_eq1[0].imm31__gold ),
    .\__po_gen_immdec_w_eq1[0].imm7 (\__po_gen_immdec_w_eq1[0].imm7__gold ),
    .\__po_gen_immdec_w_eq1[0].imm_b11_b7 (\__po_gen_immdec_w_eq1[0].imm_b11_b7__gold ),
    .\__po_gen_immdec_w_eq1[0].imm_b19_b12_b20 (\__po_gen_immdec_w_eq1[0].imm_b19_b12_b20__gold ),
    .\__po_gen_immdec_w_eq1[0].imm_b24_b20 (\__po_gen_immdec_w_eq1[0].imm_b24_b20__gold ),
    .\__po_gen_immdec_w_eq1[0].imm_b30_b25 (\__po_gen_immdec_w_eq1[0].imm_b30_b25__gold ),
    .\__po_gen_immdec_w_eq1[0].signbit (\__po_gen_immdec_w_eq1[0].signbit__gold ),
    .\__po_o_csr_imm (\__po_o_csr_imm__gold ),
    .\__po_o_imm (\__po_o_imm__gold ),
    .\__po_o_rd_addr (\__po_o_rd_addr__gold ),
    .\__po_o_rs1_addr (\__po_o_rs1_addr__gold ),
    .\__po_o_rs2_addr (\__po_o_rs2_addr__gold )
  );
  \gate.serv_immdec.clk gate (
    .\__pi_i_clk (\__pi_i_clk ),
    .\__pi_i_cnt_done (\__pi_i_cnt_done ),
    .\__pi_i_cnt_en (\__pi_i_cnt_en ),
    .\__pi_i_csr_imm_en (\__pi_i_csr_imm_en ),
    .\__pi_i_ctrl (\__pi_i_ctrl ),
    .\__pi_i_immdec_en (\__pi_i_immdec_en ),
    .\__pi_i_wb_en (\__pi_i_wb_en ),
    .\__pi_i_wb_rdt (\__pi_i_wb_rdt ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_clk (\__po_clk__gate ),
    .\__po_gen_immdec_w_eq1[0].imm31 (\__po_gen_immdec_w_eq1[0].imm31__gate ),
    .\__po_gen_immdec_w_eq1[0].imm7 (\__po_gen_immdec_w_eq1[0].imm7__gate ),
    .\__po_gen_immdec_w_eq1[0].imm_b11_b7 (\__po_gen_immdec_w_eq1[0].imm_b11_b7__gate ),
    .\__po_gen_immdec_w_eq1[0].imm_b19_b12_b20 (\__po_gen_immdec_w_eq1[0].imm_b19_b12_b20__gate ),
    .\__po_gen_immdec_w_eq1[0].imm_b24_b20 (\__po_gen_immdec_w_eq1[0].imm_b24_b20__gate ),
    .\__po_gen_immdec_w_eq1[0].imm_b30_b25 (\__po_gen_immdec_w_eq1[0].imm_b30_b25__gate ),
    .\__po_gen_immdec_w_eq1[0].signbit (\__po_gen_immdec_w_eq1[0].signbit__gate ),
    .\__po_o_csr_imm (\__po_o_csr_imm__gate ),
    .\__po_o_imm (\__po_o_imm__gate ),
    .\__po_o_rd_addr (\__po_o_rd_addr__gate ),
    .\__po_o_rs1_addr (\__po_o_rs1_addr__gate ),
    .\__po_o_rs2_addr (\__po_o_rs2_addr__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_i_clk__assume (\__pi_i_clk );
  miter_def_prop #(1, "assume") \__pi_i_cnt_done__assume (\__pi_i_cnt_done );
  miter_def_prop #(1, "assume") \__pi_i_cnt_en__assume (\__pi_i_cnt_en );
  miter_def_prop #(1, "assume") \__pi_i_csr_imm_en__assume (\__pi_i_csr_imm_en );
  miter_def_prop #(4, "assume") \__pi_i_ctrl__assume (\__pi_i_ctrl );
  miter_def_prop #(4, "assume") \__pi_i_immdec_en__assume (\__pi_i_immdec_en );
  miter_def_prop #(1, "assume") \__pi_i_wb_en__assume (\__pi_i_wb_en );
  miter_def_prop #(25, "assume") \__pi_i_wb_rdt__assume (\__pi_i_wb_rdt );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(1, "assert") \__po_clk__assert (\__po_clk__gold , \__po_clk__gate );
  miter_cmp_prop #(1, "assert") \__po_gen_immdec_w_eq1[0].imm31__assert (\__po_gen_immdec_w_eq1[0].imm31__gold , \__po_gen_immdec_w_eq1[0].imm31__gate );
  miter_cmp_prop #(1, "assert") \__po_gen_immdec_w_eq1[0].imm7__assert (\__po_gen_immdec_w_eq1[0].imm7__gold , \__po_gen_immdec_w_eq1[0].imm7__gate );
  miter_cmp_prop #(5, "assert") \__po_gen_immdec_w_eq1[0].imm_b11_b7__assert (\__po_gen_immdec_w_eq1[0].imm_b11_b7__gold , \__po_gen_immdec_w_eq1[0].imm_b11_b7__gate );
  miter_cmp_prop #(9, "assert") \__po_gen_immdec_w_eq1[0].imm_b19_b12_b20__assert (\__po_gen_immdec_w_eq1[0].imm_b19_b12_b20__gold , \__po_gen_immdec_w_eq1[0].imm_b19_b12_b20__gate );
  miter_cmp_prop #(5, "assert") \__po_gen_immdec_w_eq1[0].imm_b24_b20__assert (\__po_gen_immdec_w_eq1[0].imm_b24_b20__gold , \__po_gen_immdec_w_eq1[0].imm_b24_b20__gate );
  miter_cmp_prop #(6, "assert") \__po_gen_immdec_w_eq1[0].imm_b30_b25__assert (\__po_gen_immdec_w_eq1[0].imm_b30_b25__gold , \__po_gen_immdec_w_eq1[0].imm_b30_b25__gate );
  miter_cmp_prop #(1, "assert") \__po_gen_immdec_w_eq1[0].signbit__assert (\__po_gen_immdec_w_eq1[0].signbit__gold , \__po_gen_immdec_w_eq1[0].signbit__gate );
  miter_cmp_prop #(1, "assert") \__po_o_csr_imm__assert (\__po_o_csr_imm__gold , \__po_o_csr_imm__gate );
  miter_cmp_prop #(1, "assert") \__po_o_imm__assert (\__po_o_imm__gold , \__po_o_imm__gate );
  miter_cmp_prop #(5, "assert") \__po_o_rd_addr__assert (\__po_o_rd_addr__gold , \__po_o_rd_addr__gate );
  miter_cmp_prop #(5, "assert") \__po_o_rs1_addr__assert (\__po_o_rs1_addr__gold , \__po_o_rs1_addr__gate );
  miter_cmp_prop #(5, "assert") \__po_o_rs2_addr__assert (\__po_o_rs2_addr__gold , \__po_o_rs2_addr__gate );
`endif
`ifdef COVER_DEF_CROSS_POINTS
  `ifdef DIRECT_CROSS_POINTS
  `else
  `endif
`endif
`ifdef COVER_DEF_GOLD_MATCH_POINTS
`endif
`ifdef COVER_DEF_GATE_MATCH_POINTS
`endif
`ifdef COVER_DEF_GOLD_OUTPUTS
  miter_def_prop #(1, "cover") \__po_clk__gold_cover (\__po_clk__gold );
  miter_def_prop #(1, "cover") \__po_gen_immdec_w_eq1[0].imm31__gold_cover (\__po_gen_immdec_w_eq1[0].imm31__gold );
  miter_def_prop #(1, "cover") \__po_gen_immdec_w_eq1[0].imm7__gold_cover (\__po_gen_immdec_w_eq1[0].imm7__gold );
  miter_def_prop #(5, "cover") \__po_gen_immdec_w_eq1[0].imm_b11_b7__gold_cover (\__po_gen_immdec_w_eq1[0].imm_b11_b7__gold );
  miter_def_prop #(9, "cover") \__po_gen_immdec_w_eq1[0].imm_b19_b12_b20__gold_cover (\__po_gen_immdec_w_eq1[0].imm_b19_b12_b20__gold );
  miter_def_prop #(5, "cover") \__po_gen_immdec_w_eq1[0].imm_b24_b20__gold_cover (\__po_gen_immdec_w_eq1[0].imm_b24_b20__gold );
  miter_def_prop #(6, "cover") \__po_gen_immdec_w_eq1[0].imm_b30_b25__gold_cover (\__po_gen_immdec_w_eq1[0].imm_b30_b25__gold );
  miter_def_prop #(1, "cover") \__po_gen_immdec_w_eq1[0].signbit__gold_cover (\__po_gen_immdec_w_eq1[0].signbit__gold );
  miter_def_prop #(1, "cover") \__po_o_csr_imm__gold_cover (\__po_o_csr_imm__gold );
  miter_def_prop #(1, "cover") \__po_o_imm__gold_cover (\__po_o_imm__gold );
  miter_def_prop #(5, "cover") \__po_o_rd_addr__gold_cover (\__po_o_rd_addr__gold );
  miter_def_prop #(5, "cover") \__po_o_rs1_addr__gold_cover (\__po_o_rs1_addr__gold );
  miter_def_prop #(5, "cover") \__po_o_rs2_addr__gold_cover (\__po_o_rs2_addr__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(1, "cover") \__po_clk__gate_cover (\__po_clk__gate );
  miter_def_prop #(1, "cover") \__po_gen_immdec_w_eq1[0].imm31__gate_cover (\__po_gen_immdec_w_eq1[0].imm31__gate );
  miter_def_prop #(1, "cover") \__po_gen_immdec_w_eq1[0].imm7__gate_cover (\__po_gen_immdec_w_eq1[0].imm7__gate );
  miter_def_prop #(5, "cover") \__po_gen_immdec_w_eq1[0].imm_b11_b7__gate_cover (\__po_gen_immdec_w_eq1[0].imm_b11_b7__gate );
  miter_def_prop #(9, "cover") \__po_gen_immdec_w_eq1[0].imm_b19_b12_b20__gate_cover (\__po_gen_immdec_w_eq1[0].imm_b19_b12_b20__gate );
  miter_def_prop #(5, "cover") \__po_gen_immdec_w_eq1[0].imm_b24_b20__gate_cover (\__po_gen_immdec_w_eq1[0].imm_b24_b20__gate );
  miter_def_prop #(6, "cover") \__po_gen_immdec_w_eq1[0].imm_b30_b25__gate_cover (\__po_gen_immdec_w_eq1[0].imm_b30_b25__gate );
  miter_def_prop #(1, "cover") \__po_gen_immdec_w_eq1[0].signbit__gate_cover (\__po_gen_immdec_w_eq1[0].signbit__gate );
  miter_def_prop #(1, "cover") \__po_o_csr_imm__gate_cover (\__po_o_csr_imm__gate );
  miter_def_prop #(1, "cover") \__po_o_imm__gate_cover (\__po_o_imm__gate );
  miter_def_prop #(5, "cover") \__po_o_rd_addr__gate_cover (\__po_o_rd_addr__gate );
  miter_def_prop #(5, "cover") \__po_o_rs1_addr__gate_cover (\__po_o_rs1_addr__gate );
  miter_def_prop #(5, "cover") \__po_o_rs2_addr__gate_cover (\__po_o_rs2_addr__gate );
`endif
endmodule
module miter_cmp_prop #(parameter WIDTH=1, parameter TYPE="assert") (input [WIDTH-1:0] in_gold, in_gate);
  reg okay;
  integer i;
  always @* begin
    okay = 1;
    for (i = 0; i < WIDTH; i = i+1)
      okay = okay && (in_gold[i] === 1'bx || in_gold[i] === in_gate[i]);
  end
  generate
    if (TYPE == "assert") always @* assert(okay);
    if (TYPE == "assume") always @* assume(okay);
    if (TYPE == "cover")  always @* cover(okay);
  endgenerate
endmodule
module miter_def_prop #(parameter WIDTH=1, parameter TYPE="assert") (input [WIDTH-1:0] in);
  wire okay = ^in !== 1'bx;
  generate
    if (TYPE == "assert") always @* assert(okay);
    if (TYPE == "assume") always @* assume(okay);
    if (TYPE == "cover")  always @* cover(okay);
  endgenerate
endmodule
module \gold.serv_immdec.clk (
  input  [  0:0] \__pi_i_clk ,
  input  [  0:0] \__pi_i_cnt_done ,
  input  [  0:0] \__pi_i_cnt_en ,
  input  [  0:0] \__pi_i_csr_imm_en ,
  input  [  3:0] \__pi_i_ctrl ,
  input  [  3:0] \__pi_i_immdec_en ,
  input  [  0:0] \__pi_i_wb_en ,
  input  [ 24:0] \__pi_i_wb_rdt ,
  output [  0:0] \__po_clk ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].imm31 ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].imm7 ,
  output [  4:0] \__po_gen_immdec_w_eq1[0].imm_b11_b7 ,
  output [  8:0] \__po_gen_immdec_w_eq1[0].imm_b19_b12_b20 ,
  output [  4:0] \__po_gen_immdec_w_eq1[0].imm_b24_b20 ,
  output [  5:0] \__po_gen_immdec_w_eq1[0].imm_b30_b25 ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].signbit ,
  output [  0:0] \__po_o_csr_imm ,
  output [  0:0] \__po_o_imm ,
  output [  4:0] \__po_o_rd_addr ,
  output [  4:0] \__po_o_rs1_addr ,
  output [  4:0] \__po_o_rs2_addr
);
endmodule
module \gate.serv_immdec.clk (
  input  [  0:0] \__pi_i_clk ,
  input  [  0:0] \__pi_i_cnt_done ,
  input  [  0:0] \__pi_i_cnt_en ,
  input  [  0:0] \__pi_i_csr_imm_en ,
  input  [  3:0] \__pi_i_ctrl ,
  input  [  3:0] \__pi_i_immdec_en ,
  input  [  0:0] \__pi_i_wb_en ,
  input  [ 24:0] \__pi_i_wb_rdt ,
  output [  0:0] \__po_clk ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].imm31 ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].imm7 ,
  output [  4:0] \__po_gen_immdec_w_eq1[0].imm_b11_b7 ,
  output [  8:0] \__po_gen_immdec_w_eq1[0].imm_b19_b12_b20 ,
  output [  4:0] \__po_gen_immdec_w_eq1[0].imm_b24_b20 ,
  output [  5:0] \__po_gen_immdec_w_eq1[0].imm_b30_b25 ,
  output [  0:0] \__po_gen_immdec_w_eq1[0].signbit ,
  output [  0:0] \__po_o_csr_imm ,
  output [  0:0] \__po_o_imm ,
  output [  4:0] \__po_o_rd_addr ,
  output [  4:0] \__po_o_rs1_addr ,
  output [  4:0] \__po_o_rs2_addr
);
endmodule
