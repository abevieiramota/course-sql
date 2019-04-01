-- 1.

select '{oi, "NULL"}'::text[];

select array['oi', 'NULL'];



-- 2.
select regexp_replace(
        array_dims('[234:236]={2, 3, 4}'::int[]),
        '\[(\d+):(\d+)\]',
        'O array tem índices que vão de \1 até \2'
        );

        
select format('O array tem índices que vão de %s até %s',
                array_lower('[234:236]={2, 3, 4}'::int[], 1),
                array_upper('[234:236]={2, 3, 4}'::int[], 1));

                
-- 3.

                explain analyze
select c.company
from tmdb.company c 
inner join tmdb.production_company pc on pc.company_id = c.id 
inner join tmdb.movie m on m.id = pc.movie_id 
inner join tmdb.movie_genre mg on mg.movie_id = m.id
inner join tmdb.genre g on g.id = mg.genre_id
group by c.company
-- pressupõe que não há gênero repetido por filme
having count(distinct case when g.genre in ('Action', 'Horror', 'Animation', 'War', 'Music') then g.genre end) = 5
order by 1 asc;


-- testes usando lógica do AND -> falhou primeiro, abandona
explain analyze
with movie_do_genre as (
    select pc.company_id, g.genre
    from tmdb.movie m 
    inner join tmdb.movie_genre mg on mg.movie_id = m.id
    inner join tmdb.genre g on g.id = mg.genre_id 
    inner join tmdb.production_company pc on pc.movie_id = m.id 
)
select c.company
from tmdb.company c 
where 
exists (select * from movie_do_genre mg where mg.genre = 'Action' and mg.company_id = c.id) and
exists (select * from movie_do_genre mg where mg.genre = 'Horror' and mg.company_id = c.id) and
exists (select * from movie_do_genre mg where mg.genre = 'Animation' and mg.company_id = c.id) and
exists (select * from movie_do_genre mg where mg.genre = 'War' and mg.company_id = c.id) and
exists (select * from movie_do_genre mg where mg.genre = 'Music' and mg.company_id = c.id)
order by 1 asc;



-- intersect
explain analyze 
select c.company
from tmdb.company c 
inner join tmdb.production_company pc on pc.company_id = c.id 
inner join tmdb.movie_genre mg on mg.movie_id = pc.movie_id
inner join tmdb.genre g on g.id = mg.genre_id
where g.genre = 'Action'

intersect

select c.company
from tmdb.company c 
inner join tmdb.production_company pc on pc.company_id = c.id 
inner join tmdb.movie_genre mg on mg.movie_id = pc.movie_id
inner join tmdb.genre g on g.id = mg.genre_id
where g.genre = 'Horror'

intersect

select c.company
from tmdb.company c 
inner join tmdb.production_company pc on pc.company_id = c.id 
inner join tmdb.movie_genre mg on mg.movie_id = pc.movie_id
inner join tmdb.genre g on g.id = mg.genre_id
where g.genre = 'Animation'

intersect

select c.company
from tmdb.company c 
inner join tmdb.production_company pc on pc.company_id = c.id 
inner join tmdb.movie_genre mg on mg.movie_id = pc.movie_id
inner join tmdb.genre g on g.id = mg.genre_id
where g.genre = 'War'

intersect

select c.company
from tmdb.company c 
inner join tmdb.production_company pc on pc.company_id = c.id 
inner join tmdb.movie_genre mg on mg.movie_id = pc.movie_id
inner join tmdb.genre g on g.id = mg.genre_id
where g.genre = 'Music';



-- 4.

-- agrupamentos primeiro, só então teste
explain analyze
select c.company, array_agg(distinct g.genre)
from tmdb.company c 
inner join tmdb.production_company pc on pc.company_id = c.id 
inner join tmdb.movie m on m.id = pc.movie_id 
inner join tmdb.movie_genre mg on mg.movie_id = m.id
inner join tmdb.genre g on g.id = mg.genre_id
group by c.company 
having array_agg(g.genre::text) @> array['Action', 'Horror', 'Animation', 'War', 'Music'];

