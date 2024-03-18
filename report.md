1. Модуль теряет один сигнал channel_i  при подаче большого количества транзакций единичной длины, или просто при подаче обычного пакета в некоторых случаях:

`Error: wrong channel info!
Time: 895 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 462`

2. В отстутствие подтвержденного (после последней транзакции) valid'ом или ready сигнала startofpacket (или при отсутствии самого сигнала startofpacket), модуль начинает выдавать валидные данные на порт, соответствующий значению dir_i на предыдущем такте:

`Error: Unexpected data at          3 port
Time: 2015 ps  Scope: tb_env.Scoreboard.run File: packages/tb_env.sv Line: 449`