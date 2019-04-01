-- window function
-- https://www.postgresql.org/docs/9.2/static/functions-window.html#FUNCTIONS-WINDOW-TABLE
--    cálculo sobre rows relacionadas a row corrente
--    o que pode incluir todas as linhas
--    a anterior, posterior
--    dentro de um determinado grupo/partição

--    noção de ordem

-- Postgres Window Magic https://www.youtube.com/watch?v=D8Q4n6YXdpk
-- https://www.periscopedata.com/blog/window-functions-by-example



-- exemplos

-- 1.
--    lag
SELECT *,
--    para a row anterior, em ordem crescente, o valor de i
lag(i) over(order by i asc) as pos,
format('Meu valor = [%s], o valor do anterior = [%s]', i, lag(i::text, 1, 'vazio') over(order by i asc)) as str
FROM generate_series(1, 5) as t(i)
order by i;


-- 2.

SELECT *,
--    para a row 2-anterior, em ordem crescente, o valor de i
lag(i, 2) over(order by i asc) as pos
FROM generate_series(1, 5) as t(i)
order by i;


-- 3.

SELECT *,
--    para a row anterior, em ordem DECRESCENTE, o valor de i
lag(i) over(order by i desc) as pos
FROM generate_series(1, 5) as t(i)
order by i;
--    ver com order by i desc -> mesma ordenação da window function
--    ver que a ordem sobre a qual é aplicada a função não é necessariamente a mesma ordem do result set
order by i desc;


-- 4.

--    soma cumulativa
SELECT *,
sum(i) over(order by i asc rows between unbounded preceding and current row) as pos
FROM generate_series(1, 5) as t(i);



-- explicando
-- SUM(i) -> some os valores de i
--    OVER( -> sobre a lista de valores definidas por
--       ORDER BY i ASC -> ordenado por i asc
--       ROWS -> modo de definição da window 
--          BETWEEN -> a lista é delimitada por
--             UNBOUNDED PRECEDING -> todas as rows anteriores
--             AND
--             CURRENT ROW -> até a row atual
--         )


-- 5.

--    ordem dentro de grupos
--       valores agrupados pelo resto da divisão por três e ordenados
select i, i % 3 as rest_div_3, 
row_number() over(partition by i % 3 order by i asc) as pos 
from generate_series(1, 5) as t(i)
order by 2;

-- explicando
-- ROW_NUMBER() -> retorne a posição da row dentro do grupo
--    OVER( -> sobre a lista de valores definida por
--       PARTITION BY i % 3 -> particione os valores por i % 3 e coloque esta row no seu grupo
--       ORDER BY i ASC -> ordene as rows do grupo por i asc
--        )
--    a posição da row dentro do seu grupo, i % 3, em ordem crescente



-- sintaxe
--    FUNCTION OVER ([PARTITION BY X] [ORDER BY U] [RANGE/ROWS BETWEEN START AND END])



-- 6.

-- permite trabalhar com funções de agregação
--    e retornar valores juntamente com as próprias rows
select i, i % 2 as "i % 2", 
max(i) over (partition by i % 2)
from generate_series(1, 5) as t(i)
order by 2, 1;



-- movie com revenue e a proporção de revenue / soma de revenue no ano
select extract(year from release_date)::integer as ano, title, revenue, 
-- formatação
to_char(
	-- mantém apenas 2 casas decimais
	trunc(
		-- revenue * 100 / total do grupo
		(revenue * 100) / sum(revenue) 
		-- grupo = partição por ano ao qual o registro pertence
		over (partition by extract(year from release_date)), 
		2),  
	'90.99%') as revenue_prop 
from tmdb.movie
where revenue > 0
order by 1 desc, 3 desc;



-- reuso de window definition

-- movie com revenue e a proporção de revenue / soma de revenue no ano
--                       proporção de quantidade em relação ao total do ano
select extract(year from release_date)::int as ano, title, revenue, 
-- formatação
to_char(
	-- mantém apenas 2 casas decimais
	trunc(
		-- revenue * 100 / total do grupo
		(revenue * 100) / sum(revenue) 
		-- grupo = partição por ano ao qual o registro pertence
		over w, 
		2),  
	'990.99%') as revenue_prop,
