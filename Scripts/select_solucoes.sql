-- 1.
select current_date + i, 
case when extract(dow from current_date + i) in (0, 6) then 'Fim de semana'
	 else 'Dia da semana' end
from generate_series(1, 30) as t(i);

-- ou
select d, 
case when extract(dow from d) in (0, 6) then 'Fim de semana'
     else 'Dia da semana' end
from generate_series(current_date + '1 day'::interval, now() + 30 * '1 day'::interval, '1 day') as t(d);



-- 2.
with pessoa(nome, email) as (values
	('fulano', 'fulano@gmail.com'),
	(null, 'sicrano@gmail.com'),
	('beltrano', null)
)
select nome, email, coalesce(nome, email)
from pessoa;


-- 3.
-- simplesmente converter causa exceção, pois NULO não tem correspondente inteiro
select i, i::integer
from (values ('1'), ('2'), ('NULO'), ('4'), ('5')) as tabela(i);

select i, nullif(i, 'NULO')::integer
from (values ('1'), ('2'), ('NULO'), ('4'), ('5')) as tabela(i);

select i, case i when 'NULO' then null else i::integer end 
from (values ('1'), ('2'), ('NULO'), ('4'), ('5')) as tabela(i);