-- 1.

select 
name, sum(weight) over(order by name) as running_total_weight
from cats 
order by name;


-- 2.

select 
name, breed, sum(weight) over(partition by breed order by name asc) as running_total_weight
from cats 
order by breed, name;


-- 3.

select 
row_number() over(order by color, name) as unique_number,
name, color
from cats 
order by color, name;


-- 4.

select 
name, 
weight, weight - lag(weight, 1, weight) over(order by weight) as weight_to_lose
from cats 
order by weight;