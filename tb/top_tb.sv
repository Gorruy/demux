module top_tb;

  import usr_types_and_params::*;
  import tb_env::Environment;

  bit   clk;
  bit   srst;
  bit   srst_done;

  initial forever #5 clk = !clk;

  ast_interface #(
    .DATA_W    ( DATA_IN_W  ), 
    .EMPTY_W   ( EMPTY_IN_W ),
    .CHANNEL_W ( CHANNEL_W  ) 
  ) ast_if_in ( 
    .clk  ( clk  ),
    .srst ( srst ) 
  );

  ast_interface #(
    .DATA_W    ( DATA_OUT_W  ), 
    .EMPTY_W   ( EMPTY_OUT_W ),
    .CHANNEL_W ( CHANNEL_W   ) 
  ) ast_if_out ( 
    .clk  ( clk  ),
    .srst ( srst ) 
  );

  ast_dmx #(
  .DATA_IN_W           ( DATA_IN_W                    ),
  .CHANNEL_W           ( CHANNEL_W                    ),
  .TX_DIR              ( TX_DIR                       ),
  .DIR_SEL_WIDTH       ( DIR_SEL_WIDTH                ),

  ) ast_inst (
  .clk_i               ( clk                          ),
  .srst_i              ( srst                         ),
  
  .dir_i               ( ast_if_in.dir                )

  .ast_data_i          ( ast_if_in.ast_data           ),
  .ast_startofpacket_i ( ast_if_in.ast_startofpacket  ),
  .ast_endofpacket_i   ( ast_if_in.ast_endofpacket    ),
  .ast_valid_i         ( ast_if_in.ast_valid          ),
  .ast_empty_i         ( ast_if_in.ast_empty          ),
  .ast_channel_i       ( ast_if_in.ast_channel        ),

  .ast_ready_o         ( ast_if_in.ast_ready          ),

  .ast_data_o          ( ast_if_out.ast_data          ),
  .ast_startofpacket_o ( ast_if_out.ast_startofpacket ),
  .ast_endofpacket_o   ( ast_if_out.ast_endofpacket   ),
  .ast_valid_o         ( ast_if_out.ast_valid         ),
  .ast_empty_o         ( ast_if_out.ast_empty         ),
  .ast_channel_o       ( ast_if_out.ast_channel       ),
  .ast_ready_i         ( ast_if_out.ast_ready         )
  );

  initial 
    begin

      Environment env;
      env = new( ast_if_in, ast_if_out );

      env.run();

      $stop();

    end


endmodule