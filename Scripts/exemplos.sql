-- informações de discentes

select d.ano_ingresso, d.periodo_ingresso, d.nivel, fi.descricao
from discente d 
inner join ensino.forma_ingresso fi using (id_forma_ingresso)
where matricula = 409508;



-- turmas para mátricula do sisu

SELECT 
t.id_turma, t.id_disciplina, t.codigo, cc.id_detalhe, cd.nome, 
r.id_reserva_curso, r.id_matriz_curricular, r.vagas_atendidas, 
COALESCE(ocupadas.total, 0) as vagas_ocupadas, r.grade_horario, r.id_tipo_reserva_curso 
FROM ensino.turma t 
INNER JOIN graduacao.reserva_curso r ON r.id_turma = t.id_turma
                                        -- ingressantes
                                        AND r.id_tipo_reserva_curso = 1 AND r.vagas_atendidas > 0 
INNER JOIN ensino.componente_curricular cc ON cc.id_disciplina = t.id_disciplina 
INNER JOIN ensino.componente_curricular_detalhes cd ON cd.id_componente_detalhes = cc.id_detalhe
-- quantas vagas, por reserva, estão ocupadas?
LEFT JOIN (
    SELECT rc.id_reserva_curso, count(*) AS total 
    FROM ensino.matricula_componente mc
    INNER JOIN graduacao.reserva_curso rc ON rc.id_reserva_curso = mc.id_reserva_curso
    WHERE mc.id_situacao_matricula = 2 -- matriculado
    AND mc.ano = 2018
    AND mc.periodo = 2
    AND rc.id_tipo_reserva_curso = 1 -- ingressante
    GROUP BY rc.id_reserva_curso
    ) AS ocupadas ON ocupadas.id_reserva_curso = r.id_reserva_curso 
WHERE t.ano = 2018 AND t.periodo = 2
-- {a definir docente, aberta}
AND t.id_situacao_turma IN (1, 2) AND cc.nivel = 'G'
-- {atividade, atividade coletiva}
AND cc.id_tipo_componente NOT IN (1, 5);



-- dados de vínculo de discente para o Censo 

INSERT INTO censo_ufc.tipo_42

