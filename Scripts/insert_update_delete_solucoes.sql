-- 1.

begin;
    create temporary table a as select * from tmdb.movie;
    
    update a 
    set title = format('O título é %s e seus gêneros são [%s]', t.title, t.genres)
    from 
        (
            select m.id, m.title, string_agg(g.genre, ', ') as genres
            from a m 
            left join tmdb.movie_genre mg on mg.movie_id = m.id 
            left join tmdb.genre g on mg.genre_id = g.id 
            group by m.id, m.title
        ) as t 
    where t.id = a.id;
    
    select * from a where id = 191229;
    
rollback;
