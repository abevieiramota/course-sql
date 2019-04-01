-- select * -> todas as colunas
-- sem LIMIT -> retorna todas as rows -> mas o DBeaver limita às 200 primeiras
-- analisar algumas rows
--    pg_settings -> configurações do PostgreSQL
SELECT *
FROM pg_catalog.pg_settings;


-- retornando apenas algumas colunas específicas
select name, setting, unit, short_desc, reset_val
from pg_catalog.pg_settings;


-- case
--    IF/ELSEIF/ELSE do SQL

-- sequência de condições
--    é utilizada a estrutura
--    CASE
--       WHEN condição THEN resultado
--       WHEN condição THEN resultado
--       ELSE resultado
--    END
select i, 
case 
	when i % 2 = 0 then 'múltiplo de 2'
	when i % 3 = 0 then 'múltiplo de 3'
	else '####'
end
from generate_series(1, 10) as t(i);
-- o que acontece se não houver o else?
--    é retornado null
select i, 
case 
	when i % 2 = 0 then 'múltiplo de 2'
	when i % 3 = 0 then 'múltiplo de 3'
end
from generate_series(1, 10) as t(i);


-- define uma coluna usando case
--    CASE expressão
--       WHEN valor THEN resultado
--       WHEN valor THEN resultado
--       ELSE resultado
--    END
select i, 
case i % 3
	when 0 then 'múltiplo de 3'
	when 1 then '(múltiplo de 3) + 1'
	else '#####'
end
from generate_series(1, 10) as t(i);

-- pode ser aninhado
select i, 
case
	when i % 2 = 0 then 
		case when i % 3 = 0 then 'múltiplo de 2 e 3'
		else 'múltiplo de 2'
		end
	when i % 3 = 0 then 'múltiplo de 3'
	else '#####'
end
from generate_series(1, 10) as t(i);

-- da mesma forma, se o else não for informado, retorna NULL

-- EXERCÍCIO
-- 1. Desenvolva sql que retorne os próximos 30 dias e retorne 'Fim de semana' se for Sábado ou Domingo, 'Dia da semana', caso contrário
--       https://www.postgresql.org/docs/9.1/static/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT
--       utilizar o seguinte sql como base
select i
from generate_series(1, 30) as t(i);



-- coalesce
--    utilizado quando é necessário especificar um valor quando a expressão for NULL
-- coalesce(va1, val2, val3, ...) -> retorna o primeiro não null
select coalesce(null, 1);

select name, coalesce(unit, 'sem unidade') as unit, unit
from pg_settings;


-- EXERCÍCIO
-- 2. Desenvolva sql que retorne a partir dos dados em pessoa a coluna nome e, caso ela não esteja preenchida, o email
with pessoa(nome, email) as (values
	('fulano', 'fulano@gmail.com'),
	(null, 'sicrano@gmail.com'),
	('beltrano', null)
)
select nome, email
from pessoa;



-- scalar query
--    consulta que retorna apenas uma row e uma coluna pode ser utilizada como escalar
--    por exemplo, como o valor de uma coluna

-- ok
select (select 1);
-- não!
select (select 1, 2);

-- no exemplo é utilizada o que chamamos de correlated query
--    é uma query que faz uso de valores retornados pela outer query
--    ela será executada uma vez para cada valor retornado pela outer query
--    o que muitas vezes não é a forma mais performática de recuperar os dados
--    no exemplo, ver o explain das duas versões
--       explain complexo porque trabalha com views, que são definidas de forma complexa

-- quantidade de colunas, por tabela, correlated subquery
select t.schemaname, t.tablename, (select count(*) from information_schema.columns where table_schema = t.schemaname and table_name = t.tablename)
from pg_catalog.pg_tables t
where t.schemaname not in ('pg_catalog', 'information_schema')
order by 3 desc;

-- quantidade de colunas por tabela, group by
select t.schemaname, t.tablename, count(*)
from pg_catalog.pg_tables t
-- por que não inner join? tabelas sem colunas não seriam retornadas
left join information_schema.columns c on c.table_name = t.tablename and c.table_schema = t.schemaname 
where t.schemaname not in ('pg_catalog', 'information_schema')
group by 1, 2
order by 3 desc;



-- distinct
--    contrário de select all, que é o default
--    remove os valores repetidos
--    é aplicado sobre todos as colunas
--    deve vir no início do select

-- usuários com sessão aberta com o servidor
select distinct usename
from pg_catalog.pg_stat_activity
where usename is not null;


-- distinct on
--    realiza um distinct nas expressões informadas no ON
--    e retorna as colunas informadas após
--    mas retorna apenas uma row por grupo
--    importante que a row a ser retornada é a primeira
--    se não for informada ordem, será a primeira 'aleatória'

-- observar os dois exemplos
select distinct on (x) x, y 
from (values (1, 2), (1, 3)) as t(x, y);

-- deve ser ordenado primeiro pela coluna utilizada no on
--    é necessário que a ordenação seja da row, e não de colunas
--    não posso pedir o maior y e o menor z do grupo -> é uma row do grupo que é retornada, um representante
select distinct on (x) x, y 
from (values (1, 2), (1, 3)) as t(x, y)
order by x, y desc;

-- ex: tabelas e suas colunas com maior precision
select distinct on (table_schema, table_name) table_schema, table_name, numeric_precision
from information_schema.columns
where table_schema not in ('pg_catalog', 'information_schema')
order by table_schema, table_name, numeric_precision desc nulls last;

-- útil para consultas do tipo 
select table_schema, table_name, max(numeric_precision)
from information_schema.columns
where table_schema not in ('pg_catalog', 'information_schema')
group by 1, 2
order by 3 desc nulls last;



-- nullif 
--    nullif(x, 'valor') -> null se x for igual a 'valor', caso contrário retorna x
-- convertendo coluna string para timestamp, tornando null se valor Não informado
select nullif(x, 'Não informado')::timestamp 
from (values ('2018-01-01'), ('Não informado')) as t(x);


-- EXERCÍCIO
-- 3. Desenvolva sql para converter todos os valores para inteiro
--       utilizar o sql abaixo
select i
from (values ('1'), ('2'), ('NULO'), ('4'), ('5')) as tabela(i);



-- greatest/least
--    max/min são aggregate functions -> sobre rows, não values
--    nulls são ignorados -> retorna null se todos forem null

-- dada essa tabela
select *
from (values (1, 2, 3), (1, 4, 5), (2, 5, 6)) as t(x, y, z);

-- posso calcular o maximo das colunas y e z para grupos de x
select x, max(y) as max_y, max(z) as max_z
from (values (1, 2, 3), (1, 4, 5), (2, 5, 6)) as t(x, y, z)
group by 1;

-- e posso calcular o maior valor entre x, y e z para cada linha
select x, y, z, greatest(x, y, z), least(x, y, z)
from (values (1, 2, 3), (1, 4, 5), (2, 5, 6)) as t(x, y, z);

-- útil para quando quero aplicar um mínimo a um valor, como
--    valores menores de 10000 serão 'convertidos' para 10000
select greatest(10, idx_scan) as min_idx_scan, idx_scan
from pg_catalog.pg_stat_user_tables;



-- select alias.*::text e array[alias.*]
-- usado para identificar os valores de uma row > # optmistic lock
-- para verificar se uma determinada row foi alterada(se algum valor foi alterado
--    sua representação textual será alterada)

select t.*::text 
from pg_catalog.pg_settings t;