-- https://www.postgresql.org/docs/9.3/static/datatype-datetime.html

-- representação textual de data/hora
--    recomendado yyyy-mm-dd hh:mm:ss.mss
--    o postgresql entende outros formatos > o ideal é usar apenas um

-- exemplos de formatos

-- date

select *
from (values ('2018-06-15'::date), ('2018-01-01'::date), ('01/01/2010'::date)) as t;


-- time

-- a visualização do DBeaver realiza uma formatação sobre os dados, podendo ocultar detalhes, como os microsegundos
-- se não mostrar os microsegundos > Window > Preferences > Data Formats > selecionar Time e alterar pattern para > HH:mm:ss:SSS
select *
from (values ('10:10:10.879'::time), ('08:10'::time), ('08:10 PM'::time)) as t;


-- timestamp

-- se não mostrar os microsegundos > Window > Preferences > Data Formats > selecionar Timestamp e alterar pattern para > yyyy-MM-dd HH:mm:ss:SSS
select *
from (values ('2018-06-12 10:10:10.123'::timestamp), ('2018-01-01'::timestamp), ('01/01/2010'::timestamp)) as t;



-- Valores especiais
select 
-- data 1970-01-01 00:00:00+00
'epoch'::timestamp as epoch, 
-- maior que qualquer timestamp
'infinity'::timestamp as inf,
-- menor que qualquer timestamp
'-infinity'::timestamp as "-inf",
-- tempo de início da transação
'now'::timestamp as now,
-- now à meia noite(00:00:00.000)
'today'::timestamp as today,
-- amanhã à meia noite(00:00:00.000)
'tomorrow'::timestamp as tomorrow,
-- ontem à meia noite(00:00:00.000)
'yesterday'::timestamp as yesterday;



-- intervals
-- https://www.postgresql.org/docs/9.1/static/functions-datetime.html
-- https://www.postgresql.org/docs/9.1/static/datatype-datetime.html#DATATYPE-INTERVAL-INPUT

-- intervals representam uma quantidade de tempo
--    por exemplo '1 dia' e '123 minutos'

-- interval é definido como uma sequência de escalares seguidos de unidades de interval
--    por exemplo '1 day'
--    '1 day 15 minutes 34 seconds'
select '1 day 15 minutes 34 seconds'::interval;

-- entre dois dias, há quantos dias?
--    retorno em inteiro
select '2018-01-02'::date - '2018-01-01'::date;


-- EXERCÍCIO
-- 1. Desenvolva um sql que retorne quantos dias se passaram desde sua data de nascimento
--      utilizar a palavra reservada current_date, para capturar a data atual


-- entre dois dias, em timestamp, há quanto tempo?
--    retorno em interval
select '2018-01-02 10:02'::timestamp - '2018-01-01 14:13:21'::timestamp;


-- para extrair partes do interval, date, time, timestamp
-- https://www.postgresql.org/docs/9.1/static/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT
--    quantos dias?
select extract(day from '2018-01-02'::timestamp - '2018-01-01'::timestamp);

--    quantos minutos?
select extract(minute from '2018-01-02'::timestamp - '2018-01-01'::timestamp);
--    ! mas há 1 dia = 1440 minutos! por que retornou 0?
--    se há 60 minutos, no interval será registrado como 1 hour
--    se há 24 horas, no interval será registrado como 1 day
--    e por aí vai
--    mas se eu quiser a quantidade total de, por exemplo, minutos de um interval?!
--    uma solução é pegar a quantidade de segundos e fazer os cálculos
--    usa-se a key 'epoch' para extrair o total de segundos do intervalo

select extract(epoch from '2018-01-02'::timestamp - '2018-01-01'::timestamp) / 60 || ' minutos';

-- entre dois times, há quanto tempo?
select '10:00'::time - '08:34'::time;

-- entre um timestamp e um time?
--    funciona como interval!
select now() - '02:00'::time;


-- EXERCÍCIO
-- 2. Desenvolva um sql para retornar a quantidade de minutos desde o início da aula 13:30


-- operações com intervals

-- adição de interval a um date/timestamp/time

-- adiciona 1 dia e 10 horas
--    o postgresql converte automaticamente a string para interval
select '2018-01-01 10:00:00'::timestamp + '1 day 10:00' as "+ 1 day 10:00";


-- ou posso fazer um cast explícito
--    '1 day 10:00'::interval, interval '1 day 10:00'
select '2018-01-01 10:00:00'::timestamp + interval '1 day 10:00' as "+ interval '1 day 10:00'";



