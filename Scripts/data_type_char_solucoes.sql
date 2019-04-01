-- 1.
-- 502 registros

-- observar que o operador ~ deixa por conta do desenvolvedor explicitar se o match deve ser feito com a string toda ou não
--    por exemplo, se eu quisesse que começasse com um dígito, deveria ter informado o regex ^\d
select * from candidatos_2018.bens 
where ds_bem_candidato ~ '\d';

-- observar a necessidade de adicionar % no início e no fim, indicando que pode ser precedido ou seguido de 0 ou mais caracteres
select * from candidatos_2018.bens 
where ds_bem_candidato similar to '%\d%';


-- 2.
-- 32 registros

-- ^ -> início
-- \d -> dígito
select * from candidatos_2018.bens 
where ds_bem_candidato ~ '^\d';

-- \d -> dígito -> fica implícito o início da string
-- % -> seguido de 0 ou mais caracteres
select * from candidatos_2018.bens 
where ds_bem_candidato similar to '\d%';


-- 3.
-- 2758 registros

-- testo se o valor da coluna é igual a ela em uppercase
select * from candidatos_2018.bens
where ds_bem_candidato = upper(ds_bem_candidato);


-- 4.
-- sq_candidato = 60000612065

-- calculo num subselect o maior valor de tamanho de ds_bem_candidato
--    e então filtro os registros de candidatos_2018.bens cujo tamanho de ds_bem_candidato é igual
select * from candidatos_2018.bens
where length(ds_bem_candidato) = (select max(length(ds_bem_candidato)) from candidatos_2018.bens);

-- performance pior
--    cria ranking, que não é necessário -> preciso apenas do maior
with bens_com_pos as (
    -- rankeio pelo tamanho, em ordem decrescente
    select *, rank() over(order by length(ds_bem_candidato) desc) as pos
    from candidatos_2018.bens
)
select *
from bens_com_pos 
-- pego o maior
where pos = 1;


-- 5.
-- nm_candidato = ENILDE COUTINHO RODRIGUES SALES DE VASCONCELOS

select * from candidatos_2018.candidato
where length(nm_candidato) = (select max(length(nm_candidato)) from candidatos_2018.candidato);

with candidatos_com_pos as (
    select *, rank() over(order by length(nm_candidato) desc) as pos 
    from candidatos_2018.candidato
)
select *
from candidatos_com_pos
where pos = 1;



-- 6. 
-- 24 registros

-- com ilike
select * from candidatos_2018.candidato
where nm_urna_candidato ilike 'dr.%';

-- com regex
select * from candidatos_2018.candidato
where nm_urna_candidato ~* '^dr\.';


-- 7.

select nm_urna_candidato, split_part(nm_urna_candidato, ' ', 1)
from candidatos_2018.candidato
order by 1 asc;

-- usa regexp_split_to_array para quebrar no fim das palavras
--    pega o primeiro valor
select nm_urna_candidato, (regexp_split_to_array(nm_urna_candidato, '\ '))[1] 
from candidatos_2018.candidato
where nm_urna_candidato <> nm_candidato
order by 1 asc;

-- extra 1
select split_part(nm_urna_candidato, ' ', 1), count(*) 
from candidatos_2018.candidato
where nm_urna_candidato <> nm_candidato
group by 1
order by 2 desc;

select (regexp_split_to_array(nm_urna_candidato, '\ '))[1], count(*) 
from candidatos_2018.candidato
where nm_urna_candidato <> nm_candidato
group by 1
order by 2 desc;

select (regexp_matches(nm_urna_candidato, '^[^\ ]+'))[1], count(*) 
from candidatos_2018.candidato
where nm_urna_candidato <> nm_candidato
group by 1
order by 2 desc;


-- 8.


select split_part(nm_email, '@', 2), *
from candidatos_2018.candidato;

-- extra
select split_part(nm_email, '@', 2) as dominio, count(*)
from candidatos_2018.candidato
group by 1
order by 2 desc;

select (regexp_split_to_array(nm_email, '@'))[2] as dominio, count(*)
from candidatos_2018.candidato
group by 1
order by 2 desc;


-- 9 
-- 1 registro

-- ilike
select *
from candidatos_2018.candidato
where nm_email ilike '%ufc.br';


-- 10.

select 
'O candidato '|| nm_candidato || ' está concorrendo ao cargo ' || ds_cargo || '. Ele é natural de ' || nm_municipio_nascimento || '.'
from candidatos_2018.candidato;

select 
format('O candidato %s está concorrendo ao cargo %s. Ele é natural de %s.',
        nm_candidato, ds_cargo, nm_municipio_nascimento)
from candidatos_2018.candidato;

-- extra
select 
'O candidato '|| initcap(nm_candidato) || ' está concorrendo ao cargo ' || initcap(ds_cargo) || '. Ele é natural de ' || initcap(nm_municipio_nascimento) || '.'
from candidatos_2018.candidato;

select 
format('O candidato %s está concorrendo ao cargo %s. Ele é natural de %s.',
        initcap(nm_candidato), initcap(ds_cargo), initcap(nm_municipio_nascimento))
from candidatos_2018.candidato;


-- 11.

-- com lpad
select lpad(nr_cpf_candidato::text, 11, '0') as cpf, *
from candidatos_2018.candidato;

-- com to_char e máscara com 0s
select to_char(nr_cpf_candidato, '00000000000') as cpf, *
from candidatos_2018.candidato;


-- 12.
--WANDER CLEYTON DE ALENCAR   CLEYTON DE ALENCAR, WANDER
--SILMARA DE BRITO SOUZA  DE BRITO SOUZA, SILMARA
--ATTILA SABINO FACANHA BARRETO   SABINO FACANHA BARRETO, ATTILA
--ITALO RIBEIRO ALVES RIBEIRO ALVES, ITALO

-- defino um regex
--    grupo 1
--    (^ -> início da string
--       [^\ ]+ -> 1 ou mais não espaços
--    )
--    \ -> um espaço
--    grupo 2
--    (.*) -> todo o resto
-- recomponho a string, usando os grupos capturados
select nm_candidato, regexp_replace(nm_candidato, '(^[^\ ]+)\ (.*)', '\2, \1')
from candidatos_2018.candidato;


-- 13.

-- aplica um lower à palavra e então busca 'sql' em lowercase
select palavra, strpos(lower(palavra), 'sql')
from (values ('sql123'), ('123SqL123SQLsql'), ('9999sqL999sql')) as t(palavra);


-- 14.
-- 60 registros

select ds_bem_candidato, regexp_matches(ds_bem_candidato, 'placa.*?([a-z]{3}.\d{4})', 'i') 
from candidatos_2018.bens;

-- aplica upper em
--    substitui o caractere separando a parte alfa da numérica por hífen
select ds_bem_candidato, upper(regexp_replace((regexp_matches(ds_bem_candidato, 'placa.*?([a-z]{3}.\d{4})', 'i'))[1], '(.{3}).(.{4})', '\1-\2')) 
from candidatos_2018.bens;

