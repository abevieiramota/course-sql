-- 0. Instruções
--    Buscar treinar nos exercícios os comandos apresentados

-- 1. Instalação


-- 2. Atualização


-- 3. Interface


-- 4. Criar conexão com banco curso_sql

-- File > New > Database - Database Connection
-- Crtl+N > Database - Database Connection

-- dados de conexão

-- host: 200.17.41.119 port: 5432
-- database: curso_sql
-- user: curso_sql
-- >Marcar: Save assword locally
-- >Marcar: Show non-default databases
-- >Nomear a conexão
-- >Selecionar o Connection type
-- ->Development -> transparente, auto-commit,   sem confirmação
-- ->Test        -> verde,        auto-commit,   sem confirmação
-- ->Production  -> vermelho,     manual commit, com confirmação

-- É possível em uma mesma conexão, onde é informado qual o banco a ser acessado, alterar o banco em utilização
-- >Click direito no banco que deseja utilizar > Set active object
-- Recomendo manter uma conexão registrada por banco - em caso de vários bancos por servidor, basta registrar um e ir dando Crtl+c/Crtl+v e ajustando apenas o banco
--    em >Click direito > Edit Connection
-- EXEMPLO: nova conexão para o banco sigaa

-- EXERCÍCIO: Criar conexões com bancos {sigaa, sistemas_comum, sistemas_log, administrativo} - mesmo servidor e usuário, nomes de conexão diferentes
-- EXERCÍCIO: Testar o comando abaixo com connection type(default) Development
--               o esperado é que seja executado o create table, sem confirmação
begin;
    create table remuneracao_ufc.oi (id int);
rollback;
-- Testar alterar o tipo de conexão de uma das conexões para Production
--    >Click direito > Edit Connection > General
--    testar o comando abaixo
--    o esperado é que seja pedida confirmação para executar o create table
begin;
    create table remuneracao_ufc.oi (id int);
rollback;

-- É possível organizar as conexões em pastas
-- >Click direito em Connections > New Folder
-- >Click e arrastar conexões para as pastas

-- EXERCÍCIO: criar pasta BANCO_119 e copiar as conexões criadas


-- #apresentar a estrutura dos objetos na árvore da conexão


-- 5. Realizar consultas

-- Criar script -> >Click direito na conexão > Click no botão de adicionar Script

-- Localização dos Scripts > Seção Scripts >Click direito > Properties > Location


-- Execução
--    >Click direito no statement(dentro ou depois, antes do próximo) > Execute > Execute SQL statement
--    >Crtl + Enter
--    >Click no botão seta laranja à esquerda
-- Por default os statements são separados;
select * from candidatos_2018.bens;
select * from candidatos_2018.candidato;

-- é possível visualizar a consulta executada passando o mouse sobre o trecho de consulta na barra superior da view

-- EXERCÍCIO: Desenvolver e executar consultas para responder
--    Nome(nm_candidato) de candidatos cuja ds_ocupacao é MOTORISTA PARTICULAR
--    Nome, data de nascimento e idade, em anos, de candidatos com mais de 70 anos
--       calcular idade em anos com extract(year from age(now(), dt_nascimento))
select nm_candidato from candidatos_2018.candidato where ds_ocupacao = 'MOTORISTA PARTICULAR';

select nm_candidato, dt_nascimento, extract(year from age(now(), dt_nascimento))::int as idade
from candidatos_2018.candidato where extract(year from age(now(), dt_nascimento)) > 70;


-- Execução em outra aba
--    As vezes queremos visualizar o resultado de duas execuções ao mesmo tempo
--    >Crtl+\
--    ou clicando no botão seta laranja+ à esquerda

-- EXERCÍCIO: Desenvolver e executar consultas para responder. Utilizar a execução em múltiplas abas
--    Nome, cargo(ds_cargo) e idade de candidatos cuja ds_ocupacao é ANALISTA DE SISTEMAS
--    Nome, cargo e idade de candidatos cuja ds_ocupacao é PESCADOR

select nm_candidato, ds_cargo, extract(year from age(now(), dt_nascimento))::int as idade
from candidatos_2018.candidato where ds_ocupacao = 'ANALISTA DE SISTEMAS';

select nm_candidato, ds_cargo, extract(year from age(now(), dt_nascimento))::int as idade
from candidatos_2018.candidato where ds_ocupacao = 'PESCADOR';


-- Autocomplete
--    por default vai autocompletando > basta selecionar um dos itens do autocomplete e apertar Enter
--    em um contexto em que o autocomplete foi desabilitado(por exemplo, apertando ESC quando ele estive ativo), basta apertar >Crtl + espaço

