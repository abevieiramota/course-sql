-- 1.

-- ex:
--    top 10 -> necessário identificar os 10 maiores valores
--    top 10 offset 10 -> necessário identificar os 20 maiores valores!
--    top 10 offset 20 -> necessário identificar os 30 maiores valores!
-- custoso para paginação > sort tabela toda, dropa N pega X
-- > isso em cada chamada à pag > https://use-the-index-luke.com/no-offset


-- 2.

select table_schema, table_name, 
pg_size_pretty(pg_relation_size(table_schema || '.' ||table_name)) as table_size,
pg_size_pretty(pg_total_relation_size(table_schema || '.' ||table_name)) as table_total_size
from information_schema.tables 
where table_schema not in ('information_schema', 'pg_catalog')
order by table_size desc
limit 10;



-- 3.

-- observar o custo de order by


-- 4.

select 
-- av_needed 
--    # retorna true se n_dead_tup > av_threshold
n_dead_tup > av_threshold as av_needed,
-- pc_dead
--    # se reltuples > 0 então
--         retorna o arredondamento(inteiro mais próximo) de (n_dead_tup / reltuples, multiplicado por 100)
--         uma porcentagem
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
	pg_stat_get_tuples_inserted(C.oid) as n_tup_ins,
	pg_stat_get_tuples_updated(C.oid) as n_tup_upd,
	pg_stat_get_tuples_deleted(C.oid) as n_tup_del,
	-- HOT_update_ratio 
	--    # proporção de tuples_hot_updated dividido por tuples_updated
	--         caso tuples_updated = 0, retorna 0(pois hot_updated vai ser = 0 também)
	pg_stat_get_tuples_hot_updated(C.oid)::numeric / 
	COALESCE(NULLIF(pg_stat_get_tuples_updated(C.oid), 0), 1) as "HOT_update_ratio",
	pg_stat_get_live_tuples(C.oid) as n_live_tup,
	pg_stat_get_dead_tuples(C.oid) as n_dead_tup,
	c.reltuples as reltuples,
	-- av_threshold
	--    # arredondamento de 
	--         autovacuum_vacuum_threshold + 
	--         autovacuum_vacuum_scale_factor * reltuples
	round(current_setting('autovacuum_vacuum_threshold')::integer + current_setting('autovacuum_vacuum_scale_factor')::numeric * c.reltuples) as av_threshold,
	-- last_vacuum 
	--    # trunca até os minutos de 
	--         o maior valor entre
	--            last_vacuum_time
	--            last_autovacuum_time
	date_trunc('minute', greatest(pg_stat_get_last_vacuum_time(c.oid), pg_stat_get_last_autovacuum_time(c.oid))) as last_vacuum,
	-- last_analyze
	--    # trunca até os minutos de 
	--         o maior valor entre
	--            last_analyze_time
	--            last_autoanalyze_time
	date_trunc('minute', greatest(pg_stat_get_last_analyze_time(c.oid), pg_stat_get_last_autoanalyze_time(c.oid))) as last_analyze
	from pg_class c 
	left join pg_index i on c.oid = i.indrelid
	left join pg_namespace n on n.oid = c.relnamespace
	where c.relkind in ('r', 't')
	and n.nspname not in ('pg_catalog', 'information_schema')
	-- TOAST 
	-- The Oversized-Attribute Storage Technique
	--    técnica de armazenamento de registros que não caibam no tamanho de página do PostgreSQL(normalmente 8kB)
	--    os dados são quebrados em pedaços que caibam em páginas, e o PostgreSQL lida com o processo
	--    de 'quebra' e 'remontagem' dos dados
	and n.nspname !~ '^pg_toast'
) as av 
order by av_needed desc, n_dead_tup desc;


-- 5.

SELECT schemaname, relname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan asc
LIMIT 10;

