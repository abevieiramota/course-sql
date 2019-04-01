-- 1.

-- salva statistics de uso de tabelas
create temporary table "Abelardo Vieira Mota" as  
select * from pg_catalog.pg_stat_user_tables;

-- SQL qualquer
select * from tmdb.movie;

-- verifica que mudanças houve
select 
n.schemaname, n.relname, 
t.seq_scan - n.seq_scan as seq_scan, 
t.idx_scan - n.idx_scan as idx_scan, 
t.n_tup_ins - n.n_tup_ins as tup_ins, 
t.n_tup_upd - n.n_tup_upd as tup_upd, 
t.n_tup_del - n.n_tup_del as tup_del
from pg_catalog.pg_stat_user_tables t 
inner join "Abelardo Vieira Mota" n on n.relid = t.relid
	and (n.seq_scan, n.idx_scan, n.n_tup_ins, n.n_tup_upd, n.n_tup_del) <>
		(t.seq_scan, t.idx_scan, t.n_tup_ins, t.n_tup_upd, t.n_tup_del);
		

-- 2. Desenvolver sql que crie tabela para armazenar as seguintes informações de venda de um produto
--       nome -> texto com no máximo 200 caracteres; informação necessária e de tamanho no mínimo 3
--       preço -> valor em moeda real, no máximo 100000 reais, necessário contar os centavos; informação necessária
--       momento de compra -> data e horário em que o produto foi comprado; informação necessária
--       quanto tempo sem vender -> quanto tempo se passou desde a última vez em que o produto foi vendido; informação pode ser nula
--       código de venda -> identificador único de uma venda de um produto, em formato inteiro; pode assumir valores até 10.000.000

begin;
	create table "Abelardo Vieira Mota" 
	(
		nome varchar(200) not null check(length(nome) >= 3),
		preco numeric(8, 2) not null check(preco <= 100000),
		momento timestamp not null,
		tempo_sem_vender interval null,
		codigo integer primary key
	);
	
	-- exemplo correto
	insert into "Abelardo Vieira Mota" values ('produto', 123.23, now(), '1 hour'::interval, 123);
	select * from "Abelardo Vieira Mota";
	-- sem nome
	insert into "Abelardo Vieira Mota" values (null, 123.23, now(), '1 hour'::interval, 123);
	-- nome < 3
	insert into "Abelardo Vieira Mota" values ('oi', 123.23, now(), '1 hour'::interval, 123);
	-- preço null 
	insert into "Abelardo Vieira Mota" values ('produto', null, now(), '1 hour'::interval, 123);
	-- momento null
	insert into "Abelardo Vieira Mota" values ('produto', 123.23, null, '1 hour'::interval, 123);
	-- codigo null
	insert into "Abelardo Vieira Mota" values ('produto', 123.23, now(), '1 hour'::interval, null);
	
rollback;



-- 3. 
--    no commit da transação, a tabela será dropada, diferentemente do default que seria ela sobreviver até o fim da sessão