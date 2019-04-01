create table dados_repetidos (numero int, val1 text, val2 text, val3 text, val4 text, val5 text, val6 text, val7 text, val8 text);

insert into dados_repetidos 
select i, 
'val1' || i,
'val2' || i,
'val3' || i,
'val4' || i,
'val5' || i,
'val6' || i,
'val7' || i,
'val8' || i
from (select trunc(random()*1000) from generate_series(1, 10000) as t(i)) as t(i);

select *
from dados_repetidos;