-- ago 
--    passado > negativo
select '2018-01-01 10:00:00'::timestamp + '1 day ago'::interval as "+ 1 day ago";
--    é a mesma coisa de subtrair
select '2018-01-01 10:00:00'::timestamp - '1 day'::interval as "- 1 day";


-- não é necessário seguir uma ordem entre os campos(ex: year > month > day)
--    no exemplo day vem primeiro que month
select '2018-01-01 10:00:00'::timestamp + '1 day 2 months';


-- é possível adicionar e remover partes do timestamp ao mesmo tempo
--    no exemplo, adiciono 1 dia, removo 1 mês etc
select '2018-01-01 10:00:00'::timestamp + '+ 1 day - 1 month + 10 min - 5 sec';


-- é possível usar valores não inteiros
--    observar que 1 month = 30 days
--                 1 year = ?EXERCÍCIO? days
--    0.5 month = 30/2
--    30/2
select '2018-01-01 10:00:00'::timestamp + '0.5 month' as "+ 0.5 month";



-- EXERCÍCIO
-- 3. Desenvolva sql que calcule a quantidade de dias em um '1 year'::interval
--       considerar um dia como contendo 60 * 60 * 24 segundos



-- observar que caso não especificado e não utilizado em uma operação que faça o cast
--    '0.5 month' é uma string!
select '0.5 month' as "String 0.5 month";
-- com cast explícito
select '0.5 month'::interval as "Interval 0.5 month";


-- é possível fazer cálculos com interval
--    somar/subtrair dois intervals
select '7 minutes'::interval + '1 hour'::interval - '234 seconds'::interval;


--    multiplicar/dividir por um escalar
select 10 * '1 min 13 sec'::interval as "10 * 1 min 13 sec";

select 3 * '1 day 10 hours 35 seconds'::interval as "3 * 1 day 10 hours 35 seconds";

select 1.5 * '1 day'::interval as "1.5 * 1 day";
-- mesmo resultado, duas formas de definir
select '1 day'::interval / 20 as "1 day / 20", '0.05 day'::interval;



-- EXERCÍCIO
-- 4. Desenvolva sql para calcular quanto é 5.2 vezes 123 minutos menos 3 horas e 4 segundos



-- nas operações com date/timestamp
--    1 month = 1 mês, e não 30 dias!
--    observar que a quantidade de dias incrementados depende do mês
--    incrementar 1 mês em fevereiro de 2018
--       incrementa 28 dias
select ('2018-02-01'::date + '1 month'::interval) - '2018-02-01'::date;
--    incrementar 1 mês em março
--       incrementa 31 dias
select ('2018-03-01'::date + '1 month'::interval) - '2018-03-01'::date;





-- formatação
-- +formatos > https://www.postgresql.org/docs/9.3/static/functions-formatting.html

-- TO_CHAR(timestamp, formato)
--    dia/mês/ano
--    DD/MM/YY
select to_char('2018-05-10 18:00:00'::timestamp, 'DD/MM/YY');

-- HH é hora em formato 12h 
--    AM para indicar meridiano
select to_char('2018-05-10 18:00:00'::timestamp, 'HH:MI:SS AM');

-- HH24 é hora em formato 24h
select to_char('2018-05-10 18:00:00'::timestamp, 'HH24:MI:SS');

-- outro exemplo de formatação de data
select to_char('2018-05-10 18:00:00'::timestamp, 'DD-MM-YYYY');


-- exemplos de forma de formatar MÊS
--    observar que a única informação do timestamp sendo utilizada é o mês
--    formato + resultado
select formato, to_char('2018-05-10 18:00:00'::timestamp, formato), descricao
from (values ('MM', 'month number (01-12)'), ('Month', 'full capitalized month name (blank-padded to 9 chars)'), 
             ('month', 'full lower case month name (blank-padded to 9 chars)'), 
             ('MONTH', 'full upper case month name (blank-padded to 9 chars)'), 
             ('Mon', 'abbreviated capitalized month name (3 chars in English, localized lengths vary)'), 
             ('mon', 'abbreviated lower case month name (3 chars in English, localized lengths vary)'), 
             ('MON', 'abbreviated upper case month name (3 chars in English, localized lengths vary)')) as t(formato, descricao);


             -- exemplos de forma de formatar DIA
