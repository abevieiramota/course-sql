-- https://www.postgresql.org/docs/9.4/static/functions-aggregate.html


-- group by > calcular quantitativos por keyword, genre, company etc
--   em exercício de group by, colocar um caso de agrupamento usando case when

-- max, min, avg, sum

--    sem group by as funções de agregação são aplicadas a todo o resultado
--    o que ocorre com o group by é que elas são aplicadas a cada subset

select 
max(revenue), 
min(revenue),
avg(revenue),
sum(revenue),
count(*)
from tmdb.movie;


-- com group by 
--    agrupando por original_language
select original_language,
max(revenue), 
min(revenue),
avg(revenue),
sum(revenue),
count(*)
from tmdb.movie
group by original_language
order by original_language;



-- posso aplicar funções de agregação a colunas não agrupadas
-- posso aplicar funções escalares a colunas agrupadas

select original_language, format('O filme foi gravado em %s', original_language),
max(revenue)
from tmdb.movie
group by original_language
order by original_language; 



-- nulls ignorados
select sum(x)
from (values (1), (null)) as t(x);



-- distinct
--    é possível informar às funções de agregação para considerarem apenas valores distintos
select sum(x) as "sum(x)", sum(distinct x) as "sum(distinct x)"
from (values (1), (1), (2)) as t(x);



-- count

-- count(*) 
--    informa o número de rows do resultado
-- count(x) 
--    informa o número de rows com x não null
select 
count(*) as "count(*)", 
count(x) as "count(x)",
count(distinct x) as "count(distinct x)"
from (values (1), (2), (null), (1)) as t(x);



-- having
--    define condições sobre os subsets que devem ser satisfeitas para que eles sejam retornados
select original_language,
max(revenue), 
min(revenue),
avg(revenue),
sum(revenue),
count(*), count(tagline)
from tmdb.movie
group by original_language
-- quantidade de taglines não nulas > lembrar que nulls são ignorados
having count(tagline) > 10
order by original_language;


-- order by
--    possível especificar ordem dos valores a serem utilizados

select string_agg(x::text, ' | ' order by x asc)
from (values (1), (100), (23), (-123)) as t(x);


-- filter :( em versões mais recentes, 9.4+, é possível filtrar valores do grupo :(
--    aggregate_name ( * ) [ FILTER ( WHERE filter_clause ) ]



-- array_agg
--    transforma uma coluna de um subset em um array

--    para usar distinct + order by a a coluna utilizada no order by deve aparecer também no distinct
-- linguagens e array dos anos com filmes, em ordem
select original_language, array_agg(distinct extract(year from release_date) order by extract(year from release_date) asc)
from tmdb.movie
group by original_language
order by original_language;


-- unnest
--    faz o contrário de array_agg, transformando em rows um array
select unnest(array[1, 2]);

select array_agg(x) from (values (1), (2)) as t(x);



-- outro exemplo > tentem entender
--    valores
values (1, 2), (1, 0), (1, 2), (2, 3), (2, 5);

-- group by x
select x,
-- maior valor de y
max(y) as max_y, 
-- valores de y
array_agg(y) as array_agg_y, 
array_agg(distinct y) as array_agg_distinct_y
-- testar sem o unnest, para mostrar o comportamento
,unnest(array_agg(distinct y)) as unnest_array_agg_distinct_y
from (values (1, 2), (1, 0), (1, 2), (2, 3), (2, 5)) as t(x, y)
group by x;



-- string_agg
--    string_agg(coluna donde vêm as strings, string separadora)

--    valores devem ser text
--    ex: lista de datas, separadas por ,
select string_agg(to_char(i, 'dd/MM/yy'), ' , ')
from generate_series('2018-01-01'::date, '2018-01-08', '1 day') t(i);



-- bool_and
--    verifica se todos os booleanos são TRUE

-- filmes produzidos no Brazil e apenas no Brazil
explain 
select m.title
from tmdb.movie m 
inner join tmdb.production_country pc on pc.movie_id = m.id 
inner join tmdb.country c on c.id = pc.country_id
group by m.title 
having bool_and(c.country = 'Brazil')
--having count(*) = count(case when c.country = 'Brazil' then 1 end)
order by 1 asc;


--    outra solução
explain 
select m.title
from tmdb.movie m 
inner join tmdb.production_country pc on pc.movie_id = m.id 
inner join tmdb.country c on c.id = pc.country_id
group by m.title 
having not bool_or(c.country <> 'Brazil')
--having count(*) = count(case when c.country = 'Brazil' then 1 end)
order by 1 asc;


--    outra solução
explain
select m.title
from tmdb.movie m

except

select distinct m.title
from tmdb.movie m 
left join tmdb.production_country pc on pc.movie_id = m.id 
left join tmdb.country c on c.id = pc.country_id
where c.id is null or c.country <> 'Brazil'

order by 1 asc;




-- bool_or
--    verifica se pelo menos um booleano é TRUE

-- filmes que tiveram parte ou toda a produção no Brazil
explain 
select m.title
from tmdb.movie m 
inner join tmdb.production_country pc on pc.movie_id = m.id 
inner join tmdb.country c on c.id = pc.country_id
group by m.title 
having bool_or(c.country = 'Brazil')
order by 1 asc;


--    outra solução
explain
select distinct m.title
from tmdb.movie m 
inner join tmdb.production_country pc on pc.movie_id = m.id 
inner join tmdb.country c on c.id = pc.country_id
where c.country = 'Brazil'
order by 1 asc;




-- e se eu quiser verificar se uma quantidade delimitada de booleanos são TRUE?
--    sum(case when true then 1 end)
--    count(case when true then 1 end)
-- companhias com 5 filmes de ação
--explain analyze
select c.company, array_agg(distinct case when g.genre = 'Action' then m.title end)
from tmdb.company c 
inner join tmdb.production_company pc on pc.company_id = c.id 
inner join tmdb.movie_genre mg on mg.movie_id = pc.movie_id
inner join tmdb.movie m on mg.movie_id = m.id
inner join tmdb.genre g on g.id = mg.genre_id
group by c.company
--having sum(case when g.genre = 'Action' then 1 end) = 5;
having count(case when g.genre = 'Action' then 1 end) = 5;



-- EXERCÍCIO

-- 1. Desenvolva sql para retornar os nomes de colunas que aparecem em mais de uma tabela
--       retornar o nome da coluna e o nome das tabelas onde ela aparece, em um array
--       devem ser ignoradas colunas dos esquemas information_schema e pg_catalog
--       informações de colunas podem ser encontradas em information_schema.columns