-- 1.
SELECT current_date - '1989-11-29'::date;


-- 2.

SELECT extract(epoch from current_time::time - '13:30'::time) / 60;

select extract(hour from current_time::time - '13:30'::time) * 60 + extract(minute from current_time::time - '13:30'::time);


-- 3.
select extract(epoch from '1 year'::interval) / (60 * 60 * 24);


-- 4.
SELECT 5.2 * '123 minutes'::INTERVAL - '3 hours 4 seconds'::INTERVAL;



-- 5.
select now() - '1989-11-29' > '30 years'::interval;



-- 6.
select to_char(current_date, 'dd/MM/YYYY'),
       to_char(current_date, 'YYYY-MM-dd'),
       to_char(current_date, 'YYYYMMdd');



-- 7.
SELECT format('Eu tenho %s anos', extract(year from age(now(), '1989-11-29')));



-- 8.
with ferias(nome, inicio, fim) as (values 
	('João', '2018-01-01'::date, '2018-01-08'::date),
	('Fernanda', '2018-07-03', '2018-07-21'),
	('Sicrano', '2018-11-02', '2018-11-29'),
	('Beltrano', '2018-12-23', '2019-01-03')),
	eventos(inicio, fim) as (values
	('2018-01-02'::date, '2018-01-03'::date),
	('2018-07-14', '2018-08-13'),
	('2018-09-23', '2018-10-20'),
	('2018-01-08', '2018-01-08')
	)
-- completar o sql
select distinct f.nome
from ferias f
inner join eventos e on (f.inicio, f.fim + '1 day'::interval) overlaps (e.inicio, e.fim + '1 day'::interval);

-- extra
with ferias(nome, inicio, fim) as (values 
    ('João', '2018-01-01'::date, '2018-01-08'::date),
    ('Fernanda', '2018-07-03', '2018-07-21'),
    ('Sicrano', '2018-11-02', '2018-11-29'),
    ('Beltrano', '2018-12-23', '2019-01-03')),
    eventos(inicio, fim) as (values
    ('2018-01-02'::date, '2018-01-03'::date),
    ('2018-07-14', '2018-08-13'),
    ('2018-09-23', '2018-10-20'),
    ('2018-01-08', '2018-01-08')
    )
-- completar o sql
select f.nome, count(*)
from ferias f
inner join eventos e on (f.inicio, f.fim + '1 day'::interval) overlaps (e.inicio, e.fim + '1 day'::interval)
group by 1;



-- 9.
SELECT i, current_date + i * '1 day'::INTERVAL
FROM generate_series(1, 7) AS t(i);



-- 10.
select *
from pg_catalog.pg_stat_activity
-- agora - o início é maior que 5 minutos
where now() - backend_start > '5 minutes'::interval;



-- 11.
select format('Em %s o usuário %s está utilizando o PostgreSQL versão %s, banco %s pelo IP %s.',
			  -- formata a data
			  --    escapa 'de' com aspas duplas
			  to_char(now(), 'hh24:mm "de" dd/mm/yyyy'), 
			  current_user, 
			  -- extrai a versão do servidor
			  (regexp_matches(version(), '^PostgreSQL\ (.*?)\ '))[1], 
			  current_database(),
			  -- gera o ip com a port
			  concat(inet_client_addr(), ':', inet_client_port()));



-- 12.
select extract(epoch from now() - '1989-11-29')::integer;

-- cuidade com a solução 
select extract(epoch from age(now(), '1989-11-29'))::integer;
-- observar o resultado das duas operações
select now() - '1989-11-29', age(now(), '1989-11-29');
-- age retornara os valores em anos, meses etc
--    lembrar que ano e mes não têm um valor fixo de segundos
--    quando se vai extrair segundos de um mês, assume-se que um mês tem 30 dias
-- observar o exemplo
--    com age é retornado um mês
select '2018-02-01'::timestamp - '2018-01-01', age('2018-02-01', '2018-01-01');
 


-- 13.
-- date_trunc para remover os valores menores que seconds
select date_trunc('seconds', now() - pg_postmaster_start_time());



-- 14.
select 2018 + i
from generate_series(1, 100) as t(i)
where extract(dow from '2018-10-28'::date + i * '1 year'::interval) not in (0, 6);