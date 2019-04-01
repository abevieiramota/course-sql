-- cost of count(*)
--    seq_scan

begin;
    create temporary table a as select * from generate_series(1, (10^6)::int) as t(i);
    analyze a;


    explain analyze
    select count(*) from a;
    
    explain analyze
    select reltuples::integer
    from pg_class
    where relname = 'a' and relpersistence = 't';

rollback;




-- cost of index on updates and size

begin;

    create temporary table a (id int);
    
    -- 2467
    explain analyze
    insert into a select * from generate_series(1, (10^6)::int);
    
    select pg_size_pretty(pg_relation_size('a'));

rollback;


--    one index
begin;
    
    create temporary table a (id int);
    create index a_id_idx on a(id);
    
    -- 3740
    explain analyze
    insert into a select * from generate_series(1, (10^6)::int);
    
    select pg_size_pretty(pg_relation_size('a') + pg_relation_size('a_id_idx'));

rollback;

--    two indexes
begin;
    create temporary table a (id int);
    create index a_id_idx on a(id);
    create index a_id_idx2 on a(id);
    
    -- 4500
    explain analyze
    insert into a select * from generate_series(1, (10^6)::int);
    
    select pg_size_pretty(pg_relation_size('a') + pg_relation_size('a_id_idx') + pg_relation_size('a_id_idx2'));

rollback;


-- !!!!!!!!! parei aqui !!!!!!!!!!!

-- cost of index on delete of referrenced
--    a references b
--    deletando b eu tenho que verificar se não há alguém em a apontando pra ele

-- sem index
create temporary table a as select i from generate_series(1, (10^5)::int) as t(i);
analyze a;

create temporary table b as select i from generate_series(1, (10^5)::int + 1000) as t(i);
alter table b add constraint b_i_ok primary key (i);
analyze b;

alter table a add constraint a_b_fk foreign key (i) references b(i);

-- deletando valores que não são referenciados por a
--    8s
explain analyze 
delete from b
where i > (10^5)::int;

drop table a;
drop table b;

-- com index
create temporary table a as select i from generate_series(1, (10^5)::int) as t(i);
analyze a;

create temporary table b as select i from generate_series(1, (10^5)::int + 1000) as t(i);
alter table b add constraint b_i_ok primary key (i);
analyze b;

alter table a add constraint a_b_fk foreign key (i) references b(i);

create index a_i_idx on a(i);

-- deletando valores que não são referenciados por a
--    25ms
explain analyze 
delete from b
where i > (10^5)::int;

drop table a;
drop table b;




-- ok, tenho index, pode usar

--    50% 50%
create temporary table a as select (array[1, 2])[floor(random() * 2 + 1)] as i from generate_series(1, (10^5)::int);
analyze a;

select i, count(*) from a group by 1;
select * from a;

create index a_idx on a(i);

explain
select *
from a 
where i = 1;

drop table a;


-- ~99% ~1%
create temporary table a as select 1 as i from generate_series(1, (10^5)::int);
-- altera 10 valores para 2
update a 
set i = 2
where ctid in (
    select ctid 
    from a 
    limit 10
);

analyze a;

select i, count(*) from a group by 1;
select * from a;

create index a_idx on a(i);

-- ~99% dos dados -> seq scan
explain
select *
from a 
where i = 1;

-- ~1% dos dados -> idx scan
explain
select *
from a 
where i = 1;


-- Index only
create temporary table a (id int primary key, nome text, id2 int);

insert into a 
select i, substring('abcdefghijlmnopqrstuvxz', floor(random() * 5 + 1)::int, floor(random() * 5 + 1)::int + 5), i*2
from generate_series(1, 1000) as t(i);

analyze a;

create index a_id2_nome_idx on a(id2, nome);

explain
select *
from a
where id2 = 10;

explain
select id, nome
from a
where id2 = 10;


-- Postgresql performance in 15 minutes

-- Slow queries > cut activity > scale stack > fix hardware > postgresql.conf

-- cut activity
--    cache
--    data access anti pattern
--       pooling -> while true > execute query, test continue
--       do joins in application
--       resource hungry queries
--          add index
--          fix filter expressions
--          analyze/auto analyze
--       look up data you alread have
--       look up data you don't need
--          rows you don't need
--          columns you don't need
--          data to do calculations the DB could do
-- 
-- scaling infra
--    load balance -> separate special workloads -> {reporting, cache refresh, querying}



-- size of row 
select relnamespace::oid
from pg_class;

select relname, 
pg_size_pretty(sum(pg_column_size(c.attrelid)))
from pg_catalog.pg_attribute c
inner join pg_catalog.pg_class as pc on pc.oid = c.attrelid
inner join pg_catalog.pg_namespace as n on n.oid = pc.relnamespace
where n.nspname not in ('information_schema', 'pg_catalog') and n.nspname !~ '^pg_toast'
--where attnum > 0
group by 1
order by sum(pg_column_size(c.attrelid)) desc;



-- functional index 

create temporary table a (id int);

create index a_id_idx on a((id % 2));

insert into a select * from generate_series(1, 1000);

explain
select *
from a
where id % 2 = 0
order by id asc;

update a set id = 3 where id = 2;