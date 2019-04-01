-- char, varchar, text

-- char -> adicionado de caracteres vazios à direita
-- varchar -> ocupa apenas o necessário, até o limite
-- text -> ocupa o que for necessário, sem limite(limitado à instalação)
-- sem diferença de performance
--    > a menos da checagem de tamanho pros tipos char/varchar(n), que não há com o tipo text

begin;
	create table oi (a varchar(100), b char(100));
	insert into oi values ('aa', 'aa'), ('aaaaaaaaa', 'aaaaaaaaa');
	select a, b, octet_length(a) as byte_len_a, octet_length(b) as byte_len_b from oi;
rollback;


-- concatenação 
-- o operador de concatenção entre strings é o ||
select 'curso ' || 'de' || ' SQL';

-- pode concatenar com valores não text
select 'curso ' || 10;

-- formatação de valor não text segue um padrão
--    observar que a data não é formatada do jeito que foi definida(dd/mm/yyyy)
select 'curso  ' || d 
from (values 
	('2018-08-10 10:00:01'::timestamp),
	-- ver que não é formatado tal qual foi definido
	('01/01/2011'::timestamp)
) as t(d);

-- funções
select 
-- valor
s,
-- tamanho da string -> mesma função
char_length(s), length(s), character_length(s)
from (values ('Curso de sql')) as t(s);

select
s,
-- to lower case
lower(s),
-- to upper case
upper(s)
from (values ('Curso de sql')) as t(s);


select
s,
-- substitui a partir da posição 2, consumindo 2 caracteres('ur') por '123456'
--    o index de caracteres na string começa em 1
overlay(s placing '123456' from 2 for 2) as overlay1,
-- substitui a partir da posição 6, consumindo 0(apenas insere) caracteres('') por '123456'
overlay(s placing '123456' from 6 for 0) as overlay2,
-- funções que retornam
--    a posição do primeiro caractere da substring na string
--    mesmas funções
-- qual a posição de sql na string?
position('sql' in s), strpos(s, 'sql')
from (values ('Curso de sql')) as t(s);

select
-- substring 
--    necessário informar o caractere inicial e o tamanho
substring(s from 2 for 2) as substring_com_pos,
-- btrim = trim dos dois lados
--    remove espaços nos dois extremos da string
'"'||btrim('    oi    ')||'"' as btrim,
-- ltrim
--    trim na esquerda -> left trim
--    nas funções de trim é possível especificar qual caractere remover
--    no exemplo, estão sendo removidos, da esquerda, os caracteres -
ltrim('---oi---', '-'),
-- rtrim 
--    trim na direita -> right trim
--    é possível especificar mais de um caractere para aplicar trim 
--    no exemplo são removidos tanto o * quanto o @
rtrim('***oi**@*', '*@')
from (values ('Curso de sql')) as t(s);

select
-- concat
--    função de concatenação
--    diferente do operador || -> concat ignora null
--    o operador || retorna NULL caso algum dos operandos seja NULL
concat(s, null, ' hehe') as concat1, s ||null||' hehe' as concat2,
-- concat_ws
--    concatenção com separador entre as strings
--    parâmetros: separador, string1, string2, string3, ...
concat_ws(' ', s, 'é', 'muito', 'bom'),
-- format
--    formatação 
--    %s -> vai consumindo da lista de parâmetros, na ordem
--    %posição$s -> acessa por posição os parâmetros
format('primeiro param=[%s] segundo param=[%s]', s, 10, 123),
format('primeiro param=[%2$s] segundo param=[%3$s]', s, 10, 123)
from (values ('Curso de sql')) as t(s);


select
-- initcap
--    camelcase
initcap(s),
-- left
--    retorna os primeiros 9 caracteres
left(s, 9) as left9,
-- left com negativo
--    retorna todos menos os 9 últimos caracteres
left(s, -9) as leftm9,
-- right
--    retorna os últimos 9 caracteres
right(s, 9),
-- right com negativo
--    retorna todos menos os 9 primeiros caracteres
right(s, -9),
-- padding
-- lpad
--    adiciona caractere à esquerda até o tamanho 20
lpad(s, 20, '*'),
-- rpad
--    adiciona caracteres à direita até o tamanho 20
--    possível informar string
--    no exemplo, informado #@
rpad(s, 20, '*@')
from (values ('Curso de sql')) as t(s);


