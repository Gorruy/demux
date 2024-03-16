package tb_env;

  import usr_types_and_params::*;
  
  class Transaction;
  // Instance of this class will hold all info about single transaction in
  // a form of queues, where each element in queue represents values of 
  // dut signal during transaction

    data_t        data;
    int           len;
    channel_t     channel[$];
    empty_in_t    empty[$];
    queued_bits_t valid;
    queued_bits_t ready;
    queued_bits_t startofpacket;
    queued_bits_t endofpacket;
    bit           wait_dut_ready;
    queued_bits_t reset;

    function new( input int tr_length = WORK_TR_LEN );
    // new will generate normal transaction

      this.len = tr_length;

      repeat(this.len)
        begin
          this.data.push_back( $urandom_range( MAX_DATA_VALUE, 0 ) );

          this.channel.push_back( '0 );
          this.empty.push_back( '0 );
          this.valid.push_back( 1'b1 );
          this.ready.push_back( 1'b1 );
          this.startofpacket.push_back( 1'b0 );
          this.endofpacket.push_back( 1'b0 );
          this.reset.push_back( 1'b0 );
        end

      this.startofpacket[$] = 1'b1;
      this.endofpacket[0]   = 1'b1;
      this.wait_dut_ready   = 1'b1;

    endfunction    
    
  endclass
  
  class Generator;
  // This class will generate random transactions

    mailbox #( Transaction ) generated_transactions;

    function new( mailbox #( Transaction ) gen_tr );

      generated_transactions = gen_tr;

    endfunction

    task run;

      Transaction tr;

      // Normal transaction
      tr = new();

      generated_transactions.put(tr);

      // Transactions of length one
      repeat ( NUMBER_OF_ONE_LENGHT_RUNS )
        begin
          tr = new( .tr_length(1) );
          generated_transactions.put(tr);
        end

      // Transaction without valid
      tr = new();
      foreach( tr.data[i] )
        begin
          tr.valid[i] = 1'b0;
        end

      generated_transactions.put(tr);

      // Transactions of work length with random valid
      repeat (NUMBER_OF_TEST_RUNS)
        begin
          tr  = new();

          foreach( tr.data[i] )
            begin
              tr.valid[i] = $urandom_range( 1, 0 );
            end

          tr.valid[$]         = 1'b1;
          tr.valid[0]         = 1'b1;

          generated_transactions.put(tr);
        end


      // Transactions of work length with empty's values progression
      for ( int i = 0; i < 2**EMPTY_WIDTH; i++ )
        begin
          tr = new();

          foreach( tr.data[j] )
            begin
              tr.empty[j] = i;
            end

          generated_transactions.put(tr);
        end

      // Transaction with constant high value of startofpacket 
      tr = new();

      foreach( tr.data[i] )
        begin
          tr.startofpacket[i] = 1'b1;
        end

      generated_transactions.put(tr);

      // Transactions of work length with random ready
      repeat (NUMBER_OF_TEST_RUNS)
        begin
          tr = new();

          foreach( tr.data[i] )
            begin
              tr.ready[i] = $urandom_range( 1, 0 );
            end

          tr.wait_dut_ready   = 1'b0;

          generated_transactions.put(tr);

        end

      // Transactions of work length without ready
      repeat (NUMBER_OF_TEST_RUNS)
        begin
          tr = new();

          repeat(tr.len)
            begin
              tr.ready.push_back( 1'b0 );
            end

          tr.wait_dut_ready   = 1'b1;

          generated_transactions.put(tr);
        end

      // transaction without startofpacket
      tr = new();

      foreach( tr.data[i] )
        begin
          tr.startofpacket[i] = 1'b0;
        end

      generated_transactions.put(tr);

      // Transactions with length progression
      for ( int i = 2; i < WORK_TR_LEN; i++ )
        begin
          tr = new(.tr_length(i));

          generated_transactions.put(tr);

        end

      // Normal transaction of max length
      tr = new(.tr_length(MAX_TR_LEN));

      generated_transactions.put(tr);

      // Transaction with reset in between
      tr = new();

      tr.reset[tr.len/2] = 1'b1;

      generated_transactions.put(tr);

      // Transaction with const reset
      tr = new();

      foreach( tr.data[i] )
        begin
          tr.reset[i] = 1'b1;
        end

      // full random transaction finished with reset
      repeat(NUMBER_OF_RANDOM_RUNS)
        begin

          tr = new();

          foreach( tr.data[i] )
            begin
              tr.ready[i]       = $urandom_range( 1, 0 );
              tr.valid[i]       = $urandom_range( 1, 0 );
              tr.empty[i]       = $urandom_range( 2**EMPTY_WIDTH, 0 );
              tr.channel[i]     = $urandom_range( 2**CHANNEL_WIDTH, 0 );
              tr.endofpacket[i] = $urandom_range( 1, 0 );
            end

          tr.valid[$]       = 1'b1;
          tr.reset[0]       = 1'b1;
          tr.endofpacket[$] = 1'b0;
          generated_transactions.put(tr);

        end

    endtask 
    
  endclass

  class Driver #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR );
  // This class will drive all dut input signals
  // according to transaction's parameters

    virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) vif;

    function new( input virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) dutif );

      vif = dutif;

    endfunction

    task drive_in( input Transaction tr );

      int wr_timeout;
      wr_timeout = 0;

      repeat(tr.len)
        begin
          while ( tr.wait_dut_ready && vif.ast_ready !== 1'b1 && wr_timeout++ < DR_TIMEOUT )
            begin
              @( posedge vif.clk );
            end

          @( posedge vif.clk );
          wr_timeout             = 0;

          vif.ast_channel       <= tr.channel.pop_back();      
          vif.ast_empty         <= tr.empty.pop_back();        
          vif.ast_valid         <= tr.valid.pop_back();              
          vif.ast_startofpacket <= tr.startofpacket.pop_back();
          vif.ast_endofpacket   <= tr.endofpacket.pop_back();  
          vif.ast_data          <= tr.data.pop_back();
          vif.srst              <= tr.reset.pop_back();
        end

      // This loop will finish transaction if end of transaction and ready_o doesn't met
      while ( vif.ast_ready !== 1'b1 && wr_timeout++ < DR_TIMEOUT )
        begin
          @( posedge vif.clk );
        end

      in_flush();

    endtask

    task drive_out( input Transaction tr );

      repeat(tr.len)
        begin
          @( posedge vif.clk );
          vif.ast_ready <= tr.ready.pop_back();
        end

      vif.ast_ready <= 1'b1;

    endtask

    task in_flush;

      @( posedge vif.clk );
      vif.ast_channel       <= '0;
      vif.ast_empty         <= 1'b0;
      vif.ast_valid         <= 1'b0;
      vif.ast_startofpacket <= 1'b0;
      vif.ast_endofpacket   <= 1'b0;
      vif.ast_data          <= '0;
      vif.srst              <= 1'b0;

    endtask

    task out_flush;

      @( posedge vif.clk );
      vif.ast_ready <= 1'b0;

    endtask
  
  endclass
  
  class Monitor #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR );
  // This class will gather both input and output data from dut
  // and send it to Scoreboard

     virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) vif;
     mailbox #( byte_data_t )                              input_data;
     mailbox #( logic [CHANNEL_WIDTH - 1:0] )              channel_mbx;

    function new ( input virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) dut_interface,
                   mailbox #( byte_data_t )                                    mbx_data,
                   mailbox #( logic [CHANNEL_WIDTH - 1:0] )                        in_ch
                 );

      vif         = dut_interface;
      input_data  = mbx_data;
      channel_mbx = in_ch;

    endfunction

    task run;

      get_data();

    endtask

    task get_data;

      byte_data_t                 data;
      int                         start_of_packet_flag;
      int                         timeout_ctr;
      logic [CHANNEL_WIDTH - 1:0] channel;

      start_of_packet_flag = 0;
      data                 = {}; 
      timeout_ctr          = 0;

      while ( timeout_ctr++ < TIMEOUT )
        begin
          @( posedge vif.clk );

          if ( vif.ast_startofpacket === 1'b1 && vif.ast_valid == 1'b1 && vif.ast_ready === 1'b1 )
            begin
              if ( start_of_packet_flag == 1 )
                data = {};
              else
                begin
                  channel = vif.ast_channel;
                  channel_mbx.put(channel);
                end
              start_of_packet_flag = 1;
            end
          if ( vif.srst === 1'b1 )
            break;
            
          if ( vif.ast_valid === 1'b1 && vif.ast_ready === 1'b1 && start_of_packet_flag )
            begin
              // Transaction without errors can be finished only when endofpacket raised
              if ( vif.ast_endofpacket === 1'b1 )
                begin
                  timeout_ctr = 0;

                  for ( int i = 0; i < 2**EMPTY_WIDTH - vif.ast_empty; i++ )
                    begin
                      data.push_back( vif.ast_data[i*8 +: 8] );
                    end

                  input_data.put(data);
                  return;
                end
              else
                begin
                  timeout_ctr = 0;

                  for ( int i = 0; i < 2**EMPTY_WIDTH; i++ )
                    begin
                      data.push_back( vif.ast_data[i*8 +: 8] );
                    end
                end
            end
        end
      
      data.push_back( 'x );
      input_data.put(data);

    endtask
  
  endclass
  
  class Scoreboard;
  // This class will compare read and written data

    mailbox #( byte_data_t )                 input_data;
    mailbox #( byte_data_t )                 output_data;
    mailbox #( logic [CHANNEL_WIDTH - 1:0] ) input_channel;
    mailbox #( logic [CHANNEL_WIDTH - 1:0] ) output_channel;

    function new ( mailbox #( byte_data_t )                 in_data,
                   mailbox #( byte_data_t )                 out_data,
                   mailbox #( logic [CHANNEL_WIDTH - 1:0] ) in_ch,
                   mailbox #( logic [CHANNEL_WIDTH - 1:0] ) out_ch
                 );

      input_data     = in_data;
      output_data    = out_data;
      input_channel  = in_ch;
      output_channel = out_ch;

    endfunction

    task run;

      byte_data_t                 in_data;
      byte_data_t                 out_data;
      logic [CHANNEL_WIDTH - 1:0] in_channel;
      logic [CHANNEL_WIDTH - 1:0] out_channel;

      if ( input_channel.num() != output_channel.num() )
        $error("Error in read channels amount:rd%d, wr%d", output_channel.num(), input_channel.num() );
      else 
        begin
          while ( input_channel.num() && output_channel.num() )
            begin
              input_channel.get(in_channel);
              output_channel.get(out_channel);

              if ( in_channel !== out_channel )
                $error("Read and written channels not equal:rd%d, wr%d", out_channel, in_channel);
            end
        end

      if ( input_data.num() !== output_data.num() )
        $error( "Number of read and written transactions doesn't equal, wr:%d, rd:%d", input_data.num(), output_data.num() );

      while ( input_data.num() && output_data.num() )
        begin
          input_data.get(in_data);
          output_data.get(out_data);
          
          if ( in_data.size() != out_data.size() )
            begin
              $error( "data sizes dont match!: wr size:%d, rd size:%d ", in_data.size(), out_data.size() );
              $displayh( "wr data:%p", in_data[$ -: WORK_TR_LEN] );
              $displayh( "rd data:%p", out_data[$ -: WORK_TR_LEN] );
            end
          else
            begin
              foreach( in_data[i] )
                begin
                  if ( in_data[i] === 'x || out_data[i] === 'x && in_data[i] !== out_data[i] )
                    begin
                      $error("Error during transaction!! Wrong control signals values");
                      $displayh( "wr data:%p", in_data[$ -: WORK_TR_LEN] );
                      $displayh( "rd data:%p", out_data[$ -: WORK_TR_LEN] );
                      $display( "Index: %d", i );
                      break;
                    end
                  if ( in_data[i] !== out_data[i] )
                    begin
                      $error( "wrong data!" );
                      $displayh( "wr data:%p", in_data[$ -: WORK_TR_LEN] );
                      $displayh( "rd data:%p", out_data[$ -: WORK_TR_LEN] );
                      $display( "Index: %d", i );
                      break;
                    end
                end
            end
        end

    endtask

  endclass

  class Environment;
  // This class will hold all tb elements together
    
    Driver #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR )  in_driver;
    Driver #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR )  out_driver;
    Monitor #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) in_monitor;
    Monitor #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) out_monitor;
    Scoreboard                                                                 scoreboard;
    Generator                                                                  generator;

    mailbox #( Transaction )                                                   generated_transactions;
    mailbox #( byte_data_t )                                                   input_data;
    mailbox #( byte_data_t )                                                   output_data;

    mailbox #( logic [CHANNEL_WIDTH - 1:0] )                                   in_channel;
    mailbox #( logic [CHANNEL_WIDTH - 1:0] )                                   out_channel;

    virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) i_vif;
    virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) o_vif [TX_DIR - 1:0];

    function new( input virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) in_dutif,
                  input virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) out_dutif [TX_DIR - 1:0]
                );

      generated_transactions = new();
      input_data             = new();
      output_data            = new();
      in_channel             = new();
      out_channel            = new();

      i_vif                  = in_dutif;
      o_vif                  = out_dutif;
      in_driver              = new( i_vif );
      out_driver             = new( o_vif );
      in_monitor             = new( i_vif, input_data, in_channel );
      out_monitor            = new( o_vif, output_data, out_channel );
      scoreboard             = new( input_data, output_data, in_channel, out_channel );
      generator              = new( generated_transactions );
      
    endfunction
    
    task run;

      Transaction tr;
    
      generator.run();

      in_driver.in_flush();
      out_driver.out_flush();
  
      @( posedge i_vif.clk );

      i_vif.set_reset();
      
      while ( generated_transactions.num() )
        begin
          generated_transactions.get(tr);

          fork 
            in_driver.drive_in(tr);
            out_driver.drive_out(tr);
            in_monitor.run();
            out_monitor.run();
          join

          scoreboard.run();
        end
        
    endtask
  
  endclass

endpackage