SELECT  nextval('censo_ufc.tipo_42_seq'), 
    42, --Tipo de Registro
    eleitos.periodo, --Semestre de referencia   

    --Código das matrizes, considerando os Representados
    CASE    WHEN mtr.codigo_inep <> '' AND mtr.codigo_inep IS NOT NULL AND mtr.codigo_inep::INTEGER = 122364 THEN '69190' -- "ENGENHARIA DE TELEINFORMÁTICA (DIURNO) - MT - FORMAÇÃO - FORTALEZA"
        WHEN mtr.codigo_inep <> '' AND mtr.codigo_inep IS NOT NULL AND mtr.codigo_inep::INTEGER = 13985 THEN '29489' --"LETRAS - LICENC. EM LETRAS - HAB. EM LINGUAS CLASSICAS - MT - LICENCIATURA PLENA - FORTALEZA"
        WHEN mtr.codigo_inep <> '' AND mtr.codigo_inep IS NOT NULL AND mtr.codigo_inep::INTEGER = 13979 THEN '99567' --"QUÍMICA INDUSTRIAL - QUIMICA INDUSTRIAL - I - FORMAÇÃO - FORTALEZA"
        WHEN mtr.codigo_inep <> '' AND mtr.codigo_inep IS NOT NULL AND mtr.codigo_inep::INTEGER = 119256 THEN '1259004' --"MAGISTÉRIO INDÍGENA TREMEMBÉ SUPERIOR - MAGISTERIO INDIGENA TREMEMBE SUPERIOR - I - LICENCIATURA INTERCULTURAL - SOBRAL"
        --Curso Indígena teve a representação invertida em 2016
        ELSE mtr.codigo_inep
    END AS codigo_curso,

    NULL, -- Codigo do polo
        
    --Turno 
    CASE when mtr.codigo_inep::INTEGER = 150099 then 3  -- censo 2018/2017 -> apesar de no SIGAA estar matutino/noturno, deverá ser enviado como noturno
        WHEN tno.sigla IN ('MN','TN','MTN','MT','I') THEN  4
        WHEN tno.sigla = 'M' THEN  1
        WHEN tno.sigla = 'T' THEN  2
        WHEN tno.sigla = 'N' THEN  3
        ELSE NULL
    END AS turno,
    
    --Situacao
    case
        --FALECIDO
        when falecido.id_discente is not null then 7 --FALECIDO
        
        --CONCLUÍDO
        WHEN formado.id_discente IS NOT NULL THEN 6 --CONCLUÍDO
        
        --TRANSFERIDO - mudanças de curso(interno)
        WHEN mudou_curso.id_discente IS NOT NULL THEN 5 --TRANSFERIDO

        --CURSANDO
        WHEN cursando.id_discente IS NOT NULL OR cursando_anual.id_discente IS NOT NULL THEN 2 --CURSANDO

        --EM MOBILIDADE
        WHEN mobilidade.id_discente IS NOT NULL THEN 2 --CURSANDO
        
        --TRANCADO
        WHEN trancado.id_discente IS NOT NULL THEN 3 --TRANCADO

        --TRANCADO
        WHEN d.status = 5 THEN 3 --TRANCADO

        --ATIVO, FORMANDO, GRADUANDO com Matrículas antigas
        WHEN d.status IN (1, 8, 9) AND EXISTS (
            SELECT * 
            FROM ensino.matricula_componente
            WHERE id_discente = d.id_discente
            AND (ano*10 + periodo) < (eleitos.ano*10 + eleitos.periodo) 
            AND id_situacao_matricula = 2) --MATRICULADO
        THEN 3 --TRANCADO 
        
        --DESVINCULADO
        WHEN desvinculado.id_discente IS NOT NULL THEN 4 --DESVINCULADO

    END AS situacao,

    --CURSO ORIGEM (Há códigos não inteiros)
    --curso_origem.codigo_curso_anterior AS curso_origem,
    CASE 
        WHEN curso_origem.codigo_curso_anterior<> '' AND curso_origem.codigo_curso_anterior IS NOT NULL AND curso_origem.codigo_curso_anterior::INTEGER = 122364 THEN '69190' -- "ENGENHARIA DE TELEINFORMÁTICA (DIURNO) - MT - FORMAÇÃO - FORTALEZA"
        WHEN curso_origem.codigo_curso_anterior<> '' AND curso_origem.codigo_curso_anterior IS NOT NULL AND curso_origem.codigo_curso_anterior::INTEGER = 13985 THEN '29489' --"LETRAS - LICENC. EM LETRAS - HAB. EM LINGUAS CLASSICAS - MT - LICENCIATURA PLENA - FORTALEZA"
        WHEN curso_origem.codigo_curso_anterior<> '' AND curso_origem.codigo_curso_anterior IS NOT NULL AND curso_origem.codigo_curso_anterior::INTEGER = 13979 THEN '99567' --"QUÍMICA INDUSTRIAL - QUIMICA INDUSTRIAL - I - FORMAÇÃO - FORTALEZA"
        WHEN curso_origem.codigo_curso_anterior<> '' AND curso_origem.codigo_curso_anterior IS NOT NULL AND curso_origem.codigo_curso_anterior::INTEGER = 119256 THEN '1259004' --"MAGISTÉRIO INDÍGENA TREMEMBÉ SUPERIOR - MAGISTERIO INDIGENA TREMEMBE SUPERIOR - I - LICENCIATURA INTERCULTURAL - SOBRAL"
        ELSE curso_origem.codigo_curso_anterior
    END AS curso_origem,

    NULL, -- Semestre de Conclusão - NÃO É OBRIGATÓRIO PARA UFES
    
    --PARFOR
    CASE    WHEN mtr.id_matriz_curricular = 4650171 THEN 1 -- Pedagogia/PARFOR  
        WHEN gra.id_grau_academico IN (2, 5, 7, 12, 8067070) THEN 0 -- [Grau acadêmico igual à LICENCIATURA] -- UFC não tem PARFOR desde 2013.
        ELSE NULL
    END AS parfor,

    (d.ano_ingresso::VARCHAR || d.periodo_ingresso)::VARCHAR AS semestre_ingresso, --Formato numérico?

    NULL, -- Tipo de Escola -- preenchido pela função censo_ufc.f_tipo_42_reserva_vagas_tipo_escola

    --FORMA DE INGRESSO
    CASE    WHEN d.id_forma_ingresso IN (34108, 34110, 38, 41) THEN 1 --"REOPCAO","VESTIBULAR","VESTIBULAR-REOPCAO","VESTIBULAR-CCV"
        ELSE 0 
    END, -- Forma_ingresso Vestibular
    
    CASE    WHEN d.id_forma_ingresso IN (45, 1953825, 994409) THEN 1 --"SELEÇÃO SISU","PROCESSO SELETIVO ENEM","SELECAO"
        ELSE 0 
    END, -- Forma_ingresso Enem

    0, -- Forma_ingresso Seriada
    0, -- Forma_ingresso Simplificada
    

    -- TODO: pode ser refatorado para when eh_estrangeiro then when forma_ingresso in () then 1 else 0 else null, não duplicando a consulta
    --Se for PEC-G e estrangeiro
    CASE    WHEN d.id_forma_ingresso IN (8, 9, 34117) AND EXISTS (SELECT * FROM censo_ufc.tipo_41 t INNER JOIN censo_ufc.censo ce ON (ce.id_censo = t.id_censo AND ce.vigente IS TRUE) WHERE id_pessoa = d.id_pessoa AND nacionalidade = 3) THEN 1 --"CONV PEC-G/MUD CURSO","CONV PEC-G/TRANSF.","CONVENIO PEC-G"
        WHEN EXISTS (SELECT * FROM censo_ufc.tipo_41 t INNER JOIN censo_ufc.censo ce ON (ce.id_censo = t.id_censo AND ce.vigente IS TRUE) WHERE id_pessoa = d.id_pessoa AND nacionalidade = 3) THEN 0
        ELSE 0  
    END, -- Forma_ingresso PEC G
    
    CASE    WHEN d.id_forma_ingresso IN (33) THEN 1 --"TRANSF POR LEI"
        ELSE 0 
    END, -- Forma_ingresso Transferência

    CASE    WHEN d.id_forma_ingresso IN (27, 28, 37) THEN 1 --"ORDEM JUDICIAL","ORDEM JUDICIAL-VEST","VESTIBULAR-ORDEM JUD"
        ELSE 0 
    END, -- Forma_ingresso Judicial

    CASE    WHEN d.id_forma_ingresso IN (2,34,43,34107,34109,34113,34131,34132,34134,8692080,24,25,42,44, 46) THEN 1 --"ADMISSAO DE GRADUADO","TRANSF REGULAR","NOVA MODALIDADE/HABILITAÇÃO","MUDANCA DE CURSO","TRANSFERÊNCIA VOLUNTÁRIA","PORTADOR DE DIPLOMA","REINGRESSO AUTOMATICO","REINGRESSO DE GRADUADO","REINGRESSO SEGUNDO CILCO","TRANSFERÊNCIA DE CURSO EAD - CONVÊNIO Nº 2006/96000020","MUDANCA DE TURNO","NOVA HABILITACAO","MUDANÇA DE SEDE","MUDANÇA DE MODALIDADE", MUDANÇA DE MATRIZ/HABILITAÇÃO
        ELSE 0
    END, -- Forma_ingresso Remanescente
    
    CASE    WHEN d.id_forma_ingresso IN (14,47, 5709456) THEN 1 --CORTESIA DIPLOMATICA, PLAT. PAULO FREIRE, CONVNIO INTERNACIONAL
        ELSE 0 
    END, -- Forma_ingresso Especial3656668744

    -- censo_ufc.f_tipo_42_mobilidade_estudantil
    NULL, -- Mobilidade
    NULL, -- Tipo Mobilidade
    NULL, -- IES Destino
    NULL, -- Tipo Mobilidade Internacional
    NULL, -- Pais Destino
    
    -- censo_ufc.f_tipo_42_reserva_vagas_tipo_escola
    0, -- Reserva Vagas
    NULL, -- Reserva Vagas Etnico
    NULL, -- Reserva Vagas Deficiencia
    NULL, -- Reserva Vagas Escola Publica 
    NULL, -- Reserva Vagas Renda
    NULL, -- Reserva Vagas Outros

    --FINANCIAMENTO NÃO SE APLICA A UFES
    NULL, -- Finaciamento
    NULL, -- Finaciamento Reem FIES
    NULL, -- Finaciamento Reem gov est
    NULL, -- Finaciamento Reem gov mun
    NULL, -- Finaciamento Reem IES
    NULL, -- Finaciamento Reem Externa
    NULL, -- Finaciamento Prouni integral
    NULL, -- Finaciamento Prouni parcial
    NULL, -- Finaciamento Ent Externa
    NULL, -- Finaciamento Gov Estadual
    NULL, -- Finaciamento IES
    NULL, -- Finaciamento Gov municipal

    -- censo_ufc.f_tipo_42_apoio_social_atividade_extracurricular   
    0, -- Apoio Social
    NULL, -- Apoio Social - Alimentaçao
    NULL, -- Apoio Social - Moradia
    NULL, -- Apoio Social - Transporte
    NULL, -- Apoio Social - Material
    NULL, -- Apoio Social - Bolsa Trab
    NULL, -- Apoio Social - Bolsa permanencia

    0, -- Atividade Extracurricular
    NULL, -- Atividade Extracurricular - Pesquisa
    NULL, -- Atividade Extracurricular Bolsa - Pesquisa
    NULL, -- Atividade Extracurricular - Extensao
    NULL, -- Atividade Extracurricular Bolsa - Extensao
    NULL, -- Atividade Extracurricular - Monitoria
    NULL, -- Atividade Extracurricular Bolsa - Monitoria
    NULL, -- Atividade Extracurricular - Estagio
    NULL, -- Atividade Extracurricular Bolsa - Estagio

    crc.ch_total_minima,--CH TOTAL DO CURSO
     
    NULL, --CH TOTAL INTEGRALIZADA
    
    (SELECT id_censo FROM censo_ufc.censo WHERE vigente IS TRUE), -- ID_CENSO -- CENSO ATUAL
    d.id_discente, 
    eleitos.ano,
    p.nome, 
    d.matricula, 
    COALESCE(c.nome||' - '||hab.nome||' - '||gra.descricao||' - '||mun.nome, c.nome||' - '||gra.descricao||' - '||mun.nome) AS curso,
    curso_origem.curso_anterior,
    curso_origem.ano_ingresso,
    curso_origem.periodo_ingresso,
    1, --ORIGEM
    FALSE, --ENVIADO
    TRUE, -- ATIVO
    d.id_discente AS id_ies_aluno, -- ID na IES - Identificação única do aluno na IES
    0 -- Forma_ingresso Egresso BI/LI -- RM_10861
    
