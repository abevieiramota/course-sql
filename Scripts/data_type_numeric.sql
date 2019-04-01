-- syntax

-- integer
-- formato: \d+
-- 000123 = 123
select 1, 00123, 123;

-- arbitrary precision
-- formato: \d+.\d*, \d*.\d+
select 1., .123, 1.3;

-- numeric = decimal
-- precision -> quantos dígitos são armazenados
-- scale -> quantos dígitos decimais são armazenados
-- numeric(3, 2) -> 1.00, 1.10, 1.12
select 1::numeric(3, 2), 1.1::numeric(3, 2), 1.12::numeric(3, 2);
-- numeric(x) = numeric(x, 0) -> 0 decimais
-- arredondamento para o inteiro mais próximo -> .5 > 1, -.5 > -1
select 123.123::numeric(3), 123.567::numeric(3), 123.456::numeric(5, 2);
-- exemplos
select (2./3)::numeric(10, 2), (2./3)::numeric(10, 10), (2./3)::numeric(10), 0.5::numeric(1);
-- se a precisão do número for maior que a do container, overflow
-- exemplo:
begin;
    create table curso_sql (a numeric(2, 1));
    insert into curso_sql values (10.2);
rollback;

-- float -> inexact -> valores podem ser alterados durante a escrita p/ acomodar ao formato
-- operações mais eficientes que numeric
-- não usar para currency
begin;
    create table curso_sql (a real, b numeric(100, 30));
    insert into curso_sql select 1.22222222222222222222222222222, 1.22222222222222222222222222222 from generate_series(1, 2, 1);
    select * from curso_sql;
    select sum(a), sum(b) from curso_sql;
rollback;

-- rounding
select 1/3.::numeric(100, 40), (1/3.)::numeric(100, 40);


-- operações

-- https://www.postgresql.org/docs/9.3/static/functions-math.html

select
-- colunas
a, b, 
-- soma
a + b as soma,
-- subtração
a - b as subtracao,
-- multiplicação
a * b as multiplicacao,
-- divisão inteira
-- a e b são integers 
-- para que a divisão seja numérica, é necessário que um dos operandos seja numérico -> cast
a / b as int_div, a::numeric / b as div,
-- módulo da divisão
a % b as modulo,
-- potenciação
a ^ b as potencia,
-- raiz quadrada
|/ a as raiz_2,
-- raiz cúbica
||/ a as raiz_3,
-- fatorial
a! as fatorial,
-- valor absoluto
@ a as absoluto,
-- comparação
a > b as gt, a <= b as lte, 
-- igualdade
a <> b as dif1, a != b as dif2
from 
-- funções de geração de valores
-- gera de 1 a 3 com passo 1
generate_series(1, 3, 1) as t1(a),
-- gera de -3 a -1 com passo 1
generate_series(-3, -1, 1) as t2(b);


-- https://www.postgresql.org/docs/9.3/static/functions-comparison.html

-- between INCLUSIVE
-- x >= 5 and x <= 6
select 5 between 5 and 6;
select 5 between 4 and 5;
select 10 between 4 and 5;

-- not between EXCLUSIVE endpoints
-- x < 5 or x > 6
select 5 not between 5 and 6;
select 5 not between 4 and 5;
select 3 not between 4 and 5;

-- between symmetric
-- lida com o caso de o limite inferior ser maior que o superior, invertendo eles
-- equivalente a between 5 and 10
select 5 between symmetric 10 and 5;


-- diferença de <> para IS DISTINCT FROM
 
-- is distinct from
-- 5 <> null? não sei!
select 5 <> null;
-- 5 é distinto de null? sim
select 5 is distinct from null;
-- null <> null? não sei!
select null <> null;
-- null is distinct from null? não!
select null is distinct from null;

-- tabela verdade para <> e IS DISTINCT FROM
-- operador <> retorna NULL quando um dos operandos é NULL
-- operador IS DISTINCT FROM trata NULL como um valor
select a.i as a, b.i as b, 
a.i <> b.i as "a <> b", 
a.i is distinct from b.i as "a is distinct from b"
from (values (1), (null)) a(i), (values (2), (null)) b(i);


-- is null 
-- o operador = retorna NULL se um dos operandos forem NULL
-- observar que x = NULL sempre retorna NULL!
select a, a is null as "IS NULL", a is not null as "IS NOT NULL", a = null as "a = NULL" 
from (values (10), (null)) as t(a);

-- is unknown
-- apenas para booleanos, mesma semântica de IS NULL
select a, a is null as "a IS NULL", a is unknown as "a IS UNKNOWN"
from (values (true), (null)) as t(a);



-- Funções matemáticas
-- https://www.postgresql.org/docs/9.3/static/functions-math.html

select 
-- valores
x, y,
-- valor absoluto -> mesmo que o operador @
abs(x),
-- teto -> arredonda para o menor inteiro maior ou igual ao número
ceil(x), -- same as ceiling
-- piso -> arredonda para o maior interior menor ou igual ao número
floor(x),
-- conversão de radianos para graus
degrees(x), -- radians to degrees
-- parte inteira da divisão
div(x, y), -- integer part
-- e^x
exp(x) -- exponential
from (values (2, 3), (-3.81234, 2)) as t(x, y);