select
-- repeat
--    repete uma string n vezes
repeat(s, 2),
-- replace
--    substitui todas as ocorrências
--    string base, string a remover, string a ser colocada
replace('teste teste', 'es', 'os'),
-- reverse
--    inverte a string
reverse(s),
-- split_part
--    separa a string usando o separador informado
--    retorna a n-ésima parte
--    split_part(string, separador, n)
--    no exemplo, separa a string usando o separador 'oi'
--       e retorna a 2ª parte
split_part('1oi2oi3oi4oi5oi6', 'oi', 2),
-- translate
--    substitui caracteres usando uma tabela
--    no exemplo:
--       e -> *, o -> &, u -> $
translate(s, 'eou', '*&$')
from (values ('Curso de sql')) as t(s);


-- pattern matching
-- existem 3 operadores para pattern matching no PostgreSQL
--    LIKE
--    SIMILAR TO
--    ~
-- https://www.postgresql.org/docs/9.3/static/functions-matching.html#FUNCTIONS-POSIX-REGEXP


-- LIKE 
--    mesma coisa de ~~
--    retorna TRUE se a string(completa) fizer parte do padrão informado
select s, 
-- % 
--    0 ou + caracteres
--    case sensitive
s like 'Universidade Federal%' as like1,
-- operador ~~
s ~~ '%Federal%' as like2,
-- _
--    1 caractere
s like '%Federal do Cear_' as like3,
-- ILIKE 
--    mesma coisa de ~~*
--    case insensitive
s ilike 'universidade federal%' as ilike1,
-- operador ~~*
s ~~* '%federal do cariri' as ilike2,
-- podem ser negados
--    !~~, !~~*, not like, not ilike
s !~~* '%federal do ceará' as ilike3
from (values ('Universidade Federal do Ceará'), ('Universidade Federal do Rio de Janeiro'), ('Universidade Federal do Cearí')) as t(s);



-- SIMILAR TO 
--    mistura de like e regex, mais poderoso que LIKE/ILIKE
--    retorna TRUE se a string(completa) fizer parte do padrão informado
select s,
-- | 
--    alternativa, ou um ou outro
--    (A|B) -> ou A ou B
s similar to 'Universidade Federal do Ceará|Universidade Federal do Cearí' as similar1,
s similar to 'Universidade Federal do Cear(á|í)' as similar2
from (values ('Universidade Federal do Ceará'), ('Universidade Federal do Rio de Janeiro'), ('Universidade Federal do Cearí')) as t(s);

select s,
-- * = 0 ou + repetições
s similar to 'Universidade Federal do Ceará*' as "á*",
-- + = 1 ou + repetições
s similar to 'Universidade Federal do Ceará+' as "á+"
from (values ('Universidade Federal do Cear'), ('Universidade Federal do Ceará')) as t(s);

select s,
-- ? = 0 ou 1 repetição
s similar to 'Universidade Federal do Ceará?' as "á?",
-- {m} = m repetições
s similar to 'Universidade Federal do Ceará{3}' as "á{3}"
from (values ('Universidade Federal do Ceará'), ('Universidade Federal do Cearááá')) as t(s);

select s,
-- {m,} = m ou mais repetições
s similar to 'Universidade Federal do Ceará{1,}' as "á{1,}",
-- {m,n} = de m a n repetições
s similar to 'Universidade Federal do Ceará{1,2}' as "á{1,2}",
-- () = grupo -> delimita a expressão
s similar to 'Universidade Federal do (Ceará|Rio de Janeiro)' as "Ceará|Rio de Janeiro",
-- [] character class
s similar to '[a-zA-Z\ ]+' as "sem acento"
from (values ('Universidade Federal do Ceará'), ('Universidade Federal do Rio de Janeiro'), ('Universidade Federal do Cearí'), ('Universidade Federal do Cearáá'), ('Universidade Federal do Cearááá')) as t(s);

