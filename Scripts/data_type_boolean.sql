-- operadores

select 
-- and
true and false,
-- or
't' or 'f',
'y' and 'n',
'yes' and 'no',
'on' and 'off',
'1' or '0';

-- null
with all_values as (select * from (values (true), (false), (null)) as t(v)) 
select a.v as a, b.v as b,
a.v and b.v as "a and b",
a.v or b.v as "a or b"
from all_values a, all_values b
order by a.v desc, b.v desc;