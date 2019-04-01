-- representa intervalo de algum tipo
--    tipo deve ter noção de ordem

-- int4range
-- int8range
-- numrange
-- tsrange
-- tstzrange
-- daterange

-- exemplo

BEGIN;
	CREATE TEMPORARY TABLE reserva (sala int, duracao tsrange);

	INSERT INTO reserva VALUES (10, '[2018-10-02 10:00, 2018-10-02 12:00]');

	select * from reserva;

	select duracao, 
	-- verifica se contém momento
	duracao @> '2018-10-02 11:23'::timestamp,
	duracao @> '2018-10-01 10:30'::timestamp
	from reserva;

ROLLBACK;


-- notação
--    necessário especificar se os limites estão ou não incluídos no range
--    [] -> inclusive
--    () -> exclusive
--    lower deve ser <= upper
select '[3, 7)'::int4range @> 7;
select '[3, 7]'::int4range @> 7;

-- extremos iguals e inclusivo -> ponto
--    ponto inteiro representado como intervalo [x, x+1)
select '[3, 3]'::int4range;

-- extremos iguais e exclusivo -> empty
select '[3, 3)'::int4range;
select 'empty'::int4range;


-- lower_inc, upper_inc -> inc ~ included
--    testam se os limites estão incluídos

select lower_inc('[3, 7)'::int4range);
select upper_inc('[3, 7)'::int4range);


-- intervalos com limite infinito
select '[3,)'::int4range @> 100000;

-- inclui tudo
--    não colocar os limites
select '(,)'::int4range @> -100000;


-- lower_inf, upper_inf 
--    testa se o limite é infinito
select lower_inf('(,100]'::int4range);



-- definindo range com função
--    int4range()
--    int8range()
--    numrange()
--    tsrange()
--    tstzrange()
--    daterange()

-- (lower, upper, inclusion)
select int4range(10, 14, '[]');

-- por default, [)
select int4range(10, 14);

-- infinito à esquerda
--    informei lower inclusivo, mas vira exclusivo pois não há limite infinito inclusivo
select numrange(null, 2, '[]');



-- operações
-- https://www.postgresql.org/docs/9.2/static/functions-range.html#RANGE-OPERATORS-TABLE

-- =, <> 
select daterange(current_date, current_date + 1, '[]')
     = '[2018-10-03, 2018-10-04]'::daterange;
-- necessário ser o mesmo range, mesmos limites, mesma inclusividade
select '[1, 2]'::int4range = '[1, 2)'::int4range;


-- <, <=, >, >=
-- comparam os lowers
--    se iguais -> retorna a comparação do upper
--    senão -> retorna a comparação deles
select int4range(1, 10) > int4range(0, 30);
select int4range(1, 10) > int4range(1, 3);
--    mesmo que
select int4range(1, 10)::text > int4range(0, 30)::text;
select int4range(1, 10)::text > int4range(1, 3)::text;


-- @> -> contém
select int4range(1, 10) @> 4;
select int4range(1, 10) @> int4range(3, 4);
select int4range(1, 10) @> int4range(8, 12);


-- && -> overlap
select int4range(1, 10) && int4range(null, 4);


-- << -> totalmente menor
select int4range(1, 2, '[]') << int4range(2, 4, '[]'), 
	   int4range(1, 2, '[]') < int4range(2, 4, '[]');

-- >> -> totalmente maior


-- x &< y
--    x não tem 'pedaço' além do limite superior de y
--    upper(x) < upper(y)
select int4range(1, 10) &< int4range(null, 30);
--    o subrange (9, 10) de x se extende à direita de y
select int4range(1, 10) &< int4range(null, 9);


