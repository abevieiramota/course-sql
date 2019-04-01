begin;

    -- cria uma sequence > gerador de números únicos e incrementais
    create sequence nome_da_sequence;

    -- last_value -> ultimo valor utilizado, ou min_value se nunca foi utilizado
    -- nextval -> retorna last_value + 1, se já utilizado, min_value caso contrário
    select * from nome_da_sequence;
    
    create table nome_da_tabela (
        -- coluna textual
        -- com constraint not null
        coluna_1 text not null,
        -- coluna integer
        -- com defaults = sequence
        -- com constraint primary key -> unique E not null
        -- unique permite ter mais de um NULL
        -- apenas uma coluna pode ser primary key
        -- o PostgreSQL automaticamente cria um índice para a coluna
        id integer default nextval('nome_da_sequence') primary key,
        -- coluna smallint
        -- com valor default = 10
        -- com constraint check 
        coluna_3 smallint default 10 constraint checa_coluna_3 check (coluna_3 > 2),
        -- coluna interval
        -- com valor default now() - '1989-11-29'
        -- com constraint unique
        -- default now() -> colunas com semântica 'created_at'
        --                  -> pode ser preenchida manualmente -> se o usuário não pode ter controle, created_at deve ser feito com trigger
        --               -> colunas com semântica 'updated_at' -> necessário trigger
        coluna_4 interval default now() - '1989-11-29'::date unique,
        -- coluna timestamp
        -- sem valor default
        -- sem constraints
        coluna_5 timestamp,
        -- table check constraints
        -- constraints que podem ser aplicadas a mais de uma coluna
        -- constraint check que verifica se coluna_3 + id < 100
        constraint table_check check (coluna_3 + id < 100),
        -- constraint unique para as colunas (coluna_3, id)
        constraint table_unique unique (coluna_3, id) 
    );
    
    insert into nome_da_tabela 
    values 
    ('oi', 10, 12, '1 day', now()), 
    -- aqui faço uso de uma palavra reservada para informar
    --    ao PostgreSQL que quero preencher a coluna com seu valor default
    -- se a coluna não tem valor default explícito, ela será preenchida com NULL
    ('hola', DEFAULT, DEFAULT, DEFAULT, DEFAULT);
   
    select * from nome_da_tabela;
   
    -- salva ponto na transação
    savepoint point1;
   
    -- exemplo de erro de constraint
    --    aqui a coluna_3 tem um valor inválido, é menor ou igual a 2
    insert into nome_da_tabela values ('oi', 10, 1, '1 minute', now());
   
    -- volta para point1
    rollback to point1;
   
    -- aqui criamos outra tabela, para trabalhar constraints de relacionamento
    create table relacionada (
        -- coluna do tipo serial
        --    por baixo dos panos é uma coluna integer not null
        --    o PostgreSQL cria uma sequence e seta o default da coluna pro nextval da sequence
        -- outros: smallserial, bigserial
        -- o nome da sequence fica <nome_da_tabela>_<nome_da_coluna>_seq
        id serial primary key,
        -- coluna integer
        -- faz referência a um registro em nome_da_tabela
        -- pode ser resumido em references nome_da_tabela -> ira referenciar a PK
        nome_da_tabela_id integer references nome_da_tabela(id),
        nome_da_tabela_coluna_3 integer,
        -- defino uma constraint foreign key que é composição de colunas
        foreign key (nome_da_tabela_id, nome_da_tabela_coluna_3) references nome_da_tabela (id, coluna_3)
    );
   
    savepoint point2;
   
    -- adicionando registro inválido
    -- a combinação (nome_da_tabela_id, nome_da_tabela_coluna_3) = (1, 12)
    --    não pertence à tabela relacionada
    insert into relacionada values (default, 1, 12);
   
    rollback to point2;
   
    -- adicionando registro válido
    insert into relacionada values (default, 1, 10);
   
    select * from relacionada;
   
    savepoint point3;
   
    -- delete interrompido pois a row é referenciada
    delete from nome_da_tabela where id = 1;
   
    rollback to point3;
   
    drop table relacionada;
   
    -- agora iremos configurar o relacionamento
    --    de forma tal que um delete em uma row referenciada
    --    causa um delete em todas as rows que a referenciam
    create table fk (
        id serial primary key,
        -- quando a row referenciada for deletada, a row referenciadora deve ser deletada(cascade de delete)
        -- outras restrições > RESTRICT/NO ACTION bloqueia comando, SET DEFAULT/SET NULL alteram o valor da coluna
        -- > impacto em delete na referenciada > necessário scan na referenciadora para aplicar operação do on
        --    ou seja quando eu for deletar um registro de uma tabela
        --    eu preciso procurar, em todas as tabelas referenciadoras, se esse registro está sendo referenciado
        --    essa busca pode ser lenta se não houver índice sobre essa coluna
        --    foreign key não possui índice por padrão!
        nome_da_tabela_id integer references nome_da_tabela(id) on delete cascade
    );
   
    insert into fk values (default, 1);
   
    savepoint point4;
   
    delete from nome_da_tabela where id = 1;
   
    select * from fk;

    -- ex dropa tabela
    drop table fk;
    drop table nome_da_tabela;
    -- ex dropa sequence
    drop sequence nome_da_sequence;
    
rollback;


-- create table as
--    permite a criação de tabelas com os dados retornados por uma consulta
begin;

    create table minha_tabela as 
    select * from pg_catalog.pg_settings;
    
    select * from minha_tabela;
    
rollback;



-- tabela sem campo unique e valores duplicados
begin;

    -- temporary table -> por default dura até o fim da sessão
    create temporary table oi (numero int, nome text) on commit drop;
    
    insert into oi values (1, 'oi'), (1, 'oi'), (2, 'hehe');
    
    select * from oi;
    
    -- como remover duplicatas?!
    
    -- observar o ctid da row de numero = 2
    -- usar ctid, um identificador interno de row
    select ctid, * from oi;
    
    update oi set nome = 'hoho' where numero = 2;
    
    -- observar o novo ctid da row de numero = 2
    select ctid, * from oi;
    
    delete from oi 
    where ctid not in (select max(ctid) from oi group by numero);
    
    select ctid, * from oi;
    
 rollback;


 
-- EXERCÍCIO

-- OBS: executar dentro de uma transação e depois dar rollback

-- 1. Desenvolver sql que crie uma tabela com seu nome(usar aspas duplas) e que armazene os dados da pg_stat_user_tables
--       criar a tabela com "create temporary table"
--       execute um select * em alguma das tabelas listadas
--       teste então o sql(coloque o nome da tabela que criou)

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
		

-- 2. Desenvolver sql que crie tabela para armazenar as seguintes informações de venda de um produto(utilizar o próprio nome como nome da tabela)
--       nome -> texto com no máximo 200 caracteres; informação necessária e de tamanho no mínimo 3
--       preço -> valor em moeda real, no máximo 100000.00 reais, necessário contar os centavos; informação necessária
--       momento de compra -> data e horário em que o produto foi comprado; informação necessária
--       quanto tempo sem vender -> quanto tempo se passou desde a última vez em que o produto foi vendido; informação pode ser nula
--       código de venda -> identificador único de uma venda de um produto, em formato inteiro; pode assumir valores até 10.000.000


		
-- 3. Pesquisar na documentação o que significa o "on commit drop" ao fim da definição de uma temporary table 
--    https://www.postgresql.org/docs/9.2/static/sql-createtable.html