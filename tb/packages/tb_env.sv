package tb_env;

  import usr_types_and_params::*;

  class ReadTransactionInfo;
  // This class will hold data read by monitor

    q_byte_data_t data;
    q_channel_t   channel;
    q_dir_t       dir;     // Will hold only valid dirs

  endclass
  
  class Transaction;
  // Instance of this class will hold all info about single transaction in
  // a form of queues, where each element in queue represents values of 
  // dut signal during transaction

    q_data_t    data;
    q_channel_t channel;
    q_empty_t   empty;
    q_bits_t    valid;
    q_bits_t    startofpacket;
    q_bits_t    endofpacket;
    q_bits_t    reset;
    q_dir_t     dir;

    ready_t     ready_type;

    int         len;
    bit         wait_dut_ready;

    function new( input int     tr_length = WORK_TR_LEN,
                  input ready_t rd_t      = CONST_ONE 
                );
    // new will generate normal transaction

      this.len        = tr_length;
      this.ready_type = rd_t;

      repeat(this.len)
        begin
          this.data.push_back( $urandom_range( MAX_DATA_VALUE, 0 ) );

          this.channel.push_back( '0 );
          this.empty.push_back( '0 );
          this.valid.push_back( 1'b1 );
          this.startofpacket.push_back( 1'b0 );
          this.endofpacket.push_back( 1'b0 );
          this.reset.push_back( 1'b0 );
          this.dir.push_back( $urandom_range( TX_DIR - 1, 0 ) );
        end

      this.startofpacket[$] = 1'b1;
      this.endofpacket[0]   = 1'b1;
      this.wait_dut_ready   = 1'b0;

    endfunction    
    
  endclass
  
  class Generator;
  // This class will generate transactions

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
      tr = new( .tr_length(NUMBER_OF_ONE_LENGHT_RUNS) );

      repeat ( tr.len )
        begin
           
          tr.valid.push_back( 1'b1 );
          tr.startofpacket.push_back( 1'b1 );
          tr.endofpacket.push_back( 1'b1 );
          tr.dir.push_back( $urandom_range( TX_DIR - 1, 0 ) );
        end

      generated_transactions.put(tr);

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
          tr = new( .rd_t(RANDOM) );

          tr.wait_dut_ready = 1'b0;

          generated_transactions.put(tr);

        end

      // Transactions of work length without ready
      repeat (NUMBER_OF_TEST_RUNS)
        begin
          tr = new( .rd_t(CONST_ZERO) );
          tr.wait_dut_ready = 1'b0;

          generated_transactions.put(tr);
        end

      // transaction without startofpacket
      tr = new( .rd_t(RANDOM));

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

      // Normal transaction of max length with alternating ready
      tr = new(.tr_length(MAX_TR_LEN), .rd_t(ALTERNATING) );

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

      // transaction finished with reset
      tr = new();
      tr.reset[0] = 1'b1;

      generated_transactions.put(tr);

      // transaction started with reset
      tr = new();
      tr.reset[$] = 1'b1;

      generated_transactions.put(tr);

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
          vif.dir               <= tr.dir.pop_back();
        end

      // This loop will finish transaction if end of transaction and ready_o doesn't met
      while ( vif.ast_ready !== 1'b1 && wr_timeout++ < DR_TIMEOUT )
        begin
          @( posedge vif.clk );
        end

      in_flush();

    endtask

    task drive_out( input ready_t ready_type );

      int wr_timeout;

      wr_timeout = 0;

      while ( wr_timeout++ < TIMEOUT )
        begin
          @( posedge vif.clk );
          if ( vif.ast_valid === 1'b1 )
            wr_timeout = 0;

          case (ready_type)

            CONST_ZERO: begin
              vif.ast_ready <= 1'b0;
            end

            RANDOM: begin
              vif.ast_ready <= $urandom_range(1, 0);
            end

            CONST_ONE: begin
              vif.ast_ready <= 1'b1;
            end

            ALTERNATING: begin
              vif.ast_ready <= ~vif.ast_ready;
            end

            default: begin
              vif.ast_ready <= 'x;
            end

          endcase

        end

      vif.ast_ready <= 1'b0;

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
      vif.dir               <= 1'b0;

    endtask

    task out_flush;

      @( posedge vif.clk );
      vif.ast_ready <= 1'b1;

    endtask
  
  endclass
  
  class Monitor #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR );
  // This class will gather both input and output data from dut
  // and send it to Scoreboard

     virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) vif;
     mailbox #( ReadTransactionInfo )                                                         read_tr;

    function new ( input virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) dut_interface,
                   mailbox #( ReadTransactionInfo )                                                               mbx_tr
                 );

      this.vif     = dut_interface;
      this.read_tr = mbx_tr;

    endfunction

    task run;

      get_data();

    endtask

    task get_data;
    // This task will gather all valid data during transaction, even without startofpacket and endofpacket

      ReadTransactionInfo tr;

      int                 timeout_ctr;

      tr          = new();
      timeout_ctr = 0;

      while ( timeout_ctr++ < TIMEOUT )
        begin
          @( posedge this.vif.clk );

          if ( this.vif.srst === 1'b1 )
            break;

          if ( this.vif.ast_startofpacket === 1'b1 && this.vif.ast_valid === 1'b1 && this.vif.ast_ready === 1'b1 )
            begin
              tr = new();

              tr.channel.push_back(this.vif.ast_channel);
              tr.dir.push_back(this.vif.dir);
            end
            
          if ( this.vif.ast_valid === 1'b1 && this.vif.ast_ready === 1'b1 )
            begin
              // Transaction without errors can be finished only when endofpacket raised
              if ( vif.ast_endofpacket === 1'b1 )
                begin
                  timeout_ctr = 0;

                  for ( int i = 0; i < 2**EMPTY_WIDTH - this.vif.ast_empty; i++ )
                    begin
                      tr.data.push_back( this.vif.ast_data[i*8 +: 8] );
                    end

                  this.read_tr.put(tr);
                  tr = new();
                end
              else
                begin
                  timeout_ctr = 0;

                  for ( int i = 0; i < 2**EMPTY_WIDTH; i++ )
                    begin
                      tr.data.push_back( this.vif.ast_data[i*8 +: 8] );
                    end
                end
            end
        end

      this.read_tr.put(tr);

    endtask
  
  endclass
  
  class Scoreboard;
  // This class will compare read and written data
    mailbox #( ReadTransactionInfo ) output_trs [TX_DIR - 1:0];
    mailbox #( ReadTransactionInfo ) input_trs;

    function new ( mailbox #( ReadTransactionInfo ) in_trs,
                   mailbox #( ReadTransactionInfo ) out_trs [TX_DIR - 1:0]
                 );

      input_trs  = in_trs;
      output_trs = out_trs;

    endfunction

    task run;

      ReadTransactionInfo out_tr;
      ReadTransactionInfo in_tr;

      while ( input_trs.num() )
        begin
          input_trs.get(in_tr);
          
          if ( in_tr.dir.size() == 0 ) // Check if there is no input valid transaction but output presents
            begin
              foreach ( output_trs[i] )
                if ( output_trs[i].num() != 0 )
                  begin
                    output_trs[i].get(out_tr);
                    if ( out_tr.data.size() != 0 )
                      begin
                        $error("Unexpected data at%d port", i );
                      end
                    break;
                  end
              continue;
            end

          foreach (in_tr.dir[i]) // In loop for cases when multiple startofpacket in one transaction
            begin
              if ( output_trs[in_tr.dir[i]].try_get(out_tr) == 0 )
                begin
                  $error("There is no data at expected port!");
                  $display( "Port:%d", in_tr.dir[i] );
                  break;
                end
              else
                begin
                  if ( in_tr.channel.pop_back() !== out_tr.channel.pop_back() )
                    $error("wrong channel info!");
                  while ( out_tr.data.size() != 0 )
                    if ( out_tr.data.pop_back() !== in_tr.data.pop_back() )
                      begin
                        $error("Wrong data at port");
                        $displayh("port:%d", in_tr.dir[0] );
                        break;
                      end
                end
            end

        end

        // Clean up output mailboxes
        foreach ( output_trs[i] )
          while ( output_trs[i].num() )
            output_trs[i].get(out_tr);

    endtask

  endclass

  class Environment;
  // This class will hold all tb elements together
    
    Driver #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR )                in_driver; 
    Driver #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, 1 )                     out_drivers  [TX_DIR - 1:0];
    Monitor #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, 1 )                    out_monitors [TX_DIR - 1:0];
    Monitor #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR )               in_monitor;
    Scoreboard                                                                               scoreboard;
    Generator                                                                                generator;

    mailbox #( Transaction )                                                                 generated_transactions;
    mailbox #( ReadTransactionInfo )                                                         input_trs;
    mailbox #( ReadTransactionInfo )                                                         output_trs  [TX_DIR - 1:0];

    virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) i_vif;
    virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, 1      ) o_vifs [TX_DIR - 1:0];

    function new( input virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, TX_DIR ) in_dutif,
                  input virtual ast_interface #( DATA_WIDTH, EMPTY_WIDTH, CHANNEL_WIDTH, DIR_SEL_WIDTH, 1 )      out_dutif [TX_DIR - 1:0]
                );

      i_vif                  = in_dutif;
      o_vifs                 = out_dutif;

      generated_transactions = new();
      input_trs              = new();

      foreach ( out_drivers[i] )
        begin
          output_trs[i]   = new();
          out_drivers[i]  = new( o_vifs[i] );
          out_monitors[i] = new( o_vifs[i], output_trs[i] );
        end

      in_driver  = new( i_vif );
      scoreboard = new( input_trs, output_trs );
      generator  = new( generated_transactions );
      in_monitor = new( i_vif, input_trs );
      
    endfunction
    
    task run;

      Transaction tr;
    
      generator.run();

      in_driver.in_flush();
      foreach ( out_drivers[i] )
        out_drivers[i].out_flush();
  
      @( posedge i_vif.clk );

      i_vif.set_reset();
      
      while ( generated_transactions.num() )
        begin
          generated_transactions.get(tr);

          fork 
            in_driver.drive_in(tr);
            in_monitor.run();
            begin
              for ( int k = 0; k < TX_DIR; k++ )
                begin
                  fork
                    automatic int i = k;
                    out_drivers[i].drive_out(tr.ready_type); 
                    out_monitors[i].run();
                  join_none
                end
              wait fork;
            end
          join

          scoreboard.run();
        end
        
    endtask
  
  endclass

endpackage