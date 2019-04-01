select *
from information_schema.tables
where table_schema not in ('information_schema', 'pg_catalog');

select pg_size_pretty(pg_database_size(current_database()));

select pg_size_pretty(sum(pg_database_size(datname))) from pg_database;

select pg_size_pretty(pg_relation_size('bens'));
select pg_size_pretty(pg_total_relation_size('bens'));

select table_name, 
pg_size_pretty(pg_relation_size(table_name)) as table_size,
pg_size_pretty(pg_total_relation_size(table_name)) as table_total_size
from information_schema.tables 
where table_schema not in ('information_schema', 'pg_catalog')
order by table_size desc
limit 10;


set work_mem = '100MB';
explain analyze 
select * from generate_series(1, 5000000) as t(i) order by i;


select *
from pg_settings;


select
table_schema, table_name, column_name, format('%s %s %s %s', data_type, character_maximum_length, numeric_precision, numeric_scale) as data_type
from information_schema.columns 
where column_name in (
	select column_name 
	from information_schema.columns 
	group by 1
	having count(*) > 1
)
and table_schema not in ('information_schema', 'pg_catalog');


select t1.column_name = t2.column_name, t1.column_name as t1_col, t1.data_type as t1_type, t2.column_name as t2_col, t2.data_type as t2_type 
from (
	select column_name, data_type
	from information_schema.columns
	where table_schema = 'public' and table_name = 'bens' 
) t1
full outer join (
	select column_name, data_type
	from information_schema.columns
	where table_schema = 'public' and table_name = 'candidato' 
) t2 on t1.column_name = t2.column_name
order by 1, 2, 4;


select 
(random() * (2 * 10 ^ 9))::integer, 
(random() * (9 * 10 ^ 18))::bigint,
(random() * 100.)::numeric(4, 2),
repeat('*', (random() * 40)::integer),
substr('abcdefghijklmnopqrtuvwxyz', 1, (random() * 26)::integer),
(array['um', 'dois', 'tres', 'quatro'])[1 + random() * 3]
from generate_series(1, 10)
-- observar que apenas uma chamada a random() é feita por row, todos random() são iguais
order by random();


select *
from pg_catalog.pg_stat_activity;

begin;

select *
from pg_catalog.pg_stat_activity w 
inner join pg_catalog.pg_locks l1 on w.pid = l1.pid and not l1."granted"
inner join pg_catalog.pg_locks l2 on l1.relation = l2.relation and l2."granted"
inner join pg_catalog.pg_stat_activity l on l2.pid = l.pid
inner join pg_catalog.pg_stat_user_tables t on l1.relation = t.relid 
where w.wait_event is not null;

select *
from pg_catalog.pg_locks;
