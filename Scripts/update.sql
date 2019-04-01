create temporary table x (id int, nome text, idade int);

insert into x values (1, 'oi', 22);

update x
-- quase isso
set (nome, idade) = case id when 1 then ('hihihi', 35) else (nome, idade) end
where id = 1;

select case id when 1 then ('hihihi', 35) else (nome, idade) end from x;