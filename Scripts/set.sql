-- union 

--    por default as operações de set removem duplicatas
--    necessário adicionar ALL para não ter esse comportamento
--    > mais custosas que com ALL, por ter essa operação adicional

explain
values (1), (2) 

union 

values (1), (10);


explain
values (1), (2) 

union all

values (1), (10);


-- devem ter mesmo número de colunas e tipos(integer + numeric, date + timestamp OK)
--    erro
values (1)

union 

values ('oi');



-- intersection

values (1), (1), (2) 

intersect

values (1), (10);



-- except

values (1), (2)

except

values (1), (10);



-- order by se aplica ao resultado da operação!

values (1), (2)

union all

values (1), (10)

-- coluna deve pertencer a cada conjunto
order by 1 asc;