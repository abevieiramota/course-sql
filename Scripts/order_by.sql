-- sem order by a ordem dos resultado é indeterminada e depende da implementação que o banco der à consulta
-- !se a ordem é importante ela deve ser especificada!


-- por default order by é ASC(ascendente)
select title
from tmdb.movie
order by title;

-- DESC(descendente)
select title
from tmdb.movie
order by title desc;



-- é possível especificar uma ordem baseada em mais de uma coluna
select g.genre, m.title
from tmdb.movie m 
inner join tmdb.movie_genre mg on mg.movie_id = m.id 
inner join tmdb.genre g on g.id = mg.genre_id
order by g.genre, m.title;



-- como funciona nulls? 
--    funcionam como maiores valores, por default
-- últimos
select *
from (values (1), (null), (10), (-4), (null)) as t(x)
order by x;

-- primeiros
select *
from (values (1), (null), (10), (-4), (null)) as t(x)
order by x desc;

-- order by X nulls first
--    informa que os valores nulls devem ser retornados primeiro
select *
from (values (1), (null), (10), (-4), (null)) as t(x)
order by x nulls first;

-- order by X nulls last
--    informa que os valores nulls devem ser retornados por último
select *
from (values (1), (null), (10), (-4), (null)) as t(x)
order by x desc nulls last;



-- position
--    é possível utilizar a posição das colunas no select para indicar que colunas utilizar na ordenação
--       o mesmo com group by
--    mesma consulta de cima, ordenada usando a posição no select
--    ! risco de alterar a ordenação caso altere as colunas no select
select g.genre, m.title
from tmdb.movie m 
inner join tmdb.movie_genre mg on mg.movie_id = m.id 
inner join tmdb.genre g on g.id = mg.genre_id
order by 1, m.title;



-- alias
--    é possível ordenar referenciando colunas do resultado pelos seus alias
SELECT 1 + x AS x_1
FROM generate_series(1, 10) AS t(x)
ORDER BY x_1 ASC;

--    mas não pode criar uma expresão com o alias
SELECT 1 + x AS x_1
FROM generate_series(1, 10) AS t(x)
ORDER BY x_1 + 2 ASC;




-- limit
--    permite limitar a quantidade de resultados a serem retornados
--    informando que sejam retornados os N primeiros apenas

-- top 10
select title
from tmdb.movie
order by title
limit 10;


-- bottom 10
--    como pegar o bottom 10? 
--    bottom 10 = top 10 com ordem contrária
select title
from tmdb.movie
order by title desc
limit 10;




-- offset
--    permite ignorar os N primeiros registros do resultado
--    offset X limit Y -> começa em X+1 até X+Y

-- top 20 to 10
select title
from tmdb.movie
order by title
offset 10
limit 10;



-- offset e limit são mt utilizados para paginação de resultados
--    essa solução pode ser custosa porque envolve a ordenação de offset + limit!
--    quanto maiores as páginas, pior a performance!


--Exercício
-- 1. Execute o código abaixo e vá observando o tempo de execução quando o offset vai aumentando
--       por que isso ocorre?
begin;

    create temporary table paginacao as select * from generate_series(1, 10000000) as t(i);
    analyze paginacao;
    
    -- observar o custo de execução variando o offset
    --    páginas iniciais
    select * from paginacao order by i limit 10;
    select * from paginacao order by i offset 10 limit 10;
    --    páginas mais pra frente
    select * from paginacao order by i offset 999990 limit 10;
    
    -- observar o custo de execução utilizando uma coluna e valor de início e fim
    --    primeiras páginas
    select * from paginacao where i between 1 and 10;
    select * from paginacao where i between 11 and 20;
    --    páginas mais pra frente
    select * from paginacao where i between 999991 and 1000000;
    
    -- com index
    create index paginacao_i_idx on paginacao(i);
    
    --    páginas mais pra frente
    --    agora com index
    select * from paginacao where i between 999991 and 1000000;
   
rollback;



-- limit + distinct
--    o limit se aplica ao resultado da consulta
--    retorna 1, 2, 3 pois esse é o resultado de distinct x
--    e não 1, 2, que seria o resultado de distinct {1, 1, 2}
--    limit(distinct x)
--    e não distinct(limit x)
--    # ver plano
--explain
select distinct x 
from (values (1), (1), (2), (3)) as t(x)
order by x asc
limit 3;


-- EXERCÍCIO

-- 2. Desenvolva sql que retorne as 10 tabelas que mais ocupam espaço no banco
--       utilizar como base o seguinte SQL, que retorna as tabelas do banco, excluídas tabelas internas
select table_schema, table_name
from information_schema.tables
where table_schema not in ('information_schema', 'pg_catalog');
--       e a função pg_relation_size, que recebe um nome de tabela(<esquema>.<tabela>) e retorna o seu tamanho em bytes
--       Extra: formatar o tamanho das tabelas utilizando a função pg_size_pretty
--       https://www.postgresql.org/docs/9.4/static/functions-admin.html#FUNCTIONS-ADMIN-DBOBJECT


