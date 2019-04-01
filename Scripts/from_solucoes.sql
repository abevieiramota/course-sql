-- 1.

-- observar que os subselects em movie e em genre continuam retornando a coluna id, ambos
--    que será utilizada no natural join, fazendo movie.id = genre.id


-- 2.
-- com left
--explain
select *
from (values (1), (2), (3)) as A(i)
left join (values (2, 'a'), (3, 'b'), (4, 'c')) as B(i, j) on B.i = A.i;

-- com full outer -> exclui A.i null
--explain
select *
from (values (1), (2), (3)) as A(i)
full outer join (values (2, 'a'), (3, 'b'), (4, 'c')) as B(i, j) on B.i = A.i
where A.i is not null;

-- inner join + onde B.i null
select *
from (values (1), (2), (3)) as A(i)
inner join (values (2, 'a'), (3, 'b'), (4, 'c')) as B(i, j) on B.i = A.i

union 

select *
from (values (1), (2), (3)) as A(i)
full outer join (values (2, 'a'), (3, 'b'), (4, 'c')) as B(i, j) on B.i = A.i
where B.i is null;


-- 3.

-- em versões 9.5+
select i 
from generate_series(0., 100., 2.5) as t(i);

-- nossa versão aceita apenas inteiro
select i * 2.5
from generate_series(0, (100/2.5)::integer) as t(i);