-- EXERCÍCIO: Digitar
--    select * from cand  
--    autocompletar com o esquema
--    apertar ESC
--    apertar >Crtl + espaço, para ativar o autocomplete
--    autocompletar com a tabela candidato

select * from candidatos_2018.candidato;


-- Template
--    DBeaver permite o uso de templates
--    scgb > Select Count Group by
--    para ativar um template -> escrever a chave do template e apertar Tab > preencher os slots

-- EXERCÍCIO: Desenvolver, com o template scgb:
--    consulta para listar as ds_ocupacao e a quantidade em candidatos_2018.candidato
--    consulta para listar as ds_tipo_bem_candidato e a quantidade em candidatos_2018.bens

select ds_ocupacao,count(*)
from candidatos_2018.candidato t group by ds_ocupacao;

select ds_tipo_bem_candidato,count(*)
from candidatos_2018.bens t group by ds_tipo_bem_candidato;

--    scount > Select COUNT

-- EXERCÍCIO: Desenvolver, com o template scount:
--    consulta para calcular a quantidade de registros na tabela candidatos_2018.candidato
--    consulta para calcular a quantidade de registros na tabela candidatos_2018.bens

select count(*) from candidatos_2018.candidato;
select count(*) from candidatos_2018.bens;

--    sob > Select Order by

-- EXERCÍCIO: Desenvolver, com o template sob:
--    consulta para retornar os candidatos(todas informações *) ordenados por nome(nm_candidato), tabela candidatos_2018.candidato
--    consulta para retornar os bens(todas informações *) ordenados por valor(vr_bem_candidato) DESCENDENTE, tabela candidatos_2018.bens

select * from candidatos_2018.candidato t order by nm_candidato;
select * from candidatos_2018.bens t order by vr_bem_candidato desc;

--    swhere > Select where

-- EXERCÍCIO: Desenvolver, com o template swhere:
--    consulta para retornar os candidatos(todas informações *) cujo cargo(ds_cargo) é SENADOR

select * from candidatos_2018.candidato where ds_cargo='SENADOR';

-- Templates podem ser criados em Window > Preferences > General > Editors > SQL Editor > Templates
-- ? alguma sugestão de template ?
-- ex:
--    with oi as (
--       select *, row_number() over(partition by ${partition} order by ${ordering}) as pos
--       from ${table}
--    )
--    select *
--    from oi 
--    where pos = 1


-- Navegação nos objetos utilizados no SQL
--    é possível acessar objetos utilizados no sql -> >Crtl + click

-- EXERCÍCIO: Escrever consulta para selecionar todos os candidatos
--    Navegar para a tabela candidato

select * from candidatos_2018.candidato;

-- A view de dados da tabela é a mesma de retorno da consulta
--    as linhas são enumeradas
--    as colunas possuem indicador do domínio(textual, numérico)
--    embaixo à direita há informações sobre a execução(quantidade de linhas carregadas, tempo de execução(?? acredito que o primeiro é tempo de fetch, o segundo de rendering))

-- Executar
select * from candidatos_2018.candidato;

-- Por default uma execução irá carregar no máximo os primeiros 200 registros da consulta
--    para retornar mais: 
--       descer a tabela até o fim, o DBeaver irá carregar mais 200 registros
--       botão Fetch next page of results(ao lado da seta >|)
--    para retornar todos:
--       executar com >Click direito > Execute > Select all rows
--       executar com >Crtl + Alt + \
--       botão Fetch all rows(ao lado da seta >|)
--    para alterar o valor default de fetch > Window > Preferences > Database > Result Sets - ResultSet Fetch Size


-- EXERCÍCIO: executem a consulta por todos os candidatos, carregando todas as linhas


-- Visualização do resultado em Grid x Text
--    por default > Grid
--    pode ser alterado para Text > botão Text, ao lado do botão Grid


-- EXERCÍCIO: visualizem o retorno da consulta tanto no modo Grid quanto no modo Text


-- Visualização de registro individual
--    para visualizar um registro individual, pode-se selecionar o registro e clicar em Record
--    para sair do modo Record, basta clicar nele novamente
--    é possível ordenar as colunas por nome


-- EXERCÍCIO: visualizar algum registro com o modo Record e depois voltar para o modo default


-- Ordenação de resultados 
--    na view de dados é possível solicitar que os dados sejam ordenados de acordo com uma coluna
--    >Click nas setas à direta do nome da coluna(ordenação ascendente; outro click -> descendente; outro click -> reseta)
--    é possível ordenar por mais de um critério, ordenando por duas ou mais colunas 


-- EXERCÍCIO: ordenar os resultados por ds_cargo e nm_candidato


