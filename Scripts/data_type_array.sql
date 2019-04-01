-- https://www.postgresql.org/docs/9.1/static/functions-array.html


-- teste de interseção
SELECT x, 
array_agg(y) && array['B', 'C'],
sum(case when y in ('B', 'C') then 1 else 0 end) > 0
from (values (1, 'A'), (1, 'B'), (2, 'A')) as t(x, y)
group by x;