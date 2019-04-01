-- insert

begin;

	create temporary table a (id serial, nome text);
	
	-- especificada apenas um subconjunto das colunas
	--    as demais recebem o valor default
	insert into a (nome) 
	values
		-- múltiplas rows
		('oi'), 
		('tudo bem?');
	
	select * from a;

	-- se não especificadas as colunas e a quantidade de valores é menor que a quantidade de colunas
	--    irá tentar preencher as primeiras colunas
	insert into a 
	values (1000);

	select * from a;
	
	-- default values
	--    todas as colunas recebem os mesmos valores
	insert into a 
	default values;
	
	select * from a;
	
	-- é possível especificar que uma determinada coluna receba seu valor default
	--    default
	insert into a (id, nome)
	values (default, 'usei default');
	
	select * from a;
	

	-- insert a partir de consulta
	insert into a (nome)
	--    consulta
	select substring('abcdefghijklmnopqrstuvwxyz', floor(random() * 5 + 1)::int, floor(random() * 5 + 1)::int + 5)
	from generate_series(1, 10);

	select * from a;

	
	-- com with
	with valores as (
		select substring('abcdefghijklmnopqrstuvwxyz', floor(random() * 5 + 1)::int, floor(random() * 5 + 1)::int + 5)
		from generate_series(1, 10)
	)
	insert into a (nome)
	select *
	from valores;

	-- returning
	--    possível retornar os valores, ou parte deles, ou expressões, dos valores que foram inseridos
	insert into a (nome)
	select substring('abcdefghijklmnopqrstuvwxyz', floor(random() * 5 + 1)::int, floor(random() * 5 + 1)::int + 5)
	from generate_series(1, 10)
	returning id, format('O nome inserido foi: %s', nome);
	
rollback;




-- update

begin;

	create temporary table a (id serial, nome text, data timestamp);
	
	insert into a (nome, data) 
	select substring('abcdefghijklmnopqrstuvwxyz', floor(random() * 5 + 1)::int, floor(random() * 5 + 1)::int + 5),
	now() + random() * '1 minute'::interval
	from generate_series(1, 100);
	
	select * from a;
	

	-- update com filtro 
	--    colunas não especificadas mantém seus valores
	update a 
	set nome = 'Curso de SQL'
	where id = 3;
	
	select * from a order by id asc;
	
	
	-- update em mais de uma coluna ao mesmo tempo 
	update a 
	set nome = 'DSI/STI', data = now() + '1 day'::interval 
	where id = 1;
	
	select * from a order by id asc;
	
	
	-- update para valor default 
	update a 
	set nome = default 
	where id = 2;
	
	select * from a order by id asc;

	
	-- update usando valores antigos
	update a 
	set nome = format('O nome antigo era %s', nome)
	where id = 5;

	select * from a order by id;
	
	
	-- update com returning 
	--    retorna os valores atualizados
	update a 
	set nome = 'STI', data = now() + random() * '1 day'::interval
	where id = 4
	returning *;
	
	
	-- update condicional
	--    coluna = case when...
	update a 
	set nome = case when id % 2 = 1 then format('%s múltiplo de 2', nome) else nome end;
	
	select * from a;
	
	
	-- update from 
	--    as vezes ou o critério de update ou os novos valores dependem de outras tabelas
	-- UPDATE <tabela>
	-- SET <coluna> = <expressao>...
	-- FROM <outra tabela>
	--    o join com a primeira tabela é feito no where
	
	create temporary table b (id int, nome text);

	insert into b values (2, '>>>><<<<'), (3, '###########');

	--    quero atualizar a com os valores correspondentes em b
	update a 
	set nome = b.nome 
	-- é a mesma ideia de um
	--    select *
	--    from a, b
	-- é necessário especificar como será o match das linhas em a e b
	--    isso deve ser feito no where
	from b 
	where b.id = a.id;

	select * from a order by id asc;

	-- e se o join fizer com que uma row de a se junto a duas rows de b?
	--    apenas uma delas será utilizada para atualizar a
	--    qual delas, não é definido
	
	-- qual a vantagem?
	--    mais rápido que subselect, quando as demais tabelas servirem apenas para definir quem será atualizado
	--    mais fácil de ler, qnd acostumado
	
rollback;



-- delete 

begin;

	create temporary table a (id int);

	insert into a select * from generate_series(1, 1000);
	analyze a;

	select * from a order by id asc;

	
	-- delete com filtro
	delete from a 
	where id between 2 and 7;

	select * from a order by id;

	-- e se eu precisar de informações em outras tabelas?
	--    da mesma forma que com o update, há como especificar outras tabelas, como se fosse um join
	
	create temporary table b as select i from (values (444)) as t(i);

	-- DELETE FROM <tabela>
	-- USING <outras tabelas, join etc>
	--    o join com a primeira tabela é via where
	delete from a 
	using b 
	where a.id = b.i
	-- e posso retornar 
	returning *;

	select * from a where id = 444;

	-- outra forma é com subselect
	--    o mesmo pode ser feito com update
	
	delete from a 
	where id in (select i from b);


	-- da mesma forma, performance é menor

	-- sem where > deleta todos os registros
	delete from a;
	
	select * from a;

rollback;


-- custo do delete

begin;

    -- tabela só tem o valor 1
    create temporary table a as select 1 as i from generate_series(1, (10^7)::int);
    -- tamanho de a
    select pg_size_pretty(pg_relation_size('a'));
    analyze a;
    
    create temporary table b (i int primary key);
    insert into b values (1), (2), (3), (4), (5);
    
    -- adiciona chave de A para B
    alter table a add constraint i_b_i_fk foreign key (i) references b(i);
    
    -- quanto tempo leva para deletar um registro em b?
    --    é necessário verificar se há alguém referenciando o registro a ser deletado
    --    teste com registro que não é apontado por a
    --    900ms
    explain analyze 
    delete from b 
    where i = 2;
    
    -- e se adicionarmos um índice em a?
    create index a_i_idx on a(i);
    -- tamanho do index
    select pg_size_pretty(pg_relation_size('a_i_idx'));
    
    -- 0.482ms
    explain analyze 
    delete from b 
    where i = 4;
    
    
rollback;



-- Exercício
-- 1. Criem uma tabela temporária com os dados em tmdb.movie 
--       atualizem o title dos registros nessa tabela temporária
--       novo title = O título é "<title antigo>" e seus gêneros são [<gêneros separados por ,>]
--       por exemplo
--          Batman -> com os gêneros {action, comedy}
--          O título é Batman e seus gêneros são [action, comedy]