select nm_candidato, ds_cargo, sum(vr_bem_candidato)
from bens
natural join candidato
group by 1, 2
order by 3 desc;

select ds_tipo_bem_candidato, count(*), min(vr_bem_candidato), max(vr_bem_candidato)
from bens
group by 1
order by 2 desc;

with com_pos as (
	select *, row_number() over(partition by ds_tipo_bem_candidato order by vr_bem_candidato asc) as pos
	from bens
)
select nm_candidato, ds_tipo_bem_candidato, vr_bem_candidato
from com_pos
natural join candidato
where pos = 1
order by 3 asc;

with candidato_com_total as (
	select sq_candidato, ds_ocupacao, sum(vr_bem_candidato) as total_vr
	from bens 
	natural join candidato
	group by 1, 2
)
select ds_ocupacao, count(*), avg(total_vr) as media_patrimonio, 
min(total_vr) as min_patrimonio, max(total_vr) as max_patrimonio
from candidato_com_total
group by 1
order by 5 desc;

with candidato_com_total as (
	select nm_candidato, ds_cargo, ds_ocupacao, sum(vr_bem_candidato) as total_vr
	from bens 
	natural join candidato
	group by 1, 2, 3
), com_pos as (
	select *, row_number() over(partition by ds_ocupacao order by total_vr desc) as pos
	from candidato_com_total
)
select *
from com_pos
where pos = 1
order by total_vr desc;

select nm_candidato, ds_composicao_coligacao
from candidato;

select nm_candidato, ds_composicao_coligacao,
array_length(regexp_split_to_array(ds_composicao_coligacao, ' / '), 1) as tamanho_coligacao
from candidato
order by 3 desc;

-- existe partido em mais de uma coligação?
with coligacoes as (
	select distinct ds_composicao_coligacao
	from candidato
), coligacoes_com_partidos as (
	select *, unnest(regexp_split_to_array(ds_composicao_coligacao, ' / ')) as partido
	from coligacoes
	where array_length(regexp_split_to_array(ds_composicao_coligacao, ' / '), 1) > 1
)
select partido, unnest(array_agg(ds_composicao_coligacao))
from coligacoes_com_partidos
group by partido
having count(*) > 1
order by 1 asc;