-- -|- -> é adjacente
--    um dos ranges deve incluir o ponto de adjacência, o outro não
select int4range(1, 10, '[]') -|- int4range(10, 14, '(]');
--    simétrico
select int4range(10, 14) -|- int4range(1, 10);
-- [1, 9] e [11, 14]
select int4range(1, 10, '[)') -|- int4range(10, 14, '()');
-- possuem o mesmo ponto da adjacência -> FALSE
--    [1, 2] e [2, 3]
select int4range(1, 2, '[]') -|- int4range(2, 3, '[]');


-- + -> união
select int4range(1, 3) + int4range(2, 12);
--    necessário ser adjacente ou ter interseção!
--    [1, 3) + [4, 12) = [1, 2] + [4, 12)
select int4range(1, 3) + int4range(4, 12);
select int4range(1, 3, '[]') + int4range(4, 12);


-- * -> interseção
select daterange(current_date, current_date + 10) *
       daterange(current_date + 3, current_date + 30);
--    interseção vazia
select int4range(1, 10) * int4range(100, 200);


-- - -> diferença
select daterange(current_date, current_date + 10) -
       daterange(current_date + 3, current_date + 100);
--    resultado deve ser um range contínuo, sem gaps
--       não posso tirar um pedaço de dentro de um range
select int4range(1, 10, '[]') - int4range(2, 4, '()');
--    remove o upper bound
--       remove o ponto 10
select int4range(1, 10, '[]') - int4range(10, 10, '[]');



-- Exercício
-- 1. Analisar o sql
--       Feriado que estende um fds
--          feriado + fds > 2 dias
--          feriado n pode incluir todo o fds
--             ex: começa na sexta e termina na segunda-feira
--          sem gaps entre o feriado e o fds
--             devem ser adjacentes

with feriado(i, range, nome) as (
	-- feriado que inclui o fds todo -> NÃO
	values (1, daterange('2018-08-09'::date, '2018-08-12'::date, '[]'), 'teste 1'),
	-- perfeito -> OK
		   (2, daterange('2018-09-27'::date, '2018-09-28'::date, '[]'), 'teste 2'),
	-- feriado começa no domingo, mas inclui a segunda -> OK
		   (3, daterange('2018-09-23'::date, '2018-09-24'::date, '[]'), 'teste 3'),
	-- feriado no meio da semana -> NÃO
		   (4, daterange('2018-09-18'::date, '2018-09-19'::date, '[]'), 'teste 4'),
    -- exemplos reais
           (5, daterange('2018-01-01'::date, '2018-01-01'::date, '[]'), 'Confraternização Universal'),
           (6, daterange('2018-02-10'::date, '2018-02-12'::date, '[]'), 'Recesso Escolar e Administrativo - Carnaval'),
           (7, daterange('2018-02-13'::date, '2018-02-13'::date, '[]'), 'Feriado Nacional - Carnaval'),
           (8, daterange('2018-03-30'::date, '2018-03-30'::date, '[]'), 'Feriado Nacional - Paixão de Cristo'),
           (9, daterange('2018-03-31'::date, '2018-03-31'::date, '[]'), 'Recesso Escolar e Administrativo - Semana Santa'),
           (10, daterange('2018-04-21'::date, '2018-04-21'::date, '[]'), 'Feriado Nacional - Tiradentes')
),
-- gera os fins de semana de 2018
fds(range) as (
	select daterange(data::date, data::date + 1, '[]')
	from generate_series('2018-01-01'::timestamp, 
						 '2018-01-01'::timestamp + '1 year'::interval, 
					 	 '1 day'::interval) as t(data)
	where extract(dow from data) = 6 -- sábado
)
select f.i, f.range as feriado, fds.range as fds, f.nome
from feriado f
inner join fds on (
					-- tem interseção
					(fds.range && f.range) or 
					-- ou é adjacente
					(fds.range -|- f.range)
				  ) and 
				  (
				  	-- há dias do feriado que não caem no fds
				  	not isempty(f.range - fds.range) and 
				  	-- há dias do fds que não caem no feriado
				  	not isempty(fds.range - f.range)
				  )
order by least(f.range, fds.range) asc;