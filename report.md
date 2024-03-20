1. Модуль теряет один сигнал channel_i  при подаче большого количества транзакций единичной длины, или просто при подаче обычного пакета в некоторых случаях:

`Error: wrong channel info!
Time: 895 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 462`

2. Модуль использует неподтвержденный сигнал dir_i, беря его с предыдущего такта clk:
  - Если в начале транзакции startofpacket не подтверждается valid'ом:

`Error: Valid data at output ports without valid startofpacket
Time: 2015 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 457`

  - Если подтвержденный startofpacket'ом и valid'ом dir_i, приходит, когда ready_o опущен:

'Error: Input and output data sizes not equal!
Time: 9345 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 494'

`port:1`

3. Модуль начал выдавать данные на неправильный порт даже при подтвержденном startofpacket'ом valid'ом и ready dir_i: первая порция данных была выставлена на правильный порт, остальные - нет. Произошло это после завершения предыдущей транзакции с ошибкой: endofpacket не был подтвержден

`Error: Input and output data sizes not equal!
Time: 24545 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 494`

`port:0`