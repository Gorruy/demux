1. Модуль теряет один сигнал channel_i  при подаче большого количества транзакций единичной длины и просто при подаче обычного пакета в некоторых случаях:

`Error: wrong channel info!
Time: 895 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 462`

2. В отстутствие валидного сигнала startofpacket после последней транзакции модуль начинает выдавать валидные данные на порт, соответствующи текущему значению dir_i:

`Error: Writtend data is not at right output port!
Time: 32385 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 456`