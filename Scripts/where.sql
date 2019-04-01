-- where 
--    retorna apenas as rows para as quais a condição no where retorna TRUE
--    não retorna se o resultado for FALSE ou NULL
select *
from (values (1), (null)) as t(x)
where null;


-- in
-- X in (lista)
--    retorna TRUE se X for igual a um dos valores da lista

-- colunas integer e bigint
select data_type, table_schema, table_name, column_name
from information_schema.columns
where data_type in ('integer', 'bigint') and table_schema not in ('pg_catalog', 'information_schema');

-- é possível, no lugar de uma lista de valores, usar uma subconsulta


-- EXERCÍCIO
-- 1. Desenvolva um sql que retorne todas as colunas, que não sejam de tabelas dos esquemas pg_catalog nem information_schema
--       cujo data_type é um dos dois data_type mais frequentes entre todas colunas, em tabelas que não sejam dos esquemas pg_catalog nem information_schema
--       informações de colunas ficam em information_schema.columns


-- x in (null, lista)
-- se x not in (lista) então retorna NULL
-- a ideia é 
--    eu não sei que valor é o NULL(não conhecido)
--    ele pode ser ou não o 1 -> retorno NULL para dizer que não sei
-- ! cuidado com NULL in (...) -> sempre NULL
select x,
x in (null, 1) as "x in (null, 1)",
x in (null, 2) as "x in (null, 2)"
from (values (1), (null)) as t(x);


-- x not in (null, lista)
--    se x in (lista) então retorna FALSE -> x in (null, lista)
--    caso contrário, retorna NULL
--       eu não sei que valor é o NULL(não conhecido)
--       ele pode ser ou não o 1 -> retorno NULL para dizer que não sei
select x,
x not in (null, 1) as "x not in (null, 1)",
x not in (null, 2) as "x not in (null, 2)"
from (values (1), (null)) as t(x);


-- EXERCÍCIO
-- 2. Desenvolva um sql que retorne as rows de tabela que pertencem à lista de valores (1, 2, 3, NULL);
--       caso o valor seja NULL ele deverá ser retornado! semântica diferente
with tabela(v) as (values (1), (3), (NULL), (NULL), (10))
select *
from tabela;



-- é possível misturar tipos de dados diferentes no in
--    mas eles serão convertidos para o tipo de dado mais específico que inclua todos os operandos
-- ok
select 1 in ('1', 3);
-- erro
select 1 in ('1', 3, '2018-08-01');
-- converte para integer
select '1' in (1, 3);



-- exists
--    retorna true se a subconsulta passada retornar algum valor para a row

-- tabelas com indexes
select *
from pg_catalog.pg_stat_user_tables t
where t.schemaname not in ('pg_catalog', 'information_schema') and 
exists (
	select *
	from pg_catalog.pg_indexes i
	where t.schemaname = i.schemaname and t.relname = i.tablename 
);

-- tabelas sem indexes
select *
from pg_catalog.pg_stat_user_tables t
where t.schemaname not in ('pg_catalog', 'information_schema') and
not exists (
	select *
	from pg_catalog.pg_indexes i
	where t.schemaname = i.schemaname and t.relname = i.tablename 
);


-- EXERCÍCIO
-- 3. Desenvolva sql que retorne schemas que possuam tabelas que nunca tenham passado por vacuum ou a última vez foi há mais de 10 minutos
--       os schemas encontram-se em information_schema.schemata, com nome na coluna schema_name
--       as tabelas podem passar por vacuum manual ou automático
--          as datas das execuções ficam em pg_catalog.pg_stat_user_tables.last_vacuum e last_autovacuum, respectivamente; o nome do schema da tabela fica na coluna schemaname
select * from pg_catalog.pg_stat_user_tables;



-- and, or, not
--    avalia o operando da esquerda e então todo o resto à direita
--    usar parêntesis para clareza
select *
from generate_series(1, 10) t(i)
where i % 2 = 0 or i % 3 = 0 and i % 4 = 0;
-- resultado
--    where i % 2 = 0 or (i % 3 = 0 and i % 4 = 0);
-- e não
--    where (i % 2 = 0 or i % 3 = 0) and i % 4 = 0;

-- not
select 
not true and false as "not T and F", 
not (true and false) as "not (T and F)";



-- all
--   retorna TRUE se o operador retornar TRUE para o operando esquerdo e todos os valores no operando direito
--   notação OPERANDO OPERADOR ALL (SUBCONSULTA)

-- tabelas cujos indexes todos foram escaneados mais de 10 vezes
select t.schemaname, t.tablename
from pg_catalog.pg_tables t
where t.schemaname not in ('pg_catalog', 'information_schema') and 
10 < all(
	select idx_scan
	from pg_catalog.pg_stat_user_indexes i
	where i.schemaname = t.schemaname and t.tablename = i.relname
);

-- ! tabelas sem indexes são retornadas! 