-- 3. Teste diversos parâmetros de work_mem para o sql abaixo
--       work_mem é um parâmetro do PostgreSQL, que pode ser setado por sessão, que indica o tanto de memória
--          que o PostgreSQL irá alocar para realizar operações de sort e hash(join)
--       observe qual o valor atual de work_mem > é o valor setado no banco de dados para ser o padrão
--       vá aumentando work_mem até que a ordenação deixe de ser feita em disco e passe a ser feita em memória
show work_mem;
--       set local informa ao PostgreSQL que essa configuração deve ser utilizada apenas na transação atual
--          é necessário que ou o explain analyze seja executado junto do set local numa transação só
--          ou que seja utilizado apenas o set, sem o local
--             que seta o configuração para toda a sessão
create temporary table series as select * from generate_series(1, 100000) as t(i);
analyze series;

explain analyze 
select * from series order by i;

set work_mem = '1MB';
explain analyze 
select * from series order by i;
--       para resetar o valor da configuração
reset work_mem;
-- ou
set work_mem to default;



-- 4. Analise o seguinte sql tente entender a definição dos campos com ?
--       dead tuples -> registros que o banco cria em operações de updat e delete e que não são mais necessários, mas continuam ocupando espaço
--       live tuples -> registros válidos
--       reltuples -> estimativa da quantidade de tuplas armazenadas, incluindo live e dead


select 
-- n_dead_tup -> quantidade de dead tuples
-- av_needed ?
n_dead_tup > av_threshold as av_needed,
-- pc_dead ?
case when reltuples > 0
	then round(100. * n_dead_tup / (reltuples))
	else 0
	end as pc_dead,
*
from (
	-- nspname -> schema
	-- relname -> nome da relação -> não apenas table, pode ser index, view etc
	select n.nspname, c.relname,
	-- pg_stat_get_* funções para recuperar algumas statistics de objetos
	--    recebem como entrada um identificador da relação, OID(object ID)
	-- https://www.postgresql.org/docs/9.1/static/monitoring-stats.html#MONITORING-STATS-FUNCS-TABLE
	pg_stat_get_tuples_inserted(C.oid) as n_tup_ins,
	pg_stat_get_tuples_updated(C.oid) as n_tup_upd,
	pg_stat_get_tuples_deleted(C.oid) as n_tup_del,
	-- HOT update -> Heap Only Tuple
	--    quando ocorre um update no PostgreSQL, ao invés de o registro ser atualizado
	--    é criado um novo registro, com a nova versão
	--    é necessário então que os indexes sejam atualizados, apontando para a posição em disco da nova versão
	--    Heap Only Update é uma otimização do PostgreSQL
	--    que no lugar de atualizar todos os indexes que apontam para o registro
	--    apenas indica, na versão antiga, que a versão nova está adjacente à versão antiga
	--    para que isso ocorra, é necessário que o registro adjacente à versão antiga esteja disponível para escrita(dead tuple ou empty)
	--    por ser uma versão otimizada de UPDATE, é interessante maximizar a proporção de HOT updates
	--    HOT updates não podem ser realizados quando alguma das colunas atualizadas estiver sendo indexada
	--       porque senão o index, potencialmente, deverá ser alterado, já que a alteração pode alterar a ordem da row no índice
	--    MINIMIZAR INDICES!
	-- HOT_update_ratio ?
	pg_stat_get_tuples_hot_updated(C.oid)::numeric / 
	COALESCE(NULLIF(pg_stat_get_tuples_updated(C.oid), 0), 1) as "HOT_update_ratio",
	pg_stat_get_live_tuples(C.oid) as n_live_tup,
	pg_stat_get_dead_tuples(C.oid) as n_dead_tup,
	c.reltuples as reltuples,
	-- estima um threshold para quando o autovacuum deve ser executado
	--    utiliza as configurações
	--       autovacuum_vacuum_threshold -> o mínimo de registros atualizados/deletados
	--       autovacuum_vacuum_scale_factor -> a proporção de registros da tabela atualizados/deletados
	-- av_threshold ?
	round(current_setting('autovacuum_vacuum_threshold')::integer + current_setting('autovacuum_vacuum_scale_factor')::numeric * c.reltuples) as av_threshold,
	-- last_vacuum ?
	date_trunc('minute', greatest(pg_stat_get_last_vacuum_time(c.oid), pg_stat_get_last_autovacuum_time(c.oid))) as last_vacuum,
	-- last_analyze ?
	date_trunc('minute', greatest(pg_stat_get_last_analyze_time(c.oid), pg_stat_get_last_autoanalyze_time(c.oid))) as last_analyze
	from pg_class c 
	left join pg_index i on c.oid = i.indrelid
	left join pg_namespace n on n.oid = c.relnamespace
	-- relkind -> informa o tipo da relação
	--    r -> tabela
	--    i -> index 
	where c.relkind in ('r', 'i')
	and n.nspname not in ('pg_catalog', 'information_schema')
	-- TOAST 
	-- The Oversized-Attribute Storage Technique
	--    técnica de armazenamento de registros que não caibam no tamanho de página do PostgreSQL(normalmente 8kB)
	--    os dados são quebrados em pedaços que caibam em páginas, e o PostgreSQL lida com o processo
	--    de 'quebra' e 'remontagem' dos dados
	and n.nspname !~ '^pg_toast'
) as av 
order by av_needed desc, n_dead_tup desc;


-- 5. Desenvolva um sql para retornar os 10 índices com menor frequência de uso
--       consultar a view pg_catalog.pg_stat_user_indexes
--       analisar a coluna idx_scan
--       retornar as colunas schemaname e relname, além de idx_scan