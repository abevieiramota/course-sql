-- 1.
--explain analyze
SELECT * 
FROM information_schema.columns
where 
data_type in (
    select data_type 
    from information_schema.columns
    where table_schema not in ('information_schema', 'pg_catalog')
    group by 1 
    order by count(*) desc 
    limit 2
)
and table_schema not in ('information_schema', 'pg_catalog');

-- observar que na consulta de cima é utilizado, mais ou menos, o mesmo conjunto
--    mas a outer query tem outro filtro
--explain analyze
with columns_ok as (
    select * 
    from information_schema.columns
    where table_schema not in ('information_schema', 'pg_catalog')
)
select *
from columns_ok
where data_type in (
    select data_type 
    from columns_ok
    group by 1 
    order by count(*) desc 
    limit 2
);



-- 2.
-- não retorna null -> null in (...) = null sempre
with tabela(v) as (values (1), (3), (NULL), (NULL), (10))
select *
from tabela
where v in (1, 2, 3, null);

-- tendo controle sobre a lista, eu posso excluir os nulls, removendo da lista hardcoded
with tabela(v) as (values (1), (3), (NULL), (NULL), (10))
select *
from tabela
where v in (1, 2, 3) or v is null;

-- mas se eu não tenho controle?(lista retornada por subconsulta, por exemplo)
--    supõe que não há valores repetidos na subconsulta
with tabela(v) as (values (1), (3), (NULL), (NULL), (10))
select t.*
from tabela t 
inner join (values (1), (2), (3), (null)) v(v) on v.v is not distinct from t.v;

with tabela(v) as (values (1), (3), (NULL), (NULL), (10))
select *
from tabela
-- converto NULL para um valor com significado, dos dois lados
where coalesce(v::text, 'NÃO INFORMADO') in (select coalesce(i::text, 'NÃO INFORMADO') from (values (1), (2), (3), (null)) as t(i)); 



-- 3.
--explain
select schema_name
from information_schema.schemata s
where exists (
	select *
	from pg_catalog.pg_stat_user_tables t 
	-- mesmo schema
	where s.schema_name = t.schemaname and 
	(
		-- as duas datas são null
		coalesce(t.last_vacuum, t.last_autovacuum) is null or
		-- a maior delas foi há mais de 10 dias
		(current_date - greatest(t.last_vacuum, t.last_autovacuum) > '10 minutes'::interval)
	)
);

--explain
select distinct schema_name 
from information_schema.schemata s 
inner join pg_catalog.pg_stat_user_tables t on s.schema_name = t.schemaname
where coalesce(t.last_vacuum, t.last_autovacuum) is null or
current_date - greatest(t.last_vacuum, t.last_autovacuum) > '10 minutes'::interval;

--explain
select schema_name 
from information_schema.schemata s 
inner join pg_catalog.pg_stat_user_tables t on s.schema_name = t.schemaname
group by 1
having bool_or(coalesce(t.last_vacuum, t.last_autovacuum) is null or
                current_date - greatest(t.last_vacuum, t.last_autovacuum) > '10 minutes'::interval);
                
--explain
select schema_name 
from information_schema.schemata s 
inner join pg_catalog.pg_stat_user_tables t on s.schema_name = t.schemaname
group by 1
having count(case when 
                coalesce(t.last_vacuum, t.last_autovacuum) is null or
                current_date - greatest(t.last_vacuum, t.last_autovacuum) > '10 minutes'::interval
                  then 1
             end) > 0;


-- 4.
explain analyze
select distinct m.title
from tmdb.movie m 
inner join tmdb.movie_genre mg on mg.movie_id = m.id 
inner join tmdb.genre g on g.id = mg.genre_id
where g.genre in ('Action', 'Comedy')
order by 1 asc;

-- com union
explain analyze
select m.title 
from tmdb.movie m 
inner join tmdb.movie_genre mg on mg.movie_id = m.id 
inner join tmdb.genre g on g.id = mg.genre_id
where g.genre = 'Action'

union

select m.title 
from tmdb.movie m 
inner join tmdb.movie_genre mg on mg.movie_id = m.id 
inner join tmdb.genre g on g.id = mg.genre_id
where g.genre = 'Comedy'

order by 1 asc;


-- 5.

explain 
select distinct company
from tmdb.company c 
inner join tmdb.production_company pc on pc.company_id = c.id
inner join tmdb.movie m on m.id = pc.movie_id
where m.vote_average = 10;


-- com exists + correlated
explain
select company
from tmdb.company c
where exists (
	select *
	from tmdb.movie m 
	inner join tmdb.production_company pc on pc.movie_id = m.id
	where m.vote_average = 10 and pc.company_id = c.id 
)
order by 1 asc;

-- com in + não correlated
explain
select company
from tmdb.company c 
where c.id in (
    select company_id 
    from tmdb.production_company pc
    inner join tmdb.movie m on m.id = pc.movie_id
    group by 1
    having bool_or(m.vote_average = 10)
);


-- 6.
select distinct m.title
from tmdb.movie m 
inner join tmdb.movie_genre mg on mg.movie_id = m.id 
inner join tmdb.genre g on g.id = mg.genre_id
inner join tmdb.movie_keyword mk on mk.movie_id = m.id 
inner join tmdb.keyword k on k.id = mk.keyword_id
where (g.genre, k.keyword) in (
       ('Comedy', 'fate'),
       ('Drama', 'court case'),
       ('Thriller', 'adventure')
);