select formato, to_char('2018-05-10 18:00:00'::timestamp, formato), descricao
from (values ('DD', 'day of month (01-31)'), ('Day', 'full capitalized day name (blank-padded to 9 chars)'), 
             ('day', 'full lower case day name (blank-padded to 9 chars)'), ('DAY', 'full upper case day name (blank-padded to 9 chars)'), 
             ('Dy', 'abbreviated capitalized day name (3 chars in English, localized lengths vary)'), 
             ('dy', 'abbreviated lower case day name (3 chars in English, localized lengths vary)'), 
             ('DY', 'abbreviated upper case day name (3 chars in English, localized lengths vary)'),
             ('D', 'day of the week, Sunday (1) to Saturday (7)'),
             ('DDD', 'day of year (001-366)'),
             ('W', 'week of month (1-5) (the first week starts on the first day of the month)'),
             ('WW', 'week number of year (1-53) (the first week starts on the first day of the year)')) as t(formato, descricao);



-- EXERCÍCIO
-- 6. Desenvolva um sql que retorne a data atual formatada das seguintes formas(cada uma em uma coluna)
--      10/01/2018
--      2018-01-10
--      20180110



-- Funções e operadores
-- https://www.postgresql.org/docs/9.3/static/functions-datetime.html

-- AGE
--    age(x, y)
--      quantos anos, meses e dias de y a x
--    ex:
--       age(01/03, 01/02) -> 1 mês
--       age(01/04, 01/03) -> 1 mês
--    apesar de a quantidade de dias passados serem diferentes!
select d, a, age(d, a), d::timestamp - a
from (values ('2018-03-01'::date, '2018-02-01'::date), ('2018-04-01', '2018-03-01')) as t(d, a);

-- age(x, x) = 0
select age('2018-01-01', '2018-01-01');

-- ! CUIDADO
--    na comparação, 1 year = 30 * 12 days!
--    extract(now() - '1989-11-29') / (30 * 12)
select now() - '1989-11-29'::date > '29 years'::interval;
       


-- EXERCÍCIO
-- 5. Desenvolva sql para calcular se alguém, que nasceu em uma data x, já tem mais de 30 anos

-- 7. Desenvolva um sql para retornar a sua idade em anos
--       utilizar o formato "Eu tenho {idade} anos"



-- iniciem a transação
--    coloquem em modo Record
--    executem os selects algumas vezes e observem os campos que mudam
--    dê rollback

begin;
    select d as data,
    -- o clock_timestamp mostra o momento de execução do statement, diferentemente de current_timestamp e now(), que mostram o start da transação
    --    observar que ele não varia entre chamadas num mesmo statement
    clock_timestamp(), 
    clock_timestamp(),
    -- current_timestamp, now() -> captura o tempo de início DA TRANSAÇÃO
    current_timestamp, now(),
    current_date, current_time
    from (select '2018-02-22 10:48:00'::timestamp) as t(d);

    -- date_part e extract são equivalentes e permitem extrair partes do date/timestamp
    -- date_part('hour', d) = extract(hour from d)
	select d as data,
    date_part('hour', d) as hora, extract(hour from d),
    -- dia da semana -> dow
    --    0 sunday -> 6 saturday
    date_part('dow', d) as dia_da_semana,
    -- dia da semana -> isodow
    --    1 monday -> 7 sunday -> única diferença é domingo
    date_part('isodow', d) as dia_da_semana_iso,
    -- dia do ano
    --    0->365/366
    date_part('doy', d) as dia_do_ano,
    -- minutos
    date_part('minute', d) as minuto,
    -- mês
    date_part('month', d) as mes,
    -- para intervals, extrai o que foi especificado
    -- lembrar '1 month'::interval não quer dizer 30 dias! é 1 mês
    -- extrai literal -> no interval não há especificada quantidade de meses
    --    retorna 0!
    date_part('month', '35 days'::interval) as ex_date_part_interval
    from (select '2018-02-22 10:48:00'::timestamp) as t(d);
rollback;



-- date_trunc
--    remover partes do date/timestamp
--    date_trunc(x, data) -> seta para o menor valor os campos menos significantes que x
--    ex: x = day -> vai fazer hora = 0 minuto = 0 segundos = 0 etc
select d, 
-- ajusta para o menor valor tudo que é menor que dia
date_trunc('day', d) as day,
-- para mês
--    x = month -> vai fazer day = 1, menor valor
date_trunc('month', d) as month,
-- para minuto
date_trunc('minute', d) as minute
from (select '2018-02-10 10:48:30'::timestamp) as t(d);


-- justify_days
select d,
-- converte 
--    justify_days 30 dias em 1 mês
--    justify_hours 24 horas em 1 dia
--    retornando um interval
-- ocorre que 1 mês de interval pode incrementar 30 dias, 31, 28, 29 etc dependendo da data ao qual for somado!
justify_days('35 days') as justify, 
-- adiciona 35 dias a 2018-02-10, fevereiro
d + '35 days'::interval as "d + interval 35 days",
-- adiciona 35 dias justificados -> 1 month + 5 days
d + justify_days('35 days') as "d + justify_days 35 days", 
-- justify_hours
--    24 hours -> 1 day
justify_hours('27 hours')
from (select '2018-02-10 10:48:30'::timestamp) as t(d);