-- ! ocorre que se a subconsulta do ALL retornar 0 rows, o resultado será TRUE
--    independente do operador!
--    verdade "por vacuidade"
with vazio as (select * from generate_series(1, 1) as t(i) where i > 1000)
select *
from (values (1)) as t(i)
-- testar os dois wheres, intuitivamente opostos
--    por vacuidade, é diferente de todos os valores em vazio
where i <> all(select * from vazio);
--    e é igual a todos os valores em vazio
where i = all(select * from vazio);


-- reescrevendo o sql de tabelas cujos indexes todos têm idx_scan > 10
select distinct t.schemaname, t.tablename
from pg_catalog.pg_tables t
-- tabelas sem index não são incluídas, pois a subconsulta escalar irá retornar null para elas
where 10 < (select min(idx_scan) from pg_catalog.pg_stat_user_indexes i where i.schemaname = t.schemaname and t.tablename = i.relname);

--    com group by
select t.schemaname, t.tablename
from pg_catalog.pg_tables t
inner join pg_catalog.pg_stat_user_indexes i on i.schemaname = t.schemaname and t.tablename = i.relname
group by 1, 2
having min(idx_scan) > 10;



-- !cuidado com NULL
select *
from (values (10)) as t(i)
-- sei que é maior que um dos valores, mas não sei se é maior que NULL
where i > all(values (3), (null));



-- any/some
--    da mesma forma que o operador ALL, o operador ANY aplica a operação 
--    ao operando da esquerda e a cada valor do operando da direita
--    retorna TRUE se a operação retornar TRUE para pelo menos um caso

-- comportamento com NULL
--    sei que é maior que um dos valores, e isso é suficiente
select *, i > any(values (10), (3), (null)) as any
from (values (10)) as t(i);



-- any = some
select *
from (values (10)) as t(i)
where i > some(values (10), (3), (null));



-- between
--    x between y and z -> x in [y, z]
select *
from generate_series(1, 10) as t(i)
where i between 1 and 3;


-- cuidado trabalhando com timestamp
--    e filtrando com date
-- no exemplo, o filtro é de [01/01, 02/01]
-- que irá incluir ambos os limites 
-- ex: 02/01 00:00:00.000 -> talvez queira todos os timestamps do dia 01/01 e 02/01
select min(t), max(t)
from (
    select '2018-01-01 10:00:00'::timestamp + (n * '1 hour'::interval)
    from generate_series(0, 100) as tt(n)
) as t(t)
-- vai até 2018-01-02 00:00:00
where t between '2018-01-01' and '2018-01-02';


-- segue a forma que normalmente é desejada
--    todos os timestamps de um dia
select min(t), max(t)
from (
    select '2018-01-01 10:00:00'::timestamp + (n * '1 hour'::interval)
    from generate_series(0, 100) as tt(n)
) as t(t)
where t >= '2018-01-01' and t < '2018-01-03';



-- tuple
--    alguns operadores funcionam com tuplas, como o IN e o =
--    executar várias vezes
select *
-- gera todos os (x, y) com x em [1, 5] e y em [5, 10]
from generate_series(1, 5) a(x), generate_series(5, 10) b(x)
-- verifica se a tupla está contida no resultado
where (a.x, b.x) in (
	-- gera (x, y) com x e y em [1, 10]
    select floor(random() * 10 + 1), floor(random() * 10 + 1) 
    from generate_series(1, 3)
);

-- exemplo 

--    candidatos com a última alteração que sofreram

-- versão não correlacionada
explain 
select *
from ingresso.alteracao_status_candidato_sisu
where (id_candidato_sisu, data_alteracao) in (
    select id_candidato_sisu, max(data_alteracao)
    from ingresso.alteracao_status_candidato_sisu
    group by 1
);

-- versão correlacionada
explain 
select *
from ingresso.alteracao_status_candidato_sisu a 
where data_alteracao = (select max(data_alteracao) from ingresso.alteracao_status_candidato_sisu where id_candidato_sisu = a.id_candidato_sisu);

-- versão com window_function
explain
with com_pos as (
    select *, row_number() over(partition by id_candidato_sisu order by data_alteracao desc) as pos 
    from ingresso.alteracao_status_candidato_sisu
)
select *
from com_pos 
where pos = 1;

explain
with com_pos as (
    select *, first_value(data_alteracao) over(partition by id_candidato_sisu order by data_alteracao desc) as ult_data 
    from ingresso.alteracao_status_candidato_sisu
)
select *
from com_pos 
where data_alteracao = ult_data;



-- EXERCÍCIO

-- 4. Analisar a estrutura do esquema tmdb, contendo informações sobre filmes(sugestão: gerar um diagrama ER do esquema) 
--    Desenvolva sql que retorne o título(title) de todos os filmes cujo gênero inclui Action ou Comedy
--       ordenado pelo título ascendente


-- 5. Desenvolva sql que retorne todas as companhias que possuem pelo menos um filme com vote_average = 10



-- 6. Desenvolva sql que retorne todos os filmes que possuam as seguintes combinações de gênero e keyword
--       ('Comedy', 'fate')
--       ('Drama', 'court case')
--       ('Thriller', 'adventure')