-- [] character class
--    [a-z] -> caracteres de 'a' a 'z' -> depende de locale(tem ç ou não?)
--    lc_ctype é definido na criação do database e só pode ser alterado criando novamente 
--    https://www.postgresql.org/docs/9.1/static/locale.html
show lc_ctype;
--    ç não faz parte do alfabeto
select 'ç' similar to '[a-z]';
--    para adicionar -> [a-zç]
select 'ç' similar to '[a-zç]';


-- REGEX
--    mais poderoso que os operadores anteriores
select s,
-- .
--    qualquer caractere
-- ^ 
--    início da string
s ~ '^Universidade federal.*' as regex1,
-- ~* 
--    versão case insensitive
s ~* '^Universidade Federal.*' as regex2,
-- !~* 
--    negação da versão insensitive
s !~* '^Universidade Federal.*' as regex3,
-- substring
--    substring(string, regex)
--    faça o match de s com o segundo parâmetro e retorne o grupo capturado
substring(s, 'Universidade Federal do (.*)') as regex5,
-- (?=re)
--    positive lookahead
-- no exemplo, regexp_replace
--    troque todos 'ba' seguidos de um '2' por 'oi'
--    (?=2) -> tem um 2 depois
--    a flag 'g' indica que todos os grupos capturados devem ser substituídos -> default apenas o primeiro
regexp_replace(s, 'ba(?=2)', 'oi', 'g') as regex6,
-- (?!re)
--    negative lookahead 
--    troque todos 'ba' não seguidos de um '2' por um 'oi'
regexp_replace(s, 'ba(?!2)', 'oi', 'g') as regex7
-- positive/negative lookbehind -> 9.6+
from (values ('Universidade Federal do Ceará'), ('Universidade Federal do Rio de Janeiro'), ('Universidade federal do Cearí'), ('ba1ba2ba3ba2')) as t(s);

-- $
--    fim da string 
select s, regexp_matches(s, '123$')
from (values ('abc123', '123abc')) as t(s);



-- funções que usam regex
-- match -> regexp_matches
-- split -> regexp_split_to_array, regexp_split_to_table
-- replace -> regexp_replace



-- REGEXP_MATCHES
--    match de string retornando matches como array
--    por padrão, retorna apenas o primeiro match -> um array com os grupos na ordem em que estão definidos
--    no exemplo, um par de números, cada um num grupo diferentes
--    captura o primeiro, 12
select regexp_matches('ab12ab34', '(\d)(\d)');

--    pode-se informar flags 
--    https://www.postgresql.org/docs/9.4/static/functions-matching.html#POSIX-METASYNTAX
--    flag g -> retorna uma row para cada match
select regexp_matches('ab12ab34', '(\d)(\d)', 'g');
--    flag i -> case insensitive
--       ABC matches [a-z]+(lembrar de [] character class)
select regexp_matches('ABC', '[a-z]+', 'i');
--       sem a flag, não captura
select regexp_matches('ABC', '[a-z]+');
--    E'' -> \n -> caractere especial, e não 2 caracteres
select '\n';
select E'\n';
--    flag n -> newline sensitive
--    com essa flag, o símbolo . não inclui \n
select regexp_matches(E'123\n123', '.+', 'gn');
--    sem essa flag, o símbolo . inclui \n
select regexp_matches(E'123\n123', '.+', 'g');


-- NON GREEDY MATCH
--    as vezes quero pegar todos os caracteres até um determinado padrão
--    .+ -> pegue um ou mais caracteres, o máximo o possível para fazer um match
--    .+? -> pegue um ou mais caracteres, o mínimo o possível para fazer um match
select s,
regexp_matches(s, 'teste(.+)ba1') as "(.+)ba",
regexp_matches(s, 'teste(.+?)ba') as "(.+?)ba"
from (values ('testebababa1')) as t(s);