-- 13º
--    supondo que 1 mês tem 4 semanas e um ano tem 12 meses, quantos meses tem em um ano
--    supondo que o ano tem 365 dias, quantas semanas há em um ano 
select 1 * 4 * 12, 
       365 / 7;



-- overlaps
--    verifica interseção entre intervalos de date, timestamp, times
--    os intervalos (s1, s2) são considerados como s1 <= t < s2

-- observar que o final do intervalo não é incluído    
select ('2018-01-01'::date, '2018-02-02'::date) overlaps ('2018-02-02'::date, '2018-03-01'::date) as "[01/01, 02/02] e [02/02, 01/03]";

-- dia 03/02 presente nos dois
select ('2018-01-01'::date, '2018-02-03'::date) overlaps ('2018-02-02'::date, '2018-03-01'::date) as "[01/01, 03/02] e [02/02, 01/03]";

-- pode usar intervalo
--    (início, n dias depois)
select ('2018-01-01'::date, '1 day'::interval) overlaps ('2018-01-01'::date, '2018-03-01'::date) as "[01/01, +1 day] e [01/01, 01/03]";

-- se os dois extremos são iguals, é considerado um ponto no tempo
--    s1 = s2 -> ponto no tempo
-- ver que o ponto final do intervalo não está contido nele
--    no exemplo, verifica-se se o ponto 01/03 está no intervalo [01/01, 01/03)
select ('2018-03-01'::date, '2018-03-01'::date) overlaps ('2018-01-01'::date, '2018-03-01'::date) as "[01/03, 01/03] e [02/02, 01/03]";

-- já o ponto inicial é inclusive
--    verifica se o ponto 02/02 está no intervalo [02/02, 01/03)
select ('2018-02-02'::date, '2018-02-02'::date) overlaps ('2018-02-02'::date, '2018-03-01'::date) as "[02/02, 02/02] e [02/02, 01/03]";




-- EXERCÍCIO


-- 8. Desenvolva um sql que retorne as pessoas cujas férias têm interseção com eventos
--      a semântica de início e fim são datas que incluem as férias/evento
--      por exemplo, as férias com (início, fim) = (2018-01-01, 2018-01-08) significa que a pessoa estará de férias do dia 01/01 ao dia 01/08 inclusive
--      Extra: retorne a quantidade de eventos com os quais há interseção
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
select *
from ferias, eventos;


-- 9. Desenvolva um sql que retorne os próximos 7 dias como date. Utilizar como base o sql
SELECT i
FROM generate_series(1, 7) AS t(i);


-- 10. Desenvolva um sql que retorne quais sessões no PostgreSQL estão ativas há mais de 5 minutos
--       fazer uso das informações na view pg_catalog.pg_stat_activity
--       o início da sessão é registrado na coluna backend_start

-- 11. Desenvolva um sql para retornar o seguinte texto, preenchido com as variáveis
--       Em {momento atual em formato 'hh:mm de dd/mm/yyyy') o usuário {usuário} está utilizando o PostgreSQL versão {versão}, banco {banco} pelo IP {ip:port}.
--       Ex: Em 20:13 01/02/1978 o usuário postgres está utilizando o PostgreSQL versão 10.1, banco meu_banco pelo IP 192.168.0.1:5252.
--       https://www.postgresql.org/docs/9.2/static/functions-info.html       
--          o momento deve ter horas em formato 24h
--             observar que há um "de" entre a hora e a data
--             para que o 'd' não seja substituído pelo dia da semana, escapá-lo com aspas duplas
--          considerar que a função que retorna a versão do banco retorna no formato 'PostgreSQL {versão}, ...'


-- 12. Desenvolva sql para calcular quantos segundos de vida você já viveu até agora, considerando que nasceu às 00:00:00.000


-- 13. Desenvolva um sql para retornar há quanto tempo o servidor do PostgreSQL está em funcionamento
--       truncar até os segundos
--          ex: se o resultado for '10 hours 50.1234 seconds', deve-se retornar '10 horas 50 seconds'
--       https://www.postgresql.org/docs/9.2/static/functions-info.html 


-- 14. Desenvolva um sql que retorne, dentro dos próximos 100 anos, aqueles em que o dia do servidor público federal(28/10) irá cair na semana
