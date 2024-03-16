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

  logic [DIR_SEL_WIDTH - 1:0] dir;
  logic [DATA_WIDTH - 1:0]    ast_data;
  logic                       ast_startofpacket;
  logic                       ast_endofpacket;
  logic                       ast_valid;
  logic [EMPTY_WIDTH - 1:0]   ast_empty;
  logic [CHANNEL_WIDTH - 1:0] ast_channel;
  logic                       ast_ready;   

endinterface