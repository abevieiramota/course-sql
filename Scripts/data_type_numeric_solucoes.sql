-- 1. 
-- aplica trunc, removendo a parte decimal
select *, trunc(vr_bem_candidato) from candidatos_2018.bens;

-- converte para integer
select *, vr_bem_candidato::integer from candidatos_2018.bens;

-- aplica floor
select *, floor(vr_bem_candidato) from candidatos_2018.bens;

-- remove parte decimal
select *, vr_bem_candidato - mod(vr_bem_candidato, 1) from candidatos_2018.bens;


-- 2.
-- aplica 10%
--    vr_bem_candidato * 0.1
-- aplica floor
select vr_bem_candidato, floor(vr_bem_candidato * 0.1),
greatest(1234, floor(vr_bem_candidato * 0.1))
from candidatos_2018.bens;


-- 3.
select *
from candidatos_2018.bens 
where mod(vr_bem_candidato, 10) <> 0;


-- 4.
-- verifica se o valor é igual ao cast para inteiro sobre ele
--    no cast para integer é descartada a parte decimal
select *
from candidatos_2018.bens 
where vr_bem_candidato::integer <> vr_bem_candidato;

-- verifica se o valor é igual ao trunc sobre ele
--    o trunc descarta a parte decimal
select * 
from candidatos_2018.bens 
where trunc(vr_bem_candidato) <> vr_bem_candidato;

-- verifica se o resto da divisão do valor por 1, que retorna a parte decimal, é diferente de 0
select *
from candidatos_2018.bens 
where mod(vr_bem_candidato, 1) <> 0;

-- verifica se o arredondamento do valor para baixo é diferente do valor
select *
from candidatos_2018.bens
where floor(vr_bem_candidato) <> vr_bem_candidato;


-- 5.
-- calcula, com random(), um valor aleatório de 0 a 1
--    ordena por esse valor, de forma decrescente
--    retorna apenas o primeiro resultado
select random(), *
from candidatos_2018.candidato
where ds_cargo = 'GOVERNADOR'
order by 1 desc
limit 1;

-- para todos os cargos
with com_pos as (
    -- retorna os dados de candidato e uma coluna pos, indicando, dentro de um cargo, a posição dos candidatos àquele cargo, ordenados de forma aleatória
    select *, row_number() over(partition by ds_cargo order by random() desc) as pos 
    from candidatos_2018.candidato
    where ds_cargo in ('GOVERNADOR', 'DEPUTADO ESTADUAL', 'DEPUTADO FEDERAL', 'SENADOR')
)
select ds_cargo, nm_candidato, sg_partido
from com_pos 
-- seleciona os candidatos que dentro de seus grupos, por cargo, ficaram com a posição 1
where pos = 1
order by ds_cargo asc;