-- Filtragem do resultado
--    é possível filtrar o resultado
--       no campo superior onde há Enter a sql expression to filter results(há autocomplete) > Enter
--       clicando no símbolo de funil no lado direito do nome das colunas e selecionando um valor
--    os filtros ficam salvos num histórico(triângulo para baixo no campo de filtros)
--    para limpar o filtro corrente
--       deletar a definição do filtro e filtrar novamente
--       clicar no símbolo de funil com X vermelho


-- EXERCÍCIO: filtrar os resultados incluindo apenas aqueles com ds_cargo = DEPUTADO ESTADUAL
--    remover os filtros


-- Panels
--    existem 4 tipos de panels que podem ser utilizados para visualizar os dados

-- EXERCÍCIO: Desenvolver e executar consulta sobre candidatos e bens

select *
from candidatos_2018.candidato
natural join candidatos_2018.bens;

--    Value > permite ver o valor de uma célula na grid
--       permite fazer alterações nos valores e salvar(para desfazer a alteração, local, clicar no documento com X vermelho na barra superior)
--       permite visualizar colunas de tabelas referenciadas(testar com alguma célula de uma foreign key)

-- EXERCÍCIO: abrir o panel Value e testar com algumas células, textual e numérica
--    executar consulta por todos os bens e testar visualizar a coluna sq_candidato
--    alterar a Description para nm_candidato
select * from candidatos_2018.bens;


--    Calc > permite realizar alguns cálculos sobre conjuntos de células
--       ex: selecionar um conjunto de células numéricas > irá mostrar o count, count distinct, sum 
--       é possível adicionar novas operações {average, minimum, maximum, median, mode}
--       é possível agrupar por colunas, no caso de terem sido selecionadas colunas de mais de uma coluna

-- EXERCÍCIO: abrir o panel Calc e testar usando a última coluna, vr_bem_candidato, selecionando um conjunto de valores
--    adicionar a operação SUM
--    testar variando o conjunto de dados selecionados


--    Grouping > permite realizar operações de agregação sobre colunas dos dados
--       ex: count de registros por ds_cargo(drag-and-drop ds_cargo para o panel)
--       é possível usar sub grupos > ex: adicionar ao grouping a coluna ds_genero
--       é possível utilizar outras funções de agregação(tal como com select group by)

-- EXERCÍCIO: abrir o panel Grouping e mover ds_cargo
--    adicionar a função avg(vr_bem_candidato)
--    mover sg_partido
--    ordenar por ds_cargo


--    Metadata > permite visualizar metadados das colunas, como domínio e tabela donde veio

-- EXERCÍCIO: abrir o panel Metadata e analisar


-- Navegar entre objetos através de relacionamentos

select * from candidatos_2018.bens;

--    é possível clicar em células de chaves estrangeiras e navegar para o registro correspondente
--    esse movimento é salvo em um histórico, que pode ser utilizado com os atalhos Alt + seta direita/seta esquerda


-- Exportar resultados de consultas

--    é possível exportar o resultado de consultas para diversos formatos, como XML, JSON, HTML, CSV, formato do DbUnit, inserts SQL, markdown, Database
--    >Click direito na consulta > Execute > Export from Query

-- EXERCÍCIO: Desenvolver uma consulta pelos bens cujos valores sejam superiores a 100000(CEM MIL) e exportar o resultado para CSV, com separador ; e encoding ISO-8859-1
select *
from candidatos_2018.bens
where vr_bem_candidato > 100000;


-- Refresh de consultas
--    é possível configurar o DBeaver para fazer refresh de consultas periodicamente

-- EXERCÍCIO: Executar a consulta abaixo e configurar o refresh automático de 1s

select now();


-- Consultas com parâmetros
--    é possível configurar o DBeaver para executar consultas utilizando parâmetros, prefixados com :
--    ex:
select *
from candidatos_2018.candidato
where ds_cargo = :cargo and ds_genero = :genero;


-- EXERCÍCIO: Desenvolver e testar consulta parametrizada pela sigla do partido do candidato(sg_partido)


-- Calcular a quantidade de registros retornados por uma consulta
--    o DBeaver possui uma operação de calcular a quantidade de registros de uma consulta
--    por baixo dos panos ele envolve a consulta em um select count(*) from (CONSULTA)
-- >Click direito > Execute > Select row count

select * from candidatos_2018.candidato;


-- Controle de transação
--    o DBeaver possui dois modos de controle de transação
--       auto-commit > cada statement é mandado em uma transação
--       manual commit > as execuções de statements abrem uma transação, se não houver uma aberta, ou reusam a aberta, caso contrário; commit/rollback com botão no topo
--       o DBeaver vai mantendo o histórico de statements da transação > contador na barra superior(!acho que está bugado!)


-- EXERCÍCIO: Alterar para o modo de commit manual e executar o sql

create table tabela(id int);
--    executar a consulta
select * from tabela;
--    clicar em rollback
--    executar novamente a consulta e verificar que a criação da tabela foi desfeita


-- Geração automática de sql
--    o DBeaver permite gerar alguns tipos de sql automaticamente
--    >Click direito sobre tabela > Generate sql
--       select, insert, update, delete, merge, DDL


-- EXERCÍCIO: gerar e analisar a DDL da tabela candidatos_2018.bens


-- Atualização/exclusão de registros a partir da view de dados
--    o DBeaver permite fazer alterações em registros a partir da view de dados
--    por exemplo, ao selecionar uma linha e apertar Delete, o DBeaver irá marcar aquela linha como A deletar
--       ao clicar duas vezes em uma célula e alterar seu valor, o DBeaver irá registrá-la como A alterar
--       visualmente a linha/célula será diferenciada das demais
--    para persistir as mudanças, deve-se clicar no botão Save, na parte de baixo à esquerda
--       ou >Crtl + S (! deveria ser Crtl + Alt + S, mas acredito haver um bug que permite salvar com Crtl + S)
--    para desfazer as mudanças, deve-se clicar no botão Cancel, ao lado do botão Save

select * from candidatos_2018.candidato;


create table candidatos_2018.exercicio(id int primary key, nome text);
insert into candidatos_2018.exercicio select i, 'nome '||i from generate_series(1, 20, 1) as t(i);
-- EXERCÍCIO: Desenvolver e executar consulta para retornar todos os valores da tabela exercicio

select * from exercicio;

--    selecionar alguma linha, ir para o modo Record e alterar o nome para o seu nome > salvar


-- Diagramas ER
--    o DBeaver permite visualizar diagramas ER das tabelas e seus relacionamentos
--    >Duplo clique na tabela > aba ER Diagram
--    é possível controlar que colunas são apresentadas, >Click direito na view > show attributes 
--    é possível mostrar/ocultar o esquema da tabela, >Click direito na view > view styles
--    é possível adicionar uma grid > parte de baixo direita, botão com símbolo de grid
--    é possível navegar nas tabelas, clicando duas vezes no nome delas

-- notação
--    <>(N) ---- o (1)
create table a(id int primary key);
create table b(id int primary key, a_id int references a(id));
create table c(id int primary key, a_id int not null references a(id));
create table e(b_id int references b(id), c_id int references c(id));

--    é possível criar um diagrama com tabelas escolhidas
--    >Crtl + N > DBeaver > ER Diagram -> selecionar tabelas e dar nome ao diagrama

--    é possível exportar o diagrama como PNG -> botão com símbolo de imagem na parte de baixo direita


-- EXERCÍCIO: Gerar diagrama ER de tabelas relevantes para responder as perguntas elencadas na aula passada
--    salvar como PNG e postar no tópico do grupo


-- Atalhos
--    >Crtl + Shift + d -> Busca por objetos, tal como Crtl + Shift + t no Eclipse, para tabelas
--    >Crtl + d -> deletar a linha atual ou selecionadas, no editor de texto
--    >Crtl + / -> comentar a linha atual ou selecionadas, no editor de texto


-- Formatação dos dados
--    é possível ajustar como os dados são apresentados na view de dados
--    >window > Preferences > data formats > type: numbers > Use grouping 
--       em versões antigas, Use grouping vinha ativo por default


-- Projetos
--    o DBeaver permite o gerenciamento de projetos
--    basicamente um apanhado de conexões, diagramas, Scripts, bem como pastas que porventura estejam no diretório do projeto
--    para criar >Crtl + N > preencher nome e ajustar o caminho do projeto
--    as pastas criadas no diretório do projeto são apresentadas na visão Projects do DBeaver
--    útil para separar artefatos e conexões que tenham relação com um projeto real dos demais


-- EXERCÍCIO: Criar um projeto e copiar as conexões criadas para ele(Selecionar as conexões > Crtl + c > Crtl + v no destino)


-- Ajuste de memória do DBeaver
--    o DBeaver é uma aplicação que roda na JVM e usa parâmetros de inicialização que especificam a memória que irá utilizar
--    essas configurações ficam em /usr/share/dbeaver/dbeaver.ini
--    na minha máquina eu uso com memória limit 1GB -> -Xmx1024m


-- Ajuste de conexão por script
--    por default o DBeaver vem configurado para usar a mesma conexão para scripts distintos(que apontem para a mesma definição de conexão)
--    as vezes é necessário executar mais de uma operação ao mesmo tempo, portanto é útil poder abrir 2 scripts, cada qual com sua conexão
--    essa configuração pode ser alterada em Window > Preferences > general > Editors > sql Editor > open separate connection for each editor