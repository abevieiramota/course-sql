-- Drop table

-- DROP TABLE public.candidato

CREATE TABLE public.candidato (
	ds_cargo varchar(17) NULL,
	sq_candidato int8 NOT NULL,
	nr_candidato int8 NULL,
	nm_candidato varchar(50) NULL,
	nm_urna_candidato varchar(30) NULL,
	nm_social_candidato varchar(40) NULL,
	nr_cpf_candidato int8 NULL,
	nm_email varchar(50) NULL,
	cd_situacao_candidatura int8 NULL,
	ds_situacao_candidatura varchar(10) NULL,
	cd_detalhe_situacao_cand int8 NULL,
	ds_detalhe_situacao_cand varchar(30) NULL,
	tp_agremiacao varchar(20) NULL,
	nr_partido int8 NULL,
	sg_partido varchar(20) NULL,
	nm_partido varchar(50) NULL,
	sq_coligacao int8 NULL,
	nm_coligacao varchar(40) NULL,
	ds_composicao_coligacao varchar(120) NULL,
	cd_nacionalidade int8 NULL,
	ds_nacionalidade varchar(30) NULL,
	sg_uf_nascimento varchar(2) NULL,
	cd_municipio_nascimento int8 NULL,
	nm_municipio_nascimento varchar(40) NULL,
	dt_nascimento timestamp NULL,
	nr_idade_data_posse int8 NULL,
	nr_titulo_eleitoral_candidato int8 NULL,
	cd_genero int8 NULL,
	ds_genero varchar(9) NULL,
	cd_grau_instrucao int8 NULL,
	ds_grau_instrucao varchar(40) NULL,
	cd_estado_civil int8 NULL,
	ds_estado_civil varchar(30) NULL,
	cd_cor_raca int8 NULL,
	ds_cor_raca varchar(8) NULL,
	cd_ocupacao int8 NULL,
	ds_ocupacao varchar(100) NULL,
	nr_despesa_max_campanha int8 NULL,
	cd_sit_tot_turno int8 NULL,
	ds_sit_tot_turno varchar(6) NULL,
	st_reeleicao varchar(1) NULL,
	st_declarar_bens varchar(1) NULL,
	nr_protocolo_candidatura int8 NULL,
	nr_processo int8 NULL,
	CONSTRAINT sq_candidato_pk PRIMARY KEY (sq_candidato)
)
WITH (
	OIDS=FALSE
) ;
