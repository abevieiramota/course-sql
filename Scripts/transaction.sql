-- por default, comandos enviados fora de uma transação são encapsulados numa transação

-- begin, savepoint, rollback to, rollback

begin;

    create table a as select * from generate_series(1, 10) t(i);
    
    -- savepoints consomem recursos do banco
    savepoint ponto_1;
    
    insert into a values (100), (1000);
    
    select * from a;
    
    rollback to ponto_1;
    
    select * from a;
    
    insert into a values (200), (2000);
    
    savepoint ponto_2;
    
    select * from a;
    
    rollback to ponto_1;
    
    select * from a;
    
    -- erro > rollback to ponto_1 libera tudo que foi feito entre o savepoint e o momento do rollback
    rollback to ponto_2;
    
rollback;