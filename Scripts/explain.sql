-- notação
--
--    <especificação da operacao> (cost=<custo de start>..<custo de finalizar> rows=<estimativa de rows> width=<tamanho em bytes a ser retornado>)
--       [detalhes da operação]

-- exemplo

-- ver no https://explain.depesz.com/
explain analyze
select * 
from tmdb.movie
where title = 'Dracula';



-- explain segue uma estrutura de árvore de operações
--    operações identificadas com um -> no começo da linha(a menos da operação na primeira linha)

-- no exemplo
--   Seq Scan on movie  (cost=0.00..360.04 rows=1 width=490)
--     Filter: ((title)::text = 'Dracula'::text)

--   Leitura(scan) sequencial(Seq) sobre a tabela movie(o esquema não é mostrado)
--      cost=0.00 -> o custo necessário para começar a retornar rows -> é basicamente ler do disco e jogar na rede -> custo 0
--         o custo inicial, por exemplo, para retornar dados ordenados é > 0
--      ..360.04  -> o custo para finalizar de retornar rows -> o quanto vai levar até a última row ser retornada
--         são estimativas, valores sem unidades, utilizados para comparar planos diferentes
--      rows=1 -> estimativa da quantidade de rows que serão retornadas
--      width=490 -> quantidade de bytes que será retornada por row


-- outro exemplo, com sort
--    verificar que o custo inicial é > 0
--    e próximo do custo final -> a maior parte do custo é composta pela ordenação
explain analyze
select *
from tmdb.movie
order by title asc;


-- outro exemplo > olhem o resultado e tentem entender

-- actual time e rows são médias sobre as execuções da operação
--    importante com operações executadas N vezes, como em nested loop
explain analyze
select *
from tmdb.movie m 
inner join tmdb.movie_genre mg on mg.movie_id = m.id 
inner join tmdb.genre g on g.id = mg.genre_id
where g.genre = 'Action';



-- Index Scan
--    agora surgiu um Index Scan
--    Leitura(scan) em índice(Index)
--       mas por que aqui há leitura em index e lá leitura sequencial?

begin;

    create temporary table expl (id int);
    insert into expl select * from generate_series(1, 1000);
    create index expl_id_idx on expl(id);
    analyze expl;
    
    -- consulta retorna apenas 1 valor
    --    index scan
    explain 
    select * from expl where id = 1000;
    
    -- remove valores e adiciona apenas 1s, 1000 vezes
    truncate expl;
    insert into expl select 1 from generate_series(1, 1000);
    analyze expl;
    
    -- index scan
    explain
    select * from expl where id = 1000;
    
    -- seq scan
    --    por que?!
    explain analyze
    select * from expl where id = 1;
    
    -- ah, quando id = 1 eu sei(estimo) que a frequência é 100%
    --    se é 100%, pra que ter o custo de pesquisar no index?
    --    analogia com livro -> não preciso procurar no índice todo o conteúdo
    --       se eu vou ler o livro todo -> custo desnecessário
    select most_common_vals, most_common_freqs
    from pg_catalog.pg_stats 
    where attname = 'id' and tablename = 'expl';
    
rollback;



-- o PostgreSQL gera todos os planos de execuções possíveis para um determinado SQL*
--    calcula o custo de suas operações e então executa aquele com menor custo ESTIMADO
--    essa estimativa é baseada em um conjunto de fatores
-- * planos possíveis dado um conjunto delimitado de regras de substituição(por exemplo: not exists x left join id null não é gerado)
-- * a partir de uma determinada quantidade de tabelas em join é utilizada uma abordagem que não irá testar todos os planos possíveis
-- genetic query optimization
show geqo_threshold;


-- fatores levados em consideração

--    1 - configurações do PostgreSQL, indicando o custo de operações básicas
--    https://www.postgresql.org/docs/9.2/static/runtime-config-query.html#RUNTIME-CONFIG-QUERY-CONSTANTS

--    custo de executar a leitura sequêncial de uma page(menor estrutura que o PostgreSQL usa para armazenar rows)
show seq_page_cost;
--    custo de executar a leitura randomica de uma page
show random_page_cost;
--    custo de processar uma tupla de tabela
show cpu_tuple_cost;
--    custo de processar uma tupla de índex
show cpu_index_tuple_cost;
--    custo de executar uma função(por exemplo um format())
show cpu_operator_cost;


-- exemplo

begin;
    create temporary table a (id int);
    -- 100 1s
    insert into a select 1 from generate_series(1, 100);
    
    -- observar o custo estimado
    explain select * from a where id = 1;
    
    set seq_page_cost = 100;

    -- não há outro plano possível! mas o custo estimado aumento
    explain select * from a where id = 1;
    
    -- adicionando index
    create index a_id_idx on a(id);
    
    -- custo de scan sequencial está mais alto que indexado
    explain select * from a where id = 1;
    
    -- resetando o parâmetro
    set seq_page_cost to default;
    
    -- voltando ao normal -> scan na tabela toda, scan sequencial
    explain select * from a where id = 1;
    
rollback;



--    2 - estatísticas das tabelas/colunas

--       estatística das tabelas
--       https://www.postgresql.org/docs/9.3/static/catalog-pg-class.html
select n.nspname, c.relname, c.reltuples::int,
-- relpages não é reltuples / page_size? cuidado pois podem haver várias versões ao mesmo tempo de um mesmo registro lógico(transações)
--    além disse há as dead tuples
c.relpages
from pg_catalog.pg_class c
inner join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname not in ('information_schema', 'pg_catalog') and n.nspname !~ '^(pg_toast|pg_temp)';