select
-- valores
x, y,
-- log(x, e)
ln(x), -- natural log
-- log(x, 10)
log(x) as log10, -- base 10 log
-- log(x, y)
log(x, y) as logy, -- base y log
-- resto da divisão inteira -- mesmo que x % y
mod(x, y),
-- raiz quadrada -> mesmo que operador |/
sqrt(x), -- square root
-- PI
pi(),
-- potenciação
power(x, y), -- x ^ y
-- graus para radianos
radians(x) -- degress to radians
from (values (2, 3), (1.81234, 4)) as t(x, y);

select
-- valores
x, y,
-- arrendondamento para o inteiro mais próximo -> .5 > 1, -.5 > -1
round(x), -- round to the nearest integer
-- arredondamento para y casas decimais
round(x, y), -- round to y decimal places
-- sinal
sign(x), -- sign of x
-- arrendonda em direção a zero
trunc(x) as "trunc(x)", -- truncate toward zero
-- arredonda em direção a zero com y casas decimais
trunc(x, y) as "trunc(x, y)" -- truncate toward zero to y decimal places
from (values (2, 3), (-1.81234, 4)) as t(x, y);

select '2018-09-01'::date + '1 month'::interval;

-- random
--    
-- random() retorna número de [0.0, 1.0) uniformemente
select 
-- se eu quiser um random em [1.0, 10.0) 
--    random() * 9 gera valor em [0.0, 9.0)
--    basta incrementar 1: random() * 9 + 1 gera valor em [1.0, 10.0)
random() * 9 + 1 as _1_10_numeric, 
-- random inteiro em [1, 10] ->
--    random em [1.0, 11.0) -> arredonda para baixo -> round
--       1.3 vira 1
--       10.5 vira 10
floor(random() * 10 + 1) as _1_10_integer 
from generate_series(0, 1000, 1);

-- amostra de x números no intervalo de 1 a 10
--    gero os números com generate_series
--    ordeno aleatoriamente
--    uso limit para selecionar os X top/bottom
select i 
from generate_series(1, 10) as t(i)
order by random()
limit 5;

-- outra solução para gerar N valores dentro de um conjunto de inteiros
--    (1 + x - x) serve apenas para transformar a consulta em correlacionada
--    a ser calculada para cada registro do from
--    sem isso, ela é executada apenas uma vez, apenas um valor random é calculado
select (select i * (1 + x - x) from generate_series(1, 10) as t(i) order by random() limit 1)
from generate_series(1, 10) as t(x);


-- to_char
-- função utilizada na formatação de números
select
-- 9
--    indica o número
--    imprime a quantidade de 9s, colocando espaços à esquerda qnd não houver
-- SG
--    sign -> sinal do número
--    translate para trocar espaços por #, para mostrar os espaços inseridos
-- .
--    separador de decimais
translate(to_char(x, 'SG9999.999'), ' ', '#')
from (values (123), (-1212.123), (1)) as t(x);

select
-- 0
--    adiciona 0's à esquerda para complementar
to_char(1369216394, '00000000000');
-- formatando
--    formato com ':' no lugar de '.', pois '.' é caractere reservado = separador de decimais
select replace(to_char(1369216394, '000:000:000-00'), ':', '.');

select
-- G
--    separador de grupo(milhares, por exemplo)
--    mesmo que ',', mas usa locale
to_char(123123, '000,000');

select
-- D
--    separador de decimal
--    mesmo que '.', mas usa locale
--    especificado 4 dígitos inteiros e 2 casas decimais
to_char(123.234, '0000D00');

select
-- PR
--    se o valor for negativo, coloca ele entre angle brackets
to_char(x, '000.000PR')
from (values (123), (-123.123)) as t(x);



-- SQLS

-- Analisar estrutura/dados nas tabelas candidatos_2018.{candidatos, bens}

-- 1. Desenvolver SQL para retornar os dados em candidatos_2018.bens
--       com uma coluna adicional vr_bem_candidato_real contendo apenas a parte inteira de vr_bem_candidato
--    ex: 123.23 deve ser retornado como 123
--        123.00 deve ser retornado como 123


-- 2. Desenvolver sql para calcular, para cada registro da tabela candidatos_2018.bens 
--       uma coluna imposto calculada usando a regra
--       imposto = 10 porcento de vr_bem_candidato, arredondado para baixo(o resultado de 10% * vr_bem_candidato que deve ser arredondado para baixo)
--       ex: 59418.12 tem de imposto 5941
--           123.345 tem de imposto 12
--       EXTRA: o valor mínimo do imposto é 1234
--       ex: 123.345 tem de imposto 1234


-- 3. Desenvolver sql para calcular os registros em candidatos_2018.bens
--       com vr_bem_candidato não múltiplo de 10
--       ex: bem com vr_bem_candidato = 123.00 deve ser retornado
--           bem com vr_bem_candidato = 7.00 não deve ser retornado


-- 4. Desenvolver SQL para calcular os registros em candidatos_2018.bens
--       com vr_bem_candidato com centavos diferente de 0
--       ex: bem com vr_bem_candidato = 123.20 deve ser retornado
--           bem com vr_bem_candidato = 123.00 não deve ser retornado


-- 5. Desenvolver sql que atribua a cada registro em candidatos_2018.candidato
--       com ds_cargo = GOVERNADOR
--       um número aleatório e selecione o registro com maior valor
--       quem ganhou?
--       EXTRA: desenvolva um sql que retorne um ganhador para os cargos 'GOVERNADOR', 'DEPUTADO ESTADUAL', 'DEPUTADO FEDERAL', 'SENADOR'