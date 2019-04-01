-- 1.
begin;
    create temporary table unidade (id int primary key, id_superunidade int references unidade(id), nome text);
    insert into unidade values 
        (1, null, 'UFC'),
        (2, 1, 'STI'),
        (3, 2, 'DSI'),
        (4, 2, 'DRC'),
        (5, 2, 'DPU'),
        (6, 2, 'DAD'),
        (7, 1, 'PROGRAD'),
        (8, 7, 'COPIC'),
        (9, 7, 'COPAC'),
        (10, 9, 'COPAC.1');
        
    select * from unidade;
    
    -- incluindo a pai
    with recursive unidades as (
        select *, 0 as nivel
        from unidade
        -- parte do pai
        where id = 2
        
        union 
        
        select u.*, us.nivel + 1 as nivel
        from unidade u 
        inner join unidades us on us.id = u.id_superunidade
    )
    select *
    from unidades;
    
    -- não incluindo a pai
    with recursive unidades as (
        select *, 1 as nivel
        from unidade
        -- parte dos filhos
        where id_superunidade = 7
        
        union 
        
        select u.*, us.nivel + 1 as nivel
        from unidade u 
        inner join unidades us on us.id = u.id_superunidade
    )
    select *
    from unidades;

rollback;



-- 2.
begin;
    
    create temporary table a as select id from generate_series(1, 10000) as t(id);
    create temporary table b (id int check (id % 2 = 0));
    create temporary table c (id int check (id % 2 = 1));
    
    with deletados as (
        delete from a 
        returning *
    ), insere_em_b as (
        insert into b 
        select *
        from deletados 
        where id % 2 = 0
    )
    insert into c 
    select *
    from deletados
    where id % 2 = 1;
    
    select * from a;
    select * from b;
    select * from c;
    
rollback;



-- 3.
begin;

    create temporary table a (id int, nome text);
    create temporary table b (id int, nome_antigo text, nome_novo text);
    
    insert into a values 
        (1, 'Curso de sql'),
        (2, 'DSI/STI'),
        (3, 'Fluent Python');
        
    with atualizados as (
        update a 
        set nome = format('%s %s', nome, id)
        returning *
    )
    insert into b 
    select a.id, a.nome, atu.nome
    from a 
    inner join atualizados atu on atu.id = a.id;
    
    select * from b;
    
rollback;