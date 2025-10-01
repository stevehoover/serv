\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)

// The core logic of serv_aligner as a TLV macro
\TLV serv_aligner_logic(/_top)
   |default
      @0
         /* 16-bit register used to hold the upper half word of the current instruction in-case
            concatenation will be required with the upper half word of upcoming instruction
         */
         <<1$lower_hw[15:0] = $i_wb_ibus_ack ? $i_wb_ibus_rdt[31:16] : $lower_hw;
         
         $ibus_rdt_concat[31:0] = {$i_wb_ibus_rdt[15:0], $lower_hw};

         /* Two control signals: ack_en, ctrl_misal are set to control the bus transactions between
         SERV core and the memory
         */
         $ack_en = ! ($i_ibus_adr[1] & ! $ctrl_misal);
         
         <<1$ctrl_misal = $reset ? 1'b0 : 
                         ($i_wb_ibus_ack & $i_ibus_adr[1]) ? ! $ctrl_misal : 
                         $ctrl_misal;

\SV
module serv_aligner
   (
    input wire clk,
    input wire rst,
    // serv_top
    input  wire [31:0]  i_ibus_adr,
    input  wire         i_ibus_cyc,
    output wire [31:0]  o_ibus_rdt,
    output wire         o_ibus_ack,
    // serv_rf_top
    output wire [31:0]  o_wb_ibus_adr,
    output wire         o_wb_ibus_cyc,
    input  wire [31:0]  i_wb_ibus_rdt,
    input  wire         i_wb_ibus_ack);
\TLV
   // Connect Verilog inputs to pipesignals
   |default
      @0
         $reset = *rst;
         $i_ibus_adr[31:0] = *i_ibus_adr;
         $i_ibus_cyc = *i_ibus_cyc;
         $i_wb_ibus_rdt[31:0] = *i_wb_ibus_rdt;
         $i_wb_ibus_ack = *i_wb_ibus_ack;
         
   m5+serv_aligner_logic(/top)
   
   // Connect pipesignals to Verilog outputs
   |default
      @0
         \SV_plus
            /* From SERV core to Memory

            o_wb_ibus_adr: Carries address of instruction to memory. In case of misaligned access,
            which is caused by pc+2 due to compressed instruction, next instruction is fetched
            by pc+4 and concatenation is done to make the instruction aligned.

            o_wb_ibus_cyc: Simply forwarded from SERV to Memory and is only altered by memory or SERV core.
            */
            assign o_wb_ibus_adr = $ctrl_misal ? ($i_ibus_adr + 32'b100) : $i_ibus_adr;
            assign o_wb_ibus_cyc = $i_ibus_cyc;
            assign o_ibus_ack = $i_wb_ibus_ack & $ack_en;
            assign o_ibus_rdt = $ctrl_misal ? $ibus_rdt_concat : $i_wb_ibus_rdt;
\SV
endmodule