-- alguns caracteres têm significado dentro da regex
--    por exemplo o [ e o ], que definem um character class
-- caso seja necessário utilizá-los no match, deve-se escapá-los, usando a \
--    no exemplo -> capturo pontos '.'
select regexp_matches('123.123.123', '\.', 'g');
--    no exemplo -> capturo qualquer caractere 
select regexp_matches('123.123.123', '.', 'g');
--    exemplo mais complexo
select s,
regexp_matches(s, '\[a(\d)\]\=(\d)', 'g') as "\[a(\d)\]\=(\d)"
from (values ('[a1]=1;[a2]=2;[b1]=3')) as t(s);


-- REGEXP_SPLIT_TO_ARRAY
--    quebra a string em array de partes, separadas por um separador -> definido com regex
select regexp_split_to_array('a;b;c', ';');
--    posso por exemplo pegar o primeiro elemento
select (regexp_split_to_array('a;b;c', ';'))[1];
--    sendo que exemplo, que não usa regex, fica melhor com split_part

--    posso transformar o array em linhas
--    função UNNEST
--        transforma elementos de array em linhas
select s, unnest(regexp_split_to_array(s, ';')) as partes
from (values ('[a1]=1;[a2]=2;[b1]=3')) as t(s);


-- REGEXP_SPLIT_TO_TABLE
--    mesma coisa de unnest(regexp_split_to_array())
select s,
regexp_split_to_table(s, ';') as partes
from (values ('[a1]=1;[a2]=2;[b1]=3')) as t(s);
-- unnest(regexp_split_to_array())
select s,
unnest(regexp_split_to_array(s, ';')) as partes
from (values ('[a1]=1;[a2]=2;[b1]=3')) as t(s);


-- REGEXP_REPLACE
--    permite substituir substrings
select s,
-- substitua em s
--    o padrão (\d+)
--    por {x}, onde x é o que foi capturado pelo padrão
--    no exemplo, substitui as sequências de números por {sequência}
-- flag g -> para substituir todas
regexp_replace(s, '(\d+)', '{\1}', 'g'), 
-- sem flag g -> substitui apenas a primeira
regexp_replace(s, '(\d+)', '{\1}')
from (values ('abc123xyz987')) as t(s);

-- exemplo de troca de posição
--    troca as posições da primeira e segunda sequência de números
select s, 
-- capturo a substring, formada por 2 grupos de números, separados por _ (underline)
--    substituo ela pela string \2_\1, onde \n referencia o que foi capturado pelo n-ésimo grupo
regexp_replace(s, '(\d+)_(\d+)', '\2_\1')
from (values ('#123_456#')) as t(s);

-- E escape
--    por padrão, uma string não interpreta caracteres especiais
--    \n, newline, por exemplo
--    '\n' -> representa 2 caracteres
--    E'\n' -> representa um caractere, newline
-- olhar com o Panel Value o valor das colunas com o caractere especial
select 'oi\noi' as "'oi\noi'", 
E'oi\noi' as "E'oi\noi'", 
'oi\toi' as "'oi\toi'", 
E'oi\toi' as "E'oi\toi";


-- match da sequência de caracteres \n
--    sequência \n
select regexp_matches('oi\noi', '\\n');
-- match do caractere newline
--    caractere especial \n 
select regexp_matches(E'oi\noi', '\n');



-- CARACTERES ESPECIAIS
--    visualizar o valor da string no Panel Value
--    podem ser utilizados com os operadores
--       ~
--       similar to
select s,
-- \d caractere numérico 
-- \D caractere não numérico
--    captura primeira substring sequência de dígitos
regexp_matches(s, '\d+') as "\d",
-- \w caractere alfanumérico (obs: inclui underline)
-- \W caractere não alfanumérico
--    captura a primeira substring formada por alfanumérico+underline
regexp_matches(s, '\w+') as "\w",
-- \s caractere 'branco'(espaço, newline, tab)
-- \S caractere 'não branco'
--    captura sequência de caracteres 'brancos' -> adiciona caracteres visíveis nos extremos para visualizar no Panel Value
'#'||(regexp_matches(s, '\s+'))[1]||'#',
-- \m começo de uma substring -> antes dela não pode vir caractere 'não branco'
-- \M fim de uma substring
--    \ma.+ -> começo de string, iniciada por 'a' e seguida de qualquer coisa 1 ou mais vezes
--    match com akc e não com abc.. pois abc é precedido por c 
regexp_matches(s, '\ma.+')
from (values (E'cabc_123    \n       akc')) as t(s);



