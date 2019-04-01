-- https://www.postgresql.org/docs/9.2/static/queries-with.html

-- notação
--    WITH [RECURSIVE] cte_name[(column_name[, column_name])] AS ( cte_definition )



-- legibilidade

-- comparando os 10 filmes mais populares dos anos 2010 e 2009
with movies_2010 as (
	select *, row_number() over(order by popularity desc) as n
	from tmdb.movie
	where release_date >= '2010-01-01' and release_date < '2011-01-01'
	order by popularity desc
	limit 10
), movies_2009 as (
	select *, row_number() over(order by popularity desc) as n
	from tmdb.movie
	where release_date >= '2009-01-01' and release_date < '2010-01-01'
	order by popularity desc
	limit 10
)
select m9.title as "2009", m9.popularity, m10.title as "2010", m10.popularity
from movies_2010 m10
inner join movies_2009 m9 on m9.n = m10.n
order by m9.n asc;



-- reuso
--    adiciona o total
with filmes_2016 as (
	select title, revenue, 0 as pos
	from tmdb.movie
	where release_date >= '2016-01-01' and release_date < '2017-01-01'
),
total_revenue as (
	-- reusa a consulta acima
	select 'Total revenue' as title, sum(revenue) as revenue, 1 as pos
	from filmes_2016
)
select * from total_revenue

union all

select * from filmes_2016

order by pos desc, revenue desc;



-- with indica pro banco para executar a consulta de forma isoladas das demais partes do SQL
--    potencialmente impedindo de realizar algumas otimizações
--    pro planner há duas consultas para otimizar isoladas e depois juntar
--    no lugar de uma grande consulta, que ele poderá otimizar
--    reduz-se o espaço de busca

-- há dois filtros, que podem ser utilizados ao mesmo tempo 
--    com CTE > aplica os filtros separadamente
explain analyze
with movies as (select * from tmdb.movie where extract(year from release_date) = 2016)
select *
from movies m
inner join tmdb.movie_genre mg on mg.movie_id = m.id
inner join tmdb.genre g on g.id = mg.genre_id
where genre = 'genero que não existe'; 

explain analyze
select *
from tmdb.movie m
inner join tmdb.movie_genre mg on mg.movie_id = m.id
inner join tmdb.genre g on g.id = mg.genre_id
where genre = 'genero que não existe' and extract(year from release_date) = 2016; 



-- recursivo

-- estrutura
--    não recursivo
--       union[all]
--    recursivo

-- funcionamento: adiciona não recursivo a uma tabela temporária e à saída e vai iterando sobre a recursão, removendo a tabela temporária
--    até não retornar mais nada pra tabela temporária
with recursive t(n) as (
	-- primeiro valor
    values (1)
    -- união com os próximos valores
    union all
    -- t é a tabela temporária -> lê de lá, limpa a tabela e coloca lá o retorno da iteração
    --    até ficar vazia
    select n + 1 from t where n < 100
)
select sum(n) from t;

select sum(i) from generate_series(1, 100) as t(i);



-- utilizado com dados hierárquicos

begin;

    create temporary table grafo (node_1 integer, node_2 integer);
    
    -- um caminho simples
    --    1->2->3->4->5->6
    insert into grafo values (1, 2), (2, 3), (3, 4), (4, 5), (5, 6);
    -- algumas bifurcações
    --    2->5 4->8
    insert into grafo values (2, 5), (4, 8);

	select * from grafo;
    
	-- nós que posso alcançar a partir do nó 1
    with recursive t(o) as (
    	-- parto de 1
        values (1)
        -- vou adicionando
        union 
        -- os nós adjacentes a ele, depois os adjacentes aos adjacentes
        select g.node_2
        from grafo g
        -- adiciono os nós em g tal que o nó inicial é um dos nós já alcançados
        inner join t on t.o = g.node_1
    )
    select *
    from t;
    
    -- e se tiver ciclo?
    insert into grafo values (2, 1);
    
    -- com union, o 1 novamente alcançado(pelo path (2,1)) não é adicionado
    with recursive t(o) as (
        values (1)
        
        union
        
        select g.node_2
        from grafo g
        inner join t on t.o = g.node_1
    )
    select *
    from t;
    
    -- com union all sim
    --    e aí não tem ponto de término! limit pra parar
    with recursive t(o) as (
        values (1)
        
        union all
        
        select g.node_2
        from grafo g
        inner join t on t.o = g.node_1
    )
    select *
    from t
    limit 100;
    
