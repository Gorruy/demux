1. Модуль теряет один сигнал channel_i  при подаче большого количества транзакций единичной длины, или просто при подаче обычного пакета в некоторых случаях:

`Error: wrong channel info!
Time: 895 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 462`

2. Модуль использует неподтвержденный сигнал dir_i, беря его с предыдущего такта clk:
  - Если в начале транзакции startofpacket не подтверждается valid'ом:

`Error: Valid data at output ports without valid startofpacket
Time: 2015 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 457`

  - Если подтвержденный startofpacket'ом и valid'ом dir_i, приходит, когда ready_o опущен:

`Error: Wrong data at port
Time: 9345 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 495`

`port:1`

3. Модуль начал выдавать данные на неправильный порт даже при подтвержденном startofpacket: первая порция данных была выставлена на правильный порт, сотальные - нет. Произошло это после завершения предыдущей транзакции с ошибкой: endofpacet не был подтвержден

`Error: Wrong data at port
Time: 32465 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 479`

`port:0`