-- EXERCÍCIO

-- 1. Desenvolva SQL para retornar os registros da tabela candidatos_2018.bens 
--       que contenham algum número na coluna ds_bem_candidato
--       Analisar os valores dessa coluna e verificar se há algum padrão


-- 2. Desenvolva sql para retornar os registros da tabela candidatos_2018.bens
--       cuja coluna ds_bem_candidato inicie com número
--       Analisar os valores dessa coluna e verificar se há algum padrão


-- 3. Desenvolva sql para retornar todos os registros da tabela candidatos_2018.bens
--       cuja coluna ds_bem_candidatos está com todos os caracteres em upper case


-- 4. Desenvolva sql para retornar os registros da tabela candidatos_2018.bens
--       com maior texto em ds_bem_candidatos


-- 5. Desenvolva sql para retornar os registros da tabela candidatos_2018.candidatos
--       com maior texto em nm_candidato


-- 6. Desenvolva sql para retornar os registros da tabela candidatos_2018.candidatos
--       cujo nm_urna_candidato inicie com DR. (case insensitive)


-- 7. Desenvolva sql que extraia a primeira palavra de nm_urna_candidato
--       de registros da tabela candidatos_2018.candidatos
--       quando nm_urna_candidato for diferente de nm_candidato
--       EXTRA: agrupe pela primeira palavra e calculo a quantidade


-- 8. Desenvolva sql que calcule o domínio dos emails(nm_email) dos registros da tabela candidatos_2018.candidatos
--       meu_email@domi.ni.o
--       EXTRA: agrupe e calcule a quantidade


-- 9. Desenvolva sql para retornar os registros da tabela candidatos_2018.candidatos
--       onde o email(nm_email) termina em UFC.BR


-- 10. Desenvolva sql para gerar textos com a seguinte estrutura, para registros em candidatos_2018.candidatos
--        "O candidato {nm_candidato} está concorrendo ao cargo {ds_cargo}. Ele é natural de {nm_municipio_nascimento}."
--         EXTRA: nm_candidato e nm_municipio_nascimento devem ter cada palavra iniciada com caixa alta, as demais letras em caixa baixa


-- 11. Desenvolva sql para retornar os registros em candidatos_2018.candidatos
--        adicionada de coluna CPF contendo nr_cpf_candidato com 11 dígitos(adicionar 0's à esquerda se necessário)


-- 12. Desenvolva sql que retorne o nome dos candidatos na forma SOBRENOMES, PRIMEIRO NOME
--        ex: SILMARA DE BRITO SOUZA  DE BRITO SOUZA -> DE BRITO SOUZA, SILMARA


-- 13. Desenvolva sql que retorne a primeira posição da string 'sql' nos valores da coluna 'palavra'
--        deve ser considerada qualquer variação no case da string
--        ex: 'sql123' -> 1
--            '123SqL123SQLsql' -> 4
--            '9999sqL999sql' -> 5
select palavra, -- coloque seu código aqui
from (values ('sql123'), ('123SqL123SQLsql'), ('9999sqL999sql')) as t(palavra);


-- 14. Desenvolva sql que retorne a placa de carro de registros em candidatos_2018.bens
--        que seguem o padrão:
--           possuem 'placa' como substring e o padrão AAA(um caractere qualquer)9999 depois
--        ex: Um veiculo TOYOTA HILUX SW4 branca 2013/2013 placa OSX 3213. Valor: R$ 140.000,00 (cem e quarenta mil reais). 
--            VW/GOL 1000, ANO 1993,COR BRANCA,PLACA HUG 4088
--        Extra: para as placas capturadas, reformatar ela para o padrão AAA-9999
--                  letras maísculas, hífen e números