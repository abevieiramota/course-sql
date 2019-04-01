-- notação
select 
-- TIPO 'representação'
text '123', 
-- 'representação'::TIPO
'123'::text, 
-- cast('representação' as TIPO)
cast('123' as text),
-- exemplos com smallint
smallint '123', 
'123'::smallint, 
cast('123' as smallint);


-- erro de conversão
select smallint '12341234';
select '12341234'::smallint;
-- ! não entendo por que não lança erro...!
select x::smallint
from (values ('1', '12341234')) as t(x);


-- truncando timestamp com cast para date
-- diferença para date_trunc
-- timestamp::date -> muda o tipo e perde o time
-- date_trunc('day' -> 'zera' o time
select d::date, date_trunc('day', d)
from (values ('2018-01-01 10:20:12'::timestamptz)) as t(d);


-- EXERCÍCIO

-- 1. Considere o sql abaixo

begin;

	-- preencher o nome da tabela com seu nome entre aspas duplas
	
	-- cria tabela
    create table "Abelardo Vieira Mota" (data timestamp);
	-- insere registros com timestamps
    insert into "Abelardo Vieira Mota" select now() + (i || ' days')::interval from generate_series(1, 100000) as t(i);

	-- exemplo dos dados
	SELECT * FROM "Abelardo Vieira Mota";
    
	-- cria índice sobre a coluna data
	create index teste_data_idx on "Abelardo Vieira Mota"(data);
    
	-- explain analyze de duas consultas
	--    tentar explicar por que o índice é utilizado apenas na segunda consulta
	--    por que ela é mais eficiente?
    explain analyze
    select * from "Abelardo Vieira Mota" where data::date = '2018-09-12'::date;
    
    explain analyze
    select * from "Abelardo Vieira Mota" where data >= '2018-09-12'::timestamp and data < '2018-09-13'::timestamp;
    
rollback;