FROM public.discente d 
INNER JOIN comum.pessoa p USING (id_pessoa)
inner join censo_ufc.eleitos on (eleitos.id_discente = d.id_discente)
LEFT JOIN comum.tipo_raca tr ON (tr.id_tipo_raca = p.id_raca) --COR/RAÇA
INNER JOIN status_discente sd USING (status)
INNER JOIN graduacao.curriculo crc USING (id_curriculo)
INNER JOIN graduacao.matriz_curricular mtr ON (mtr.id_matriz_curricular = crc.id_matriz)
INNER JOIN public.curso c ON (c.id_curso = mtr.id_curso)
LEFT JOIN ensino.turno tno ON (tno.id_turno = mtr.id_turno)
LEFT JOIN ensino.grau_academico gra ON (gra.id_grau_academico = mtr.id_grau_academico)
LEFT JOIN comum.municipio mun ON (mun.id_municipio = c.id_municipio)
LEFT JOIN graduacao.habilitacao hab ON (mtr.id_habilitacao = hab.id_habilitacao)

--MOVIMENTAÇÃO DE FALECIMENTO
left join(
    SELECT ma.id_discente, 
           ma.ano_referencia AS ano, 
           ma.periodo_referencia AS periodo
    FROM ensino.movimentacao_aluno ma
    WHERE ma.ativo IS TRUE
    AND ma.ano_referencia = 2017
    AND ma.id_tipo_movimentacao_aluno IN (3, 403) -- [FALECIMENTO, FALECIMENTO] 
    GROUP BY ma.id_discente, ma.ano_referencia, ma.periodo_referencia
) as falecido on (falecido.id_discente = d.id_discente AND falecido.ano = eleitos.ano AND falecido.periodo = eleitos.periodo)