--       estatística das colunas
--       https://www.postgresql.org/docs/9.3/static/view-pg-stats.html
select schemaname, tablename, attname, null_frac, avg_width, 
case when n_distinct > 0 then format('%s = distinct values', n_distinct)
     when n_distinct < 0 then format('%s = distinct values / number of rows', abs(n_distinct))
     else 'dunno' end, 
most_common_vals, most_common_freqs, histogram_bounds, correlation
from pg_catalog.pg_stats
where schemaname !~ '^(pg_toast|pg_temp)' and schemaname not in ('information_schema', 'pg_catalog');

-- statistics target of columns
select attname, 
case when attstattarget < 0 then current_setting('default_statistics_target')::int
     else attstattarget end 
from pg_catalog.pg_attribute;



-- é possível desabilitar/habilitar algumas operações
-- https://www.postgresql.org/docs/9.2/static/runtime-config-query.html

begin;
    create temporary table a (id int);
    insert into a select 1 from generate_series(1, 100);
    create index a_id_idx on a(id);
    analyze a;
    
    -- seq scan cost 2.25
    explain select * from a where id = 1;
    
    set enable_seqscan to off;
    
    -- index scan cost 14.00
    explain select * from a where id = 1;
    
    set enable_indexscan to off;
    
    -- bitmap heap scan cost 9.03..14.28
    explain select * from a where id = 1;
    
    set enable_bitmapscan to off;
    
    -- seq scan de novo! -> mas agora com um custo altíssimo(comportamento do set enable_seqscan to off)
    explain select * from a where id = 1;
rollback;


-- estimativa de rows -> o PostgreSQL pode estar enganado!

begin;

    -- 100k rows com 1
    create temporary table a as select 1 as i from generate_series(1, 100000);
    
    -- PostgreSQL acha que há 532 rows com 1s
    --    mas todas são 1!
    explain 
    select * from a where i = 1;
    
    -- vamos ver as estatísticas para essa coluna
    --    nem tem ainda!
    select schemaname, tablename, attname, null_frac, avg_width, 
    case when n_distinct > 0 then format('%s = distinct values', n_distinct)
         when n_distinct < 0 then format('%s = distinct values / number of rows', abs(n_distinct))
         else 'dunno' end, 
    most_common_vals, most_common_freqs, histogram_bounds, correlation
    from pg_catalog.pg_stats
    where tablename = 'a' and attname = 'i';

    -- analizando
    analyze a;
    
    -- agora tem
    --    ver n_distinct e most_common_freqs
    select schemaname, tablename, attname, null_frac, avg_width, 
    case when n_distinct > 0 then format('%s = distinct values', n_distinct)
         when n_distinct < 0 then format('%s = distinct values / number of rows', abs(n_distinct))
         else 'dunno' end, 
    most_common_vals, most_common_freqs, histogram_bounds, correlation
    from pg_catalog.pg_stats
    where tablename = 'a' and attname = 'i';
    
    -- testando novamente
    --    agora com estatísticas atualizadas, o PostgreSQL tem uma estimativa melhor e responde que serão retornadas 100000 rows
    explain 
    select * from a where i = 1;

    -- e se eu alterar uma row?
    update a 
    set i = 123
    where ctid = (select max(ctid) from a);
    
    -- estimativa positiva -> pelo menos uma
    explain 
    select * from a where i = 123;
    
    analyze a;
    
    -- agora ele sabe que o 1 não é o único valor
    --    ver n_distinct e most_common_freqs
    select schemaname, tablename, attname, null_frac, avg_width, 
    case when n_distinct > 0 then format('%s = distinct values', n_distinct)
         when n_distinct < 0 then format('%s = distinct values / number of rows', abs(n_distinct))
         else 'dunno' end, 
    most_common_vals, most_common_freqs, histogram_bounds, correlation
    from pg_catalog.pg_stats
    where tablename = 'a' and attname = 'i';

    -- e isso se reflete na estimativa de valores a serem retornados com i = 1
    explain 
    select * from a where i = 1;
    
rollback;


-- e width?

-- 490 bytes estimados em média por row
explain 
select * from tmdb.movie;

-- 16 bytes
explain 
select title from tmdb.movie;



-- !!!!! parei aqui !!!!!
-- where (count(*)) > 0    x    where exists (*)

begin;

    create temporary table b (id int primary key);
    insert into b values (1), (2), (3);
    
    create temporary table a (id int, id_b int references b(id));
    insert into a 
    select i, (i % 3) + 1
    from generate_series(1, 100000) as t(i);
    
    analyze a;
    analyze b;
    
    select id_b, count(*)
    from a 
    group by 1;
    
    explain analyze
    select distinct a.id
    from a 
    inner join b on b.id = a.id_b
    where b.id in (1, 2);
    
    explain analyze
    select a.id
    from a 
    where a.id_b in (select * from b where b.id in (1, 2));
    
    -- segunda opção responde mais rápido a consultas limitadas
    
    explain analyze
    select a.id
    from a 
    where a.id_b in (select * from b where b.id in (1, 2))
    limit 10;
    
    explain analyze
    select distinct a.id
    from a 
    inner join b on b.id = a.id_b
    where b.id in (1, 2)
    limit 10;
    
rollback;



-- frequência relativa por original_language
explain analyze
select original_language, count(*) as n, (count(*) / (select count(*) from tmdb.movie)::numeric) as freq
from tmdb.movie
group by 1
order by 2 desc;

-- reusing previous calculated rows
explain analyze
with c as (
	select original_language, count(*) as n
	from tmdb.movie
	group by 1
)
select original_language, n, n / sum(n) over() as freq
from c
order by 2 desc;