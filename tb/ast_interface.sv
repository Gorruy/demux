interface ast_interface #( 
  parameter int DATA_WIDTH    = 1,
  parameter int EMPTY_WIDTH   = 1,
  parameter int CHANNEL_WIDTH = 1,
  parameter int DIR_SEL_WIDTH = 1,
  parameter int TX_DIR        = 1
 ) ( 
  input bit clk,
  ref   bit srst
);

  task set_reset;
  
    srst = 1'b0;
    @( posedge clk );
    srst = 1'b1;
    @( posedge clk );
    srst = 1'b0;

  endtask

  generate
    if (TX_DIR != 1)
      begin
        logic [DATA_W - 1:0]    ast_data          [TX_DIR - 1:0];
        logic                   ast_startofpacket [TX_DIR - 1:0];
        logic                   ast_endofpacket   [TX_DIR - 1:0];
        logic                   ast_valid         [TX_DIR - 1:0];
        logic [EMPTY_W - 1:0]   ast_empty         [TX_DIR - 1:0];
        logic [CHANNEL_W - 1:0] ast_channel       [TX_DIR - 1:0];
        logic                   ast_ready         [TX_DIR - 1:0]; 
      end
    else
      begin
        logic [DIR_SEL_WIDTH - 1:0] dir;
        logic [DATA_W - 1:0]        ast_data;
        logic                       ast_startofpacket;
        logic                       ast_endofpacket;
        logic                       ast_valid;
        logic [EMPTY_W - 1:0]       ast_empty;
        logic [CHANNEL_W - 1:0]     ast_channel;
        logic                       ast_ready;   
      end
  endgenerate

endinterface