-- formatação
to_char(
	-- mantém apenas 2 casas decimais
	trunc(
		-- %
		100.0 / count(*)
		-- window definition
		over w, 
		2), 
	'990.99%') as count_prop
from tmdb.movie
where revenue > 0
window w as (partition by extract(year from release_date))
order by 1 desc, 3 desc;




-- frame
-- sem order by -> toda a partição
--    FUNCTION_NAME over (PARTITION BY X ORDER BY U RANGE/ROWS BETWEEN START AND END)
--    por default -> [unbounded preceding, current_row]
--       deve estar especificada uma ordem! over() -> todas as rows
-- se frame_end não definido > default = current row
-- UNBOUNDED PRECEDING > frame_start = first row
-- UNBOUNDED FOLLOWING > frame_end = last row
-- no modo ROWS pode-se especificar quantas rows antes ou depois, com N PRECEDING/N FOLLOWING
--    order by > sem ele, igual a consulta normal, ordem não definida
-- no modo RANGE não


select *,
-- default
--    range between unbounded preceding and current row
--    observar que range trabalha com valores, e não rows -> 3 ocorre 2 vezes, as duas são consideradas a mesma ocorrência
--        dai o resultado 1 -> 3 -> 9 -> 9
sum(x) over (partition by y order by x asc) as ex_default,
sum(x) over (partition by y order by x asc range between unbounded preceding and current row) as ex_default_explicito,

-- versão com row
sum(x) over (partition by y order by x asc rows between unbounded preceding and current row) as ex_default_row,

-- soma o valor e os que o seguem
--    modo row
sum(x) over (partition by y order by x asc rows between current row and unbounded following) as ex_rows,
--    modo range
sum(x) over (partition by y order by x asc range between current row and unbounded following) as ex_range,

-- soma o valor corrente e o próximo -> não havendo próximo(ou anterior), soma só o atual
--    observar que para x = 4 o valor é 4, por não haver próximo
sum(x) over (partition by y order by x asc rows between current row and 1 following) as ex4,
-- range > frame definido de forma lógica; row > frame definido de forma "física"
--    observa o resultado para x = 3(ocorre duas vezes)
--    comparar ex5 com o correspondente com ROW, ex2
--    soma atual e os próximos
--    para row > próximos = próximas rows; current row = row atual
--    para range > próximos = próximos elementos na ordenação; current row = conjunto de rows com mesmo rank 
sum(x) over (partition by y order by x asc range between current row and unbounded following) as ex5,
-- soma da partição
sum(x) over (partition by y order by x rows between unbounded preceding and unbounded following)
-- mesmo que sum(x) over(partition by y)
from (values (1, 'a'), (2, 'a'), (3, 'a'), (3, 'a'), (4, 'a'), (4, 'a'), (5, 'b'), (6, 'b'), (7, 'b'), (8, 'b')) as t(x, y)
order by x, y;



-- over()
--    inclui todas as rows
--    significado
--    (range between unbounded preceding and current row)
--    como não é especificado partition -> uma partição com todo mundo
--    como não é especificada ordem, todas as rows são consideradas no mesmo range

select x,
x::numeric / sum(x) over() as val1, 
sum(x) over() as val2
from generate_series(1, 5) as t(x);



-- window functions