--MOVIMENTAÇÃO DE CONCLUSÃO
LEFT JOIN ( 
    SELECT ma.id_discente, 
           ma.ano_referencia AS ano, 
           ma.periodo_referencia AS periodo
    FROM ensino.movimentacao_aluno ma
    WHERE ma.ativo IS TRUE
    AND ma.ano_referencia = 2017
    AND ma.id_tipo_movimentacao_aluno IN (1, 465) -- [CONCLUSÃO, CONCLUSÃO COM PENDÊNCIA]   
    GROUP BY ma.id_discente, ma.ano_referencia, ma.periodo_referencia
) AS formado ON (formado.id_discente = d.id_discente AND formado.ano = eleitos.ano AND formado.periodo = eleitos.periodo)

-- Integralizou componentes somente via APROVEITAMENTOS ou efetuou Trancamento Total, Matrícula Institucional 
LEFT JOIN (
    SELECT mc.id_discente,
           mc.ano,
           mc.periodo
    FROM ensino.matricula_componente mc 
    WHERE mc.ano = 2017
    AND mc.id_situacao_matricula IN (21,22,23) --[DISPENSADO, APROVT INTERNO, APROVT EXTERNO]
    AND NOT EXISTS (
        SELECT * FROM ensino.matricula_componente WHERE id_discente = mc.id_discente AND ano = mc.ano AND periodo = mc.periodo 
        AND id_situacao_matricula IN (2,4,5,6,7,9,27,/*1, 3, 12,10*/ 8,24,25,26) -- [MATRICULADO, APROVADO, TRANCADO, REPROVADO, REP. FALTA, REP. FALTA,"APROVADO_MEDIA",/*"EM ESPERA","CANCELADO","DESISTENCIA","EXCLUIDA"*/,"CONCLUIDO","INCONCLUIDO","SATISFATORIO","INSATISFATORIO]
    )
    GROUP BY mc.id_discente, mc.ano, mc.periodo
        
    UNION

    SELECT ma.id_discente,
           ma.ano_referencia AS ano,
           ma.periodo_referencia AS periodo
    FROM ensino.movimentacao_aluno ma
    WHERE ma.ativo = TRUE 
    AND ma.ano_referencia = 2017
    AND ma.id_tipo_movimentacao_aluno IN (101, 311, 201, 203) -- [TRANCAMENTO DE PROGRAMA, MATRICULA INSTITUCIONAL, "PRORROGAÇÃO ADMINISTRATIVA", "PRORROGAÇÃO POR TRANCAMENTO DE PROGRAMA"]
    GROUP BY ma.id_discente, ma.ano_referencia, ma.periodo_referencia   
) AS trancado ON (trancado.id_discente = d.id_discente AND trancado.ano = eleitos.ano AND trancado.periodo = eleitos.periodo)

-- Cursando
LEFT JOIN (
    SELECT mc.id_discente,
           mc.ano,
           mc.periodo
    FROM ensino.matricula_componente mc 
    WHERE mc.ano = 2017
    AND mc.id_situacao_matricula IN (2, 4, 5, 6, 7, 8, 9, 25, 26, 27) --[MATRICULADO, APROVADO, TRANCADO, REPROVADO, REP. FALTA, REP. FALTA, CONCLUIDO, SATISFATORIO, INSATISFATORIO, APROVADO_MEDIA]
    GROUP BY mc.id_discente, mc.ano, mc.periodo
) AS cursando ON (cursando.id_discente = d.id_discente AND cursando.ano = eleitos.ano AND cursando.periodo = eleitos.periodo)

-- Cursando (Componentes com mais de um período de duração)
LEFT JOIN (
    SELECT 2017 AS ano, 
           1 AS periodo, 
           mc.id_discente
    FROM ensino.matricula_componente mc  
    INNER JOIN ensino.componente_curricular_detalhes ccd USING (id_componente_detalhes)
    WHERE mc.id_situacao_matricula IN (2,4,5,6,7,9,25,26,27) --[MATRICULADO,APROVADO,TRANCADO,REPROVADO,REP. FALTA,REP. FALTA,SATISFATORIO,INSATISFATORIO,APROVADO_MEDIA] 
    AND mc.ano*10 + mc.periodo < 20171
    AND ccd.quantidade_periodos_padrao > 1
    AND public.f_somar_periodo(mc.ano, mc.periodo, ccd.quantidade_periodos_padrao) >= (20171) 

    UNION

    SELECT 2017 AS ano, 
           2 AS periodo, 
           mc.id_discente
    FROM ensino.matricula_componente mc  
    INNER JOIN ensino.componente_curricular_detalhes ccd USING (id_componente_detalhes)
    WHERE mc.id_situacao_matricula IN (2,4,5,6,7,9,25,26,27) --[MATRICULADO,APROVADO,TRANCADO,REPROVADO,REP. FALTA,REP. FALTA,SATISFATORIO,INSATISFATORIO,APROVADO_MEDIA] 
    AND mc.ano*10 + mc.periodo < 20172
    AND ccd.quantidade_periodos_padrao > 1
    AND public.f_somar_periodo(mc.ano, mc.periodo, ccd.quantidade_periodos_padrao) >= (20172) 
) AS cursando_anual ON (cursando_anual.id_discente = d.id_discente AND cursando_anual.ano = eleitos.ano AND cursando_anual.periodo = eleitos.periodo)

--Mobilidade
LEFT JOIN (
    SELECT me.id_discente,
           2017 AS ano, 
           1 AS periodo, 
           MAX(id_programa_mobilidade_estudantil) AS id_programa_mobilidade_estudantil,
           MAX(pais.cod_pais_pingifes) AS cod_pais_pingifes
    FROM ensino.mobilidade_estudantil me
    INNER JOIN comum.pais pais ON (pais.id_pais = me.id_pais_externa)
    WHERE me.ativo IS TRUE
    AND (me.ano = 2017 AND me.periodo = 1
        OR (me.ano*10 + me.periodo < 20171 AND public.f_somar_periodo(me.ano, me.periodo, me.numero_periodos) >= (20171)))
    GROUP BY me.id_discente, 2, 3

    UNION 

    SELECT me.id_discente,
           2017 AS ano, 
           2 AS periodo, 
           MAX(id_programa_mobilidade_estudantil) AS id_programa_mobilidade_estudantil,
           MAX(pais.cod_pais_pingifes) AS cod_pais_pingifes
    FROM ensino.mobilidade_estudantil me
    INNER JOIN comum.pais pais ON (pais.id_pais = me.id_pais_externa)
    WHERE me.ativo IS TRUE
    AND (me.ano = 2017 AND me.periodo = 2
        OR (me.ano*10 + me.periodo < 20172 AND public.f_somar_periodo(me.ano, me.periodo, me.numero_periodos) >= (20172)))
    GROUP BY me.id_discente, 2, 3   
) AS mobilidade ON (mobilidade.id_discente = d.id_discente AND eleitos.ano = mobilidade.ano AND eleitos.periodo = mobilidade.periodo)

--AFASTAMENTO PERMANENTE
LEFT JOIN ( 
    SELECT ma.id_discente, 
           ma.ano_referencia AS ano, 
           ma.periodo_referencia AS periodo
    FROM ensino.movimentacao_aluno ma
    WHERE ma.ativo IS TRUE
    AND ma.ano_referencia = 2017
    AND data_retorno IS NULL
    AND ma.id_tipo_movimentacao_aluno IN (4,6,8,9,10,11,17,308,427,455,459,460,461,462,464,16,436,309,402,432)
    --[TRANSF.P/OUTRA IES,CANCELAMENTO JUDICIAL,EXCLUIDO,DESISTÊNCIA,CANC. NOVO VESTIBULAR,CANC. POR REOPCAO,CANC. DECURSO DE PRAZO MÁXIMO P/ CONCLUSÃO DE CURSO,CANCELAMENTO ESPONTÂNEO,DECISÃO JUDICIAL,DESLIGAMENTO - PEC-G,LIMITE REPROV. FREQ EXCEDIDO - RES. 12/CEPE/19 (06/2008),DESISTÊNCIA - NOVO INGRESSO,DESISTÊNCIA - OUTRA IES,DECISÃO ADMINISTRATIVA,JUBILAMENTO]
    --["ABANDONO", "ADMISSÃO DE GRADUADO", "CADASTRO CANCELADO", "CANCELAMENTO", "TRANSFERÊNCIA"]
    GROUP BY ma.id_discente, ma.ano_referencia, ma.periodo_referencia
) AS desvinculado ON (desvinculado.id_discente = d.id_discente AND desvinculado.ano = eleitos.ano AND desvinculado.periodo = eleitos.periodo)

--MUDANÇA DE CURSO
LEFT JOIN ( 
    SELECT ma.id_discente,
           ma.ano_referencia AS ano,
           ma.periodo_referencia AS periodo
    FROM ensino.movimentacao_aluno ma
    WHERE ma.ativo IS TRUE 
    AND ma.ano_referencia = 2017
    AND ma.id_tipo_movimentacao_aluno IN (405, 414) -- ["MUDANÇA DE CURSO", CONVÊNIO PEC-G/MUDANÇA DE CURSO]    
    GROUP BY ma.id_discente, ma.ano_referencia, ma.periodo_referencia
) AS mudou_curso ON (mudou_curso.id_discente = d.id_discente AND mudou_curso.ano = eleitos.ano AND mudou_curso.periodo = eleitos.periodo)

--CURSO ORIGEM
LEFT JOIN (
    SELECT ingressou.id_discente, p.nome,
           COALESCE(c.nome||' - '||hab.nome||' - '||tno.sigla||' - '||gra.descricao||' - '||mun.nome, c.nome||' - '||tno.sigla||' - '||gra.descricao||' - '||mun.nome) AS curso_anterior,
               mtr.codigo_inep AS codigo_curso_anterior,
           ingressou.curso_atual, ingressou.codigo_inep AS codigo_curso_atual,
           ingressou.ano, ingressou.periodo,
           d.ano_ingresso, d.periodo_ingresso
    FROM public.discente d 
    INNER JOIN comum.pessoa p USING (id_pessoa)
    INNER JOIN graduacao.curriculo crc USING (id_curriculo)
    INNER JOIN graduacao.matriz_curricular mtr ON (mtr.id_matriz_curricular = crc.id_matriz)
    INNER JOIN public.curso c ON (c.id_curso = mtr.id_curso)
    LEFT JOIN ensino.turno tno ON (tno.id_turno = mtr.id_turno)
    LEFT JOIN ensino.grau_academico gra ON (gra.id_grau_academico = mtr.id_grau_academico)
    LEFT JOIN comum.municipio mun ON (mun.id_municipio = c.id_municipio)
    LEFT JOIN graduacao.habilitacao hab on (mtr.id_habilitacao = hab.id_habilitacao)
    INNER JOIN comum.unidade uni ON (uni.id_unidade = c.id_unidade_coordenacao AND uni.id_gestora_academica <> 951 AND uni.id_gestora <> 951) --EXCETO UFCA
    INNER JOIN ( --MOVIMENTAÇÕES DE MUDANÇA DE CURSO
        SELECT ma.id_discente,
               ma.ano_referencia AS ano,
               ma.periodo_referencia AS periodo,
               ma.data_ocorrencia,
               tma.descricao
        FROM ensino.movimentacao_aluno ma
        INNER JOIN ensino.tipo_movimentacao_aluno tma USING (id_tipo_movimentacao_aluno)
        WHERE ma.ativo IS TRUE 
        AND ma.ano_referencia = 2017
        AND ma.id_tipo_movimentacao_aluno IN (405, 414) --MUDANÇA DE CURSO
    ) AS mudou ON (mudou.id_discente = d.id_discente)
    INNER JOIN (
        SELECT p.id_pessoa, d.id_discente, 
               COALESCE(c.nome||' - '||hab.nome||' - '||tno.sigla||' - '||gra.descricao||' - '||mun.nome, c.nome||' - '||tno.sigla||' - '||gra.descricao||' - '||mun.nome) AS curso_atual,
                       mtr.codigo_inep,
               d.ano_ingresso AS ano, d.periodo_ingresso AS periodo
        FROM public.discente d
        INNER JOIN comum.pessoa p USING (id_pessoa)
        INNER JOIN graduacao.curriculo crc USING (id_curriculo)
        INNER JOIN graduacao.matriz_curricular mtr ON (mtr.id_matriz_curricular = crc.id_matriz)
        INNER JOIN public.curso c ON (c.id_curso = mtr.id_curso)
        LEFT JOIN ensino.turno tno ON (tno.id_turno = mtr.id_turno AND mtr.ativo IS TRUE)
        LEFT JOIN ensino.grau_academico gra ON (gra.id_grau_academico = mtr.id_grau_academico)
        LEFT JOIN comum.municipio mun ON (mun.id_municipio = c.id_municipio)
        LEFT JOIN graduacao.habilitacao hab ON (mtr.id_habilitacao = hab.id_habilitacao)
        INNER JOIN ensino.forma_ingresso fi USING (id_forma_ingresso)
        INNER JOIN comum.unidade uni ON (uni.id_unidade = c.id_unidade_coordenacao AND uni.id_gestora_academica <> 951 AND uni.id_gestora <> 951) --EXCETO UFCA
        WHERE d.nivel = 'G' 
        AND d.ano_ingresso = 2017 
        AND d.status <> 10 /*EXCLUIDO*/
        AND fi.id_forma_ingresso IN (34107, 8) --MUDANÇA DE CURSO - PEC G MUD DE CURSO
    ) AS ingressou ON (ingressou.id_pessoa = d.id_pessoa AND ingressou.ano = mudou.ano AND ingressou.periodo = mudou.periodo AND ingressou.id_discente <> mudou.id_discente)
    WHERE d.nivel = 'G' 
    AND d.status <> 10 /*EXCLUIDO*/ 
) AS curso_origem ON (curso_origem.id_discente = d.id_discente AND curso_origem.ano = eleitos.ano AND curso_origem.periodo = eleitos.periodo);