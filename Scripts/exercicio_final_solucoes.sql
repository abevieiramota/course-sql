-- 1.

select datname, 
to_char(trunc(tup_returned*100.0 / (tup_fetched + tup_returned), 2), '90.00%') as pct_tup_returned 
from pg_stat_database
where datname not like 'template%';

select to_char(trunc(0.73123 * 100, 2), '90.00%');
select to_char(trunc(0.54900 * 100, 2), '90.00%');
select to_char(trunc(0.03109 * 100, 2), '90.00%');



-- 2.
SELECT 
    relid::regclass AS table, 
    indexrelid::regclass AS index, 
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size 
FROM 
    pg_stat_user_indexes 
WHERE 
    idx_scan = 0 
order by pg_relation_size(indexrelid::regclass) desc;



-- 3.
SELECT pg_size_pretty(sum(pg_relation_size(indexrelid::regclass))) AS index_size 
FROM 
    pg_stat_user_indexes 
WHERE 
    idx_scan = 0;
    
    
    
-- 4.
select relid::regclass as table, count(*), pg_size_pretty(sum(pg_relation_size(indexrelid::regclass)))
from pg_stat_user_indexes
group by 1
order by count(*) desc;



-- 5.

analyze log_operacao;