select *,
-- row_number
--    posição, a partir de 1, na janela
--    exemplos anteriores
row_number() over(order by x asc),
--    dentro da partição
row_number() over(partition by y order by x asc) as row_number_na_particao,
-- RANK
--    mesmo que row_number, mas quando há empate, o grupo empatado recebe o valor do menor
--    !o próximo após o empate recebe o a posição que receberia num row_number
rank() over(order by y asc),
-- DENSE_RANK
--    !o próximo após o empate recebe o a posição que receberia se o grupo do empate fosse considerado apenas uma row
dense_rank() over(order by y asc),
-- PERCENT_RANK
--    (rank - 1) / (nrows - 1)
percent_rank() over(order by y asc),
--    mesmo cálculo
(rank() over(order by y asc) - 1)::numeric / (count(*) over() - 1),
-- CUME_DIST
--    quantidade de rows no mesmo rank ou inferior / total de rows
cume_dist() over(order by y asc),
(rank() over(order by y asc))::numeric / (count(*) over())
from (values (1, 'a'), (2, 'b'), (3, 'b'), (4, 'c')) as t(x, y)
order by x asc;



-- NTILE
--    divide os dados em N buckets de tamanho igual, a partir do 1
--    útil para calcular percentis
select *,
--    10 tiles
ntile(10) over(order by x),
--    25 tiles
ntile(25) over(order by x),
--    10 tiles -> desc
ntile(10) over(order by x desc)
from generate_series(1, 100) as t(x)
order by x asc;



-- 90 percentil
--    coloco os dados em grupos de 10% cada, ordenados
--    seleciono o menor valor do último grupo
--    valor abaixo do qual se concentram 90% dos dados
--    n-percentil usado como métrica de qualidade
--       90% das requisições demoram menos de 2s
with tiles as (
    select *,
    ntile(10) over(order by x) as tile
    from generate_series(1, 5000) as t(x)
)
select min(x)
from tiles
where tile = 10;




-- lag(x, offset, valor_default)
--    retorna o valor de x, na janela, y rows antes da current row, com valor default z, caso não exista
--    offset default = 1
--    valor_default default = NULL
select *,
--    ex: 1234 - 1000
x - lag(x) over(order by y asc),
--    ex: 223 - 1000
x - lag(x, 2) over(order by y asc),
--    faz isso, mas em cada partição
x - lag(x) over(partition by y order by x asc),
--    x - lag(0, caso não exista) -> ex: primeira linha, 1000 - 0
x - lag(x, 1, 0) over(partition by y order by x asc)
from (values (1000, 'a'), (223, 'b'), (300, 'b'), (41, 'c'), (1234, 'a'), (555555, 'c')) as t(x, y);
order by y asc;

-- mesma ideia pro LEAD, só que no lugar de trabalhar com rows anteriores, trabalha com rows posteriores



-- FIRST_VALUE, LAST_VALUE, NTH_VALUE
select *,
-- primeira linha da window -> !importante, é em relação à window, e não à partition!
--    qual a diferença de first_value e min?
--    first_value retorna o valor da coluna na primeira posição, de acordo com a ordem da window
--    min retorna o menor valor da coluna -> independe da ordem dos registros
first_value(x) over(partition by y order by x asc),
min(x) over(partition by y order by x asc),
-- última linha da WINDOW
last_value(x) over(partition by y order by x asc rows between current row and 1 following),
max(x) over(partition by y order by x asc),
-- retorna x apenas na row 2 da window
nth_value(x, 2) over(partition by y order by x asc)
from (values (1000, 'a'), (223, 'b'), (300, 'b'), (41, 'c'), (1234, 'a'), (555555, 'c')) as t(x, y);






-- aggregation functions
-- https://www.postgresql.org/docs/9.2/static/functions-aggregate.html
--    podem ser utilizadas também as funções de agregação
--    como sum, avg etc

select *,
--    0 following = current row
--    0 preceding = current row
array_agg(x) over (partition by y order by x asc rows between unbounded preceding and 0 following),
avg(x) over (partition by y order by x asc)
from (values (1000, 'a'), (223, 'a'), (300, 'a'), (41, 'c'), (1234, 'a'), (555555, 'c')) as t(x, y)
order by y asc, x asc;



-- Exercício

-- 1. https://www.windowfunctions.com/questions/over/0

-- 2. https://www.windowfunctions.com/questions/over/1

-- 3. https://www.windowfunctions.com/questions/ranking/0

-- 4. https://www.windowfunctions.com/questions/grouping/1