rollback;



-- Exercício
-- 1. Desenvolva um sql que retorne todas as subunidades de uma dada unidade
--       incluir apenas as subunidades, não incluir a unidade pesquisada
--    Extra: adicione uma coluna 'Nível' indicando quão distante a unidade está da unidade pesquisada
--       por exemplo, para UFC, a STI está no nível 1, a DSI no nível 2

begin;
    create temporary table unidade (id int primary key, id_superunidade int references unidade(id), nome text);
    insert into unidade values 
        (1, null, 'UFC'),
        (2, 1, 'STI'),
        (3, 2, 'DSI'),
        (4, 2, 'DRC'),
        (5, 2, 'DPU'),
        (6, 2, 'DAD'),
        (7, 1, 'PROGRAD'),
        (8, 7, 'COPIC'),
        (9, 7, 'COPAC'),
        (10, 9, 'COPAC.1');
        
    select * from unidade;
    
rollback;
    
    
    

-- mover registros + cláusula returning
--    executem e tentem entender

begin;

    create temporary table a (numero int);
    insert into a select generate_series(1, 100);

	select * from a;
    
    create temporary table b (numero int);
    create temporary table c (numero int);
    
    -- é possível encadear chamadas a delete, insert, select etc
    --    ! não é possível atualizar ou deletar rows que foram inseridas
    --       cada CTE(common table expression) vai ter acesso ao mesmo snapshot dos dados
    --       a forma de comunicar entre eles é através de returnings
    with deletados as (
    	-- deleta
        delete from a
        -- e retorna
        returning numero
    ), insere_em_b as (
        insert into b
        select * from deletados
    )
    insert into c 
    select * from deletados;
    
	select * from a;
    select * from b;
    select * from c;
    
rollback;



-- Exercício
-- 2. Desenvolva um sql que remova todos os registros na tabela A 
--    e adicione à tabela B os registros removidos cujo id é múltiplo de 2 
--    e adicione à tabela C os registros removidos cujo id é múltiplo de 3
--    tudo em um sql só, usando with
begin;
    
    create temporary table a as select id from generate_series(1, 10000) as t(id);
    create temporary table b (id int check (id % 2 = 0));
    create temporary table c (id int check (id % 2 = 1));
    
rollback;



-- update > você pode retornar os valores antes ou depois do update
begin;

    create temporary table a as select * from generate_series(1, 10) as t(i);
    
    select * from a;
    
    -- retorna os valores após o update 
	--    select na CTE definida no with
	--    retorna os valores retornados > retornados no returning > valores que foram atualizados
    with u as (update a set i = i + 1 returning *)
    select *
    from u;
    
    select * from a;
    
    -- retorna os valores antes do update
    --    select na própria tabela
    --    retorna os valores antes da operação
    with u as (update a set i = i + 1 returning *)
    select *
    from a;

	select * from a;
    
rollback;



-- Exercício
-- 3. Desenvolva um sql que insira na tabela B o valor antigo e o valor novo da coluna nome da tabela A
--       após o sql de update
begin;

    create temporary table a (id int, nome text);
    create temporary table b (id int, nome_antigo text, nome_novo text);
    
    insert into a values 
        (1, 'Curso de sql'),
        (2, 'DSI/STI'),
        (3, 'Fluent Python');
        
    with atualizados as (
        update a 
        set nome = format('%s %s', nome, id)
        returning *
    )
    -- seu sql aqui
    
rollback;



-- exemplo
--    soma da metade de 1, recursivo

with recursive t(x, y) as (
	values (0.0::numeric(200, 199), 0.5::numeric(200, 199))
	
	union all 
	
	select (x + y)::numeric(200, 199), (y / 2.0)::numeric(200, 199)
	from t
)
select *
from t 
limit 100;