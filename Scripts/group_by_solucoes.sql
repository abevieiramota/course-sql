-- 1.

select column_name, 
array_agg(format('%s.%s', table_schema, table_name)),
array_agg((table_schema, table_name))
from information_schema.columns
WHERE table_schema not in ('information_schema', 'pg_catalog')
group by 1
having count(*) > 1
