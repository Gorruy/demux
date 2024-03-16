package usr_types_and_params;
  
  parameter int DATA_WIDTH                = 64;
  parameter int CHANNEL_WIDTH             = 10;
  parameter int EMPTY_WIDTH               = $clog2( DATA_WIDTH / 8 );
  parameter int TX_DIR                    = 4;

  parameter int DIR_SEL_WIDTH             = TX_DIR == 1 ? 1 : $clog2( TX_DIR );

  parameter int NUMBER_OF_TEST_RUNS       = 2;
  parameter int MAX_TR_LEN                = 1024;
  parameter int WORK_TR_LEN               = 10;
  parameter int TIMEOUT                   = WORK_TR_LEN * 3;
  parameter int DR_TIMEOUT                = WORK_TR_LEN;
  parameter int MAX_DATA_VALUE            = 2**DATA_WIDTH - 1;
  parameter int NUMBER_OF_ONE_LENGHT_RUNS = 1;
  parameter int NUMBER_OF_RANDOM_RUNS     = 10;

  typedef logic [DATA_WIDTH - 1:0]    data_t[$];
  typedef int                         delays_t[$];
  typedef logic [CHANNEL_WIDTH - 1:0] channel_t;
  typedef logic [EMPTY_WIDTH - 1:0]   empty_in_t;
  typedef logic [EMPTY_WIDTH - 1:0]   empty_out_t;
  typedef logic [7:0]                 byte_data_t[$];
  
  typedef bit                         queued_bits_t[$];

endpackage