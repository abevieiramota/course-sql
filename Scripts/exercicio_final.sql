-- 1. Desenvolva sql que retorne a porcentagem de tuplas retornadas em relação ao total de tuplas retornadas e lidas do banco, para o banco curso_sql
--       essas informações podem ser encontradas em pg_catalog.pg_stat_database
--       tuplas retornadas -> tup_returned
--       tuplas lidas -> tup_fetched
--       nome do banco -> datname
--       essa proporção deverá ser formatada como os exemplos(teste eles!)
--       0.73123 -> 73.12%
--       0.54900 -> 54.90%
--       0.03109 -> 3.10% (não deve resultar em 3.11%, o valor deverá ser TRUNCADO até a segunda casa decimal; não há 0 antes do 3)
--       https://www.postgresql.org/docs/9.2/static/monitoring-stats.html#PG-STAT-DATABASE-VIEW



-- 2. Desenvolva sql que retorne índices que nunca foram utilizados, dentre as tabelas acessíveis pelo usuário da conexão, ordenado pelo espaço ocupado, decrescente
--       informar o nome da tabela, nome do índice e o espaço ocupado por cada índice
--       nome da tabela -> relid::regclass
--       nome do índice -> relindex::regclass
--       espaço ocupado -> https://www.postgresql.org/docs/9.4/static/functions-admin.html#FUNCTIONS-ADMIN-DBOBJECT
--          formatar o resultado com pg_size_pretty
--       informações de índices de tabelas acessíveis pelo usuário -> pg_stat_user_indexes
--       quantidade de usos do index -> idx_scan



-- 3. Desenvolver sql que retorne o espaço ocupado total de todos os índices não utilizados(ver questão 2)
--       também formatar com pg_size_pretty



-- 4. Desenvolver sql que retorne, para cada tabela acessível pelo usuário da conexão, a quantidade de índices e o espaço total ocupado por eles,
--       ordenado pela quantidade, decrescente
--       ver exercício 2.




