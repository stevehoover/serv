\TLV_version 1d: tl-x.org
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
   |default
      @0
         \SV_plus
            reg  [15:0] lower_hw;
            reg         ctrl_misal ;
            
            // Convert interface signal to internal signal with valid name
            assign $$reset = rst;

            /* From SERV core to Memory

            o_wb_ibus_adr: Carries address of instruction to memory. In case of misaligned access,
            which is caused by pc+2 due to compressed instruction, next instruction is fetched
            by pc+4 and concatenation is done to make the instruction aligned.

            o_wb_ibus_cyc: Simply forwarded from SERV to Memory and is only altered by memory or SERV core.
            */
            assign o_wb_ibus_adr = $ctrl_misal ? (i_ibus_adr + 32'b100) : i_ibus_adr;
            assign o_wb_ibus_cyc = i_ibus_cyc;

            /* From Memory to SERV core

                o_ibus_ack: Instruction bus acknowledge is send to SERV only when the aligned instruction,
                either compressed or un-compressed, is ready to dispatch.

                o_ibus_rdt: Carries the instruction from memory to SERV core. It can be either aligned
                instruction coming from memory or made aligned by two bus transactions and concatenation.
            */
            assign o_ibus_ack = i_wb_ibus_ack & $ack_en;
            assign o_ibus_rdt = $ctrl_misal ? $ibus_rdt_concat : i_wb_ibus_rdt;

            /* 16-bit register used to hold the upper half word of the current instruction in-case
               concatenation will be required with the upper half word of upcoming instruction
            */
            always @(posedge clk) begin
                if(i_wb_ibus_ack)begin
                    $$lower_hw[15:0] <= i_wb_ibus_rdt[31:16];
                end
            end

            assign $$ibus_rdt_concat[31:0] = {i_wb_ibus_rdt[15:0], $lower_hw};

            /* Two control signals: ack_en, ctrl_misal are set to control the bus transactions between
            SERV core and the memory
            */
            assign $$ack_en = ! (i_ibus_adr[1] & ! $ctrl_misal);

            always @(posedge clk ) begin
                if($reset)
                    $$ctrl_misal <= 0;
                else if(i_wb_ibus_ack & i_ibus_adr[1])
                    $ctrl_misal <= ! $ctrl_misal;
            end
\SV
endmodule
