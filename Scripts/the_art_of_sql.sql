begin;

    create table oi (id int);
    insert into oi select * from generate_series(1, 100000) as t;
    analyze oi;
    select reltoastrelid from pg_catalog.pg_class where relname = 'oi';
    -- 24 de overhead de tupla(header, null bitmap) + 4 byte int
    select pg_column_size(oi.*) from oi;
    
    
    
    create table oi2 (id int, nome text, idade bigint, dt_nascimento timestamp);
    insert into oi2 select i, repeat('a', (i * 0.001)::integer), i * 10, now() from generate_series(1, 100000) as t(i);
    analyze oi2;
    select reltoastrelid from pg_catalog.pg_class where relname = 'oi2';
    
    select pg_column_size(oi2.*) from oi2;
    
    
    explain analyze select id from oi;
    explain analyze select id from oi2;
    
rollback;



begin;

    create temporary table oi (id int, id_status int, status text);
    
    insert into oi 
        select i, 
        (array[1, 2, 3])[n],
        (array['ativo', 'cancelado', 'cadastrado'])[n]
        from (select i, random() * 2 + 1 as n from generate_series(1, 100000) as t(i)) t(i, n);
            
    analyze oi;
    
    savepoint hehe;
    rollback to hehe;
    
    select * from oi;
    
    explain
    select * from oi where id = 1 and status = 'ativo';
    
    select pg_relation_size('oi');
    
    -- refactoring
    
    create temporary table oi2 as select id, id_status from oi;
    
    create temporary table oi2_status as select distinct id_status, status from oi;
    alter table oi2_status add constraint oi2_status_id_status_pk primary key (id_status);
    
    alter table oi2 add constraint oi2_id_status_fk foreign key (id_status) references oi2_status(id_status);
    
    analyze oi2;
    analyze oi2_status;
    
    explain
    select * from oi2 inner join oi2_status using (id_status) where id = 1 and status = 'ativo';
       
    
rollback;



begin;

    create temporary table oi (id int);
    insert into oi select * from generate_series(100, 200000);
    analyze oi;
    explain
    select * from oi where id < 50;
    
    alter table oi add constraint oi_check_id_gte_100 check (id >= 100);
    
    explain
    select * from oi where id < 50;
    
    set constraint_exclusion to on;
    
    explain
    select * from oi where id < 50;
    
    -- Turning it on for all tables imposes extra planning overhead that is quite noticeable on simple queries, 
    -- and most often will yield no benefit for simple queries.
    
rollback;

-- let's fool postgresql think that the table has duplicates

begin;

    create temporary table a (id int);
    
    insert into a select (random() * 10)::integer from generate_series(1, 1000);
    
    analyze a;
    
    -- it thinks there are multiple rows for id = 3
    explain 
    select * from a where id = 3;
    
    -- lets remove duplicates
    delete from a
    where ctid not in (select max(ctid) from a group by id);
    
    -- no more duplicates
    select * from a order by id asc;
    
    -- it still thinks there are multiple rows
    explain 
    select * from a where id = 3;
    
    -- analyze
    analyze a;
    
    -- now postgresql know there aren't duplicates
    explain 
    select * from a where id = 3;
    
rollback;

-- unique
begin;

    create temporary table a (id int);
    
    insert into a select * from generate_series(1, 1000);
    
    -- it thinks there are multiple rows for id = 3
    explain 
    select * from a where id = 3;
    
    alter table a add constraint a_id_unique unique (id);

    -- now there is an index
    explain 
    select * from a where id = 3;
rollback;
    
    


        
        
        
        
        
        
        
        
        
        
        
        
        
        
    