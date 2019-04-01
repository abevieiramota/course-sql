-- notação -> adicionar [] a um tipo base
--    int[] -> 1 dimensão
--    int[][] -> 2 dimensões

-- o PostgreSQL não checa a quantidade de dimensões!
-- ex:

begin;
	-- declarado com 1 dimensão
	create temporary table a (valores int[]);
	-- inseridos valores com 2 dimensões
	--    {
	--       {1, 2},
	--       {3, 4}
	--    }
	insert into a values ('{{1, 2}, {3, 4}}');
	
	select
	-- valores[índice para dimensão 1][índice para dimensão 2]
	valores[1][2], 
	* 
	from a;
rollback;


-- possível especificar tamanhos, mas o PostgreSQL também não valida
--    mais para documentação
-- ex: int[3]


-- literal
--    dimensões entre {}
--    {x, y} -> v[1] = x, v[2] = y
--    {{x, y}, {z, l}} -> v[1][1] = x, v[1][2] = y, v[2][1] = z
select '{1, 2}'::int[];


-- a quantidade de elementos por dimensão devem ser iguais!
select '{{x, y}, {z}}'::text[];


-- null values
select '{1, NULL}'::int[];


-- possível especificar os índices
--    [índices]={valores}
--       índices de 123 a 124
--       acessando o índice = 1 -> NULL
select ('[123:124]={2, 3}'::int[])[1];



-- Exercício
-- 1. Verifique como criar um array do tipo text
--       com os valores 'oi' e 'NULL' (a string, não o valor vazio)
-- https://www.postgresql.org/docs/9.2/static/arrays.html#ARRAYS-INPUT



-- outra notação
select array[1, 2];
select array[[1, 2], [3, 4]];
select array[array[1, 2], array[3, 4]];
select array['OI', 'Hehe'];

-- exemplo
select array[x, y]
from generate_series(1, 3) as t(x), generate_series(1, 3) as m(y);



-- acessando
--    1-based indexing por default -> começa em 1
begin;

	create temporary table a (id int, valores int[]);

	-- arrays com todas as combinações entre [1, 3] e [1, 3]
	insert into a 
	select x, array[x, y]
	from generate_series(1, 3) as t(x), generate_series(1, 3) as m(y);
	
	select * from a;

	select *
	from a 
	-- onde o valor da primeira posição é igual ao valor da segunda posição
	where valores[1] = valores[2];

rollback;



-- slicing
with matrix(M) as 
(values (
	array[
		[1, 2, 3], 
		[4, 5, 6], 
		[7, 8, 9]]
		)
)
select
-- linhas 2 a 3
-- colunas 2 a 3
M[2:3][2:3],
-- linhas 2 a 3
-- de 1 a 2 -> quando há um slice, todas dimensões são slices
--    sem slice -> de 1 ao valor especificado
M[2:3][2],
-- dimensão não restringida retorna tudo
M[2:3]
from matrix;


-- acesso a posição sem dados retorna null, e não erro!
select (array[1, 2])[3];
-- alias, não consigo
--    coloque parênteses entre a expressão que retorna array
select array[1, 2][3];



-- e se o array for null?
--    retorna NULL também! cuidado!
select (null::int[])[3];

-- testando se está vazio
select array_length(array[[[]]]::int[], 1) is null;


-- e slice?
--    retorna a parte que há
--    no exemplo, há a coluna 2, do slice 2:4 -> retornada
select ('{1, 2}'::int[])[2:4];
-- e se não houver interseção
--    retorna array vazio, no lugar de null! cuidado!
--    documentação fala que comportamento tem a ver com retrocompatibilidade
select ('{1, 2}'::int[])[5:7];



-- dimensões de um array
--    array_dims -> retorno TEXTUAL
select array_dims('{{1, 2}, {3, 4}}'::int[]);
select array_dims('[20:21]={5, 6}'::int[]);



-- Exercício
-- 2. Desenvolva um sql que retorne o texto
--       "O array tem índices que vão de X até Y"
--       onde X e Y são o menor índice e o maior índice, respectivamente, do array de 1 dimensão
--       Dica: array_dims + regexp_replace
select '[234:236]={2, 3, 4}'::int[];



--    array_lower
--       menor posição de uma dimensão
--    array_upper
--       maior posição de uma dimensão
select array_lower('[3:4][5:6]={{1, 2}, {3, 4}}'::int[], 1);
select array_upper('{{1, 2}, {3, 4}}'::int[], 1);


--    array_length
--       tamanho de uma dimensão
select array_length('{{1, 2}, {3, 4}}'::int[], 1);



-- modificando

begin;
	create temporary table a (id int, valores int[]);
	insert into a values (1, '{1, 2, 3}');

	select * from a;

	-- modificando totalmente
	update a set valores = '{1, 4}' where id = 1 returning *;
	-- modificando apenas um elemento
	update a set valores[1] = 100 where id = 1 returning *;
	-- adicionando elementos!
	update a set valores[3] = 123 where id = 1 returning *;
	-- alterando slices
	update a set valores[1:2] = '{444, 555}' where id = 1 returning *;
	-- adicionando elementos em posições maiores do que a próxima
	--    nulls adicionados no espaço
	--    permitido apenas para arrays de 1 dimensão!
	update a set valores[10] = 9 where id = 1 returning *;

rollback;


-- concatenação
--    mesmas dimensões -> resultado com mesma quantidade de dimensões
select array[1, 2] || array[3, 4];

--    dimensão N + dimensão N - 1
--    resultado com N dimensões
select array[1, 2] || array[[3, 4], [5, 6]];
select array[[3, 4], [5, 6]] || array[1, 2];


select 1 || array[1, 2];




-- operações com arrays 

begin;

	create temporary table a (id int, locais text[]);
	insert into a values (1, '{casa, trabalho, praça}'),
						 (2, '{casa, shopping}'),
						 (3, '{praça}');

	select * from a;
					
	-- com any/some/all
	--    verificação de se um ELEMENTO pertence a um ARRAY
	select *
	from a 
	where 'shopping' = any(locais);
	
	select *
	from a 
	where 'praça' = all(locais);
	
rollback;



-- 3. Desenvolva sql que retorne todos as produtoras(tmdb.company) que
--       possuem pelo menos um filme de cada um dos seguintes gêneros(tmdb.genre)
--       Action, Horror, Animation, War, Music
--       Não utilizar arrays!



-- operadores

-- igualdade
select array[1, 2] = array[1, 2];
--    devem ser do mesmo tipo
select array[1, 2] = array[1.0, 2.0];
select array[1, 2] = array[1.0, 2.0]::int[];
--    checado o index
select '{1, 2}'::int[] = '[3:4]={1, 2}'::int[];
--    e se possuem tamanhos diferentes mas mesmos elementos?
--    verificado também a dimensão
select array[1, 2] = array[1, 1, 1, 1, 1, 1, 2];

-- <> para diferente
-- <, <=, >, >=
--    testa, na ordem do index, o operador
--       não muito útil com dimensões/tamanhos diferentes
select array[1, 2] < array[2, 3];
--    a comparação é feita como se o array fosse uma string!
--        retorna true, apesar de 1 < 1 = FALSE
select array[1, 2] < array[1, 3];



-- contém
--    @> verifica se o array à esquerda
--       contém todos os ELEMENTOS do array à direita, quantidade não importa -> operação de conjunto
select array[1, 2] @> array[1];
select array[1, 2, 3] @> array[1, 3];

--    observar o exemplo > o teste é sobre os ELEMENTOS
select array[[1, 2], [3, 4]] @> array[[1, 4], [2, 3]];
select array[[1, 2], [3, 4]] @> array[1, 4, 2, 3];


--    opera como set > não verifica as quantidades
--       apesar de ser array[1, 1], verifica apenas se há 1 em array[1, 2, 3]
select array[1, 2, 3] @> array[1, 1];

--     <@ -> está contido em -> mesma operação, muda a posição dos operandos
select array[1, 4, 3] <@ array[[1, 2], [3, 4]];


-- overlap
--    verifica se há ELEMENTOS em comum
--    trata o array como um set, ignorando dimensões
--    &&
select array[1, 2, 3] && array[[1, 8], [2, 11], [66, 3]];



-- array_fill(N, array com dimensões)
--    array 3x3 preenchido com 10
select array_fill(10, array[3, 3]);
select array_fill(null::int, array[3, 3, 3]);


-- array_to_string
--    (array, separador, null-string)
select array_to_string(array[1, 2, null, 3], '-', 'Nulo');


-- string_to_array
--    (string, separador, null-string)
select string_to_array('1-2-3-#-4', '-', '#');


-- unnest 
--    transforma elementos em rows
select unnest(array[1, 2, 3]);


-- ravel -> N-dim -> 1-dim
select array_agg(v)
from (select unnest(array[[3, 4], [23, 22]])) as t(v);



-- Exercício
-- 4. Desenvolva sql que retorne todos as produtoras(tmdb.company) que
--       possuem pelo menos um filme de cada um dos seguintes gêneros(tmdb.genre)
--       Action, Horror, Animation, War, Music
--       Usar array -> array_agg + @>