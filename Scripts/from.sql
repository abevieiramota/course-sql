-- values list
--    retorna uma lista de rows
--    same as select * from (values (1), (2)) t;
values (1), (2);

-- equivalente a
--    select select_list from table_expression

-- exemplo de uso com union
values (1), (2)

union 

values (3);


-- com limit/offset
values (1), (15), (-3) limit 2 offset 1;

-- com order by 
values (1), (3), (2) order by 1;



-- exemplo de utilização
--    insert
--       observar que é
--       INSERT INTO <TABELA> <EXPRESSÃO QUE RETORNE VALORES -> {SELECT, VALUES}>
insert into tabela values (1, 2, 3);
--    adicionar colunas
--       por exemplo, quando tenho uma informação válida durante o ano
--          e quero retornar uma row por semestre, informando que a informação é válida
select original_title, i from tmdb.movie, (values (1), (2)) as t(i);
--    outra solução
select original_title, unnest(array[1, 2]) from tmdb.movie;




-- inner join
--    mantém apenas rows das duas fontes que têm match
--    a ordem entre inner joins é irrelevante para o resultado lógico, normalmente o planner reescreve essa ordem
--       mas importa para o optimizer! quando a otimização não é feita exaustivamente, usam-se heurísticas
--       parte do estado inicial da heurística pode ser afetada pela ordem entre os inner joins!
--    !sequência de inner joins! o mesmo não se aplica a outer joins
--    !mas, é possível informar ao planner para não alterar essa ordem!
--       join_collapse_limit

show join_collapse_limit;

explain
select *
from tmdb.movie m 
-- genre
inner join tmdb.movie_genre mg on mg.movie_id = m.id 
inner join tmdb.genre g on g.id = mg.genre_id
-- production company
inner join tmdb.production_company pc on pc.movie_id = m.id 
inner join tmdb.company c on c.id = pc.company_id
-- production country
inner join tmdb.production_country pco on pco.movie_id = m.id 
inner join tmdb.country co on co.id = pco.country_id;

explain
select *
from tmdb.movie m  
-- production country
inner join tmdb.production_country pco on pco.movie_id = m.id 
inner join tmdb.country co on co.id = pco.country_id
-- genre
inner join tmdb.movie_genre mg on mg.movie_id = m.id
inner join tmdb.genre g on g.id = mg.genre_id
-- production company
inner join tmdb.production_company pc on pc.movie_id = m.id 
inner join tmdb.company c on c.id = pc.company_id;

-- testando sem reescrita de join
--    ver os custos
--    com reescrita -> ~ 3k
--    sem reescrita -> ~4~6k
set join_collapse_limit to 1;
set join_collapse_limit to default;




-- on/using
--    utilizados para informar como o match deverá ser realizado

-- on 
--    necessário especificar quais as chaves nos dois lados
--    mantém as colunas utilizadas
--    ex: join nas colunas iguais, mantém dos dois lados
with valores as (select * from generate_series(1, 10) as a, generate_series(1, 10) as b)
select *
from valores as t(i, j)
inner join valores as b(i, j) on (t.i = b.i and b.j = t.j);

-- using 
--    necessário especificar o nome de colunas a serem utilizadas -> devem pertencer a ambas as tabelas
--    mantém, no resultado, apenas uma coluna de cada especificada
with valores as (select * from generate_series(1, 10) as a, generate_series(1, 10) as b)
select *
from valores as t(i, j)
inner join valores as b(i, j) using (i, j);



-- outer join
-- 
-- left join > mantenho a esquerda, mesmo sem match na direita
--           > removo a direita sem match na esquerda
select i, m.title
--    gera valores entre 6950 e 7000
--    match com valores em movie.id > retorna nome NULL em caso de não match 
from generate_series(6950, 7000) as t(i)
--    ver diferença para inner
left join tmdb.movie m on m.id = t.i;



-- cuidado
--    há diferenças entre colocar uma condição no filtro de um outer join e colocá-la no where
--    isso só se aplica com outer join -> inner join é irrelevante onde a condição fica

-- nesse exemplo, é feito left join com os números e o conjunto de registros em tmdb.movie com title = 'Outbreak'
--    o left join é feito e, para os números sem match, é retornado NULL para m.title
select i, m.title
from generate_series(6950, 7000) as t(i)
left join tmdb.movie m on m.id = t.i and m.title = 'Outbreak';

-- já nesse caso, o left join é feito e só então o resultado é filtrado
--    ficando apenas as rows cujo m.title = 'Outbreak'
select i, m.title
from generate_series(6950, 7000) as t(i)
left join tmdb.movie m on m.id = t.i 
where m.title = 'Outbreak';


-- quebrando na definição talvez fique mais claro
-- primeira consulta
--    executar as partes individualmente e depois o resultado
select i, m.title
from generate_series(6950, 7000) as t(i)
inner join tmdb.movie m on m.id = t.i and m.title = 'Outbreak'

union 
-- quem não fez match
select i, null
from generate_series(6950, 7000) as t(i)
full outer join tmdb.movie m on m.id = t.i and m.title = 'Outbreak'
where m.id is null;


-- segunda consulta
--    executar as partes individualmente e depois o resultado
select i, m.title
from generate_series(6950, 7000) as t(i)
inner join tmdb.movie m on m.id = t.i 
where m.title = 'Outbreak'

union 

select i, null
from generate_series(6950, 7000) as t(i)
full outer join tmdb.movie m on m.id = t.i
where m.title = 'Outbreak' and m.id is null;



-- e a ordem importa!

-- t1 é mantida, match com t2, 0 matches com t3
select t1.x as t1, t2.x as t2, t3.x as t3
-- 1, 2
from (values (1), (2)) as t1(x)
-- 2, 3
left join (values (2), (3)) as t2(x) on t1.x = t2.x
-- 3, 4
left join (values (3), (4)) as t3(x) on t2.x = t3.x;


-- t1 é mantida, 0 matches com t3, 0 matches com t2
select t1.x as t1, t2.x as t2, t3.x as t3
-- 1, 2
from (values (1), (2)) as t1(x)
-- 3, 4
left join (values (3), (4)) as t3(x) on t1.x = t3.x
-- 2, 3
left join (values (2), (3)) as t2(x) on t3.x = t2.x;

-- para ver melhor, basta executar em partes
--    o primeiro join mantém valor para o próximo
select t1.x as t1, t2.x as t2
-- 1, 2
from (values (1), (2)) as t1(x)
-- 2, 3
left join (values (2), (3)) as t2(x) on t1.x = t2.x;

-- e
--    o primeiro join já retorna tudo null para o próximo join
select t1.x as t1, t3.x as t3
-- 1, 2
from (values (1), (2)) as t1(x)
-- 3, 4
left join (values (3), (4)) as t3(x) on t1.x = t3.x;



-- natural join
--    match realizado utilizando todas as colunas com mesmo nome
--    utilizado quando a modelagem usa mesmos nomes de colunas em relacionamentos
--    sem colunas em comum = produto cartesiano


--Exercício
-- 1. Explicar porque o primeiro sql não retorna o mesmo resultado do segundo

-- renomeio as colunas de ID para movie_id e genre_id, de forma a permitir usar o natural join
select *
from (select id as movie_id, * from tmdb.movie) m 
natural join tmdb.movie_genre as mg
natural join (select id as genre_id, * from tmdb.genre) as g;

select *
from tmdb.movie m 
inner join tmdb.movie_genre mg on mg.movie_id = m.id 
inner join tmdb.genre g on g.id = mg.genre_id;



-- as colunas no natural join devem ter mesmos tipos compatíveis
--    text x numeric > incompatível
select *
from (values (1), (2)) as t(i)
natural join (values ('1', '3')) as k(i);

-- numeric x numeric > ok
select *
from (values (1), (2)) as t(i)
natural join (values (1.0000000000001), (2.)) as k(i);



-- cartesian product ou cross join 
--    retorna todas as combinações

select *
from 
(values (1), (2)) a(x), -- separado por vírgula 
(values (3), (4)) b(y);

select *
from 
(values (1), (2)) a(x)
cross join (values (3), (4)) b(y);


-- syntax antiga para inner join
--    cross join + join no where
--explain
select a.*, b.*
from (values (1, 'a'), (2, 'b')) a(x, y), (values (1, 'c'), (4, 'd')) b(x, y)
where a.x = b.x;

-- igual a
--explain
select a.*, b.*
from (values (1, 'a'), (2, 'b')) a(x, y)
inner join (values (1, 'c'), (4, 'd')) b(x, y) on (a.x = b.x);

-- subquery
--    tudo em SQL são expressões, retornam um valor -> se retorna um set, pode ir no from -> subqueries
select *
from (select * from tmdb.movie where id = 209112) as t;


-- faz diferença?
--    não para a execução
--    sim pro parser e rewriter
--       essa versão não mostra o tempo de planning, com o explain analyze :\
explain analyze
select *
from (
    select *
    from (
        select *
        from (
            select * from tmdb.movie where id = 209112) as t) as t) as t; 

        
            
        
-- generate_series

-- (start, stop)
select *
from generate_series(1, 10);

-- (start, stop, step)
select *
from generate_series(1, 4, 1);

select *
from generate_series(10, 1, -1);

select generate_series(1, 10) + 1;
-- estranho...
select generate_series(1, 4), generate_series(1, 4);
select generate_series(1, 4), generate_series(1, 5);
-- prefiro no from, fica mais claro o resultado


-- timestamp
select generate_series('2018-01-01'::timestamp, '2018-01-03 04:00:00'::timestamp, '1 hour 10 minutes 23 seconds'::interval);



-- EXERCÍCIO

-- 2. Desenvolva sql que faça tenha o mesmo resultado de um left join entre A e B, mas sem utilizar left join
--       A: (values (1), (2), (3)) as A(i)
--       B: (values (2, 'a'), (3, 'b'), (4, 'c')) as B(i, j)


-- 3. Desenvolva sql que retorne a sequência de números de 0.0 a 100.0 com saltos de tamanho 2.5
--       valores iniciais: 0.0, 2.5, 5.0, 7.5, ...