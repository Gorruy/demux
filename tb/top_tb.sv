module top_tb;

  import usr_types_and_params::*;
  import tb_env::Environment;

  bit                           clk;
  bit                           srst;
  bit                           srst_done;

  logic [DATA_WIDTH    - 1 : 0] data          [TX_DIR-1:0];
  logic                         startofpacket [TX_DIR-1:0];
  logic                         endofpacket   [TX_DIR-1:0];
  logic                         valid         [TX_DIR-1:0];
  logic [EMPTY_WIDTH   - 1 : 0] empty         [TX_DIR-1:0];
  logic [CHANNEL_WIDTH - 1 : 0] channel       [TX_DIR-1:0];
  logic                         ready         [TX_DIR-1:0];

  initial forever #5 clk = !clk;

  ast_interface #(
    .DATA_WIDTH    ( DATA_WIDTH    ), 
    .EMPTY_WIDTH   ( EMPTY_WIDTH   ),
    .CHANNEL_WIDTH ( CHANNEL_WIDTH ),
    .DIR_SEL_WIDTH ( DIR_SEL_WIDTH ),
    .TX_DIR        ( TX_DIR        )
  ) ast_if_in ( 
    .clk  ( clk  ),
    .srst ( srst ) 
  );

  genvar i;
  generate
    for ( i = 0; i < TX_DIR; i++ )
      begin : out_interfaces
        ast_interface #(
          .DATA_WIDTH    ( DATA_WIDTH    ), 
          .EMPTY_WIDTH   ( EMPTY_WIDTH   ),
          .CHANNEL_WIDTH ( CHANNEL_WIDTH ),
          .DIR_SEL_WIDTH ( DIR_SEL_WIDTH ),
          .TX_DIR        ( 1             )
        ) ast_if_inst ( 
          .clk  ( clk  ),
          .srst ( srst ) 
        );
      end
  endgenerate

  generate 
    for ( i = 0; i < TX_DIR; i++ )
      begin : port_assignments
        assign out_interfaces[i].data          = data[i];
        assign out_interfaces[i].startofpacket = startofpacket[i];
        assign out_interfaces[i].endofpacket   = endofpacket[i];
        assign out_interfaces[i].valid         = valid[i];
        assign out_interfaces[i].empty         = empty[i];
        assign out_interfaces[i].channel       = channel[i];
        assign out_interfaces[i].ready         = ready[i];
      end
  endgenerate

  virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) out_ifs[TX_DIR - 1:0];

  generate
    for ( i = 0; i < TX_DIR; i++ )
      begin : vifs_assignments
        assign out_ifs[i] = out_interfaces.ast_if_inst[i];
      end
  endgenerate 

  ast_dmx #(
    .DATA_WIDTH          ( DATA_WIDTH                   ),
    .CHANNEL_WIDTH       ( CHANNEL_WIDTH                ),
    .TX_DIR              ( TX_DIR                       ),
    .DIR_SEL_WIDTH       ( DIR_SEL_WIDTH                )

   ) ast_inst (
    .clk_i               ( clk                          ),
    .srst_i              ( srst                         ),
    
    .dir_i               ( ast_if_out.dir               ),

    .ast_data_i          ( ast_if_out.ast_data          ),
    .ast_startofpacket_i ( ast_if_out.ast_startofpacket ),
    .ast_endofpacket_i   ( ast_if_out.ast_endofpacket   ),
    .ast_valid_i         ( ast_if_out.ast_valid         ),
    .ast_empty_i         ( ast_if_out.ast_empty         ),
    .ast_channel_i       ( ast_if_out.ast_channel       ),

    .ast_ready_o         ( ast_if_out.ast_ready         ),

    .ast_data_o          ( data                         ),
    .ast_startofpacket_o ( startofpacket                ),
    .ast_endofpacket_o   ( endofpacket                  ),
    .ast_valid_o         ( valid                        ),
    .ast_empty_o         ( empty                        ),
    .ast_channel_o       ( channel                      ),
    .ast_ready_i         ( ready                        )
  );

  initial 
    begin

      Environment env;
      env = new( ast_if_in, out_ifs );

      env.run();

      $stop();

    end


endmodule