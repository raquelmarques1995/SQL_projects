use movie;

-- Para conhecer as tables
SELECT * FROM Genre;
SELECT * FROM Director;
SELECT * FROM Movie;

-- 1. (4 val.) Crie uma Query que apresente todos os Movies (title,year,duration,genre,director).
SELECT M. title AS Titulo, M. year AS Ano, M. duration AS `Duração(min)`, G. genre AS Género, D. director AS Realizador
FROM Movie M
INNER JOIN Genre G ON M.genre_id = G.id
INNER JOIN Director D ON M.director_id = D.id
ORDER BY year DESC;


-- 2. (4 val.) Crie uma Query que liste todos Directors com mais do que um Movie.
SELECT D. director AS Realizador, COUNT(M.title) AS `Total de filmes realizados`
FROM Movie M
INNER JOIN Director D ON M.director_id = D.id
GROUP BY D.director
HAVING COUNT(M.title)>1
ORDER BY COUNT(M.title) DESC;


-- 3. (4 val.) Crie uma Query que apresente o total de Movies por year em que o genre inclui Comedy.
SELECT M.year AS Ano, COUNT(M.title) AS `Total de filmes de comédia`
FROM Movie M
INNER JOIN Genre G ON G.id = M.genre_id
WHERE G.genre LIKE '%Comedy%'
GROUP BY M.year
ORDER BY M.year DESC;
 
 
-- 4. (4 val.) Crie uma Query que liste o total de Movies agrupados por Director e por Year.

-- Dependendo das necessidades, a lista pode ser ordenada por ano ou por realizador, sendo visualmente diferentes. Assim deixo as duas soluções

-- Ordenado por ano
SELECT M. year AS Ano, D.director AS Realizador, COUNT(M.title) AS `Total de filmes realizados`
FROM Movie M
INNER JOIN Director D ON M.director_id = D.id
GROUP BY D.director, M.year
ORDER BY M.year DESC;

-- Ordenado por realizador
SELECT D.director AS Realizador, M. year AS Ano, COUNT(M.title) AS `Total de filmes realizados`
FROM Movie M
INNER JOIN Director D ON M.director_id = D.id
GROUP BY D.director, M.year
ORDER BY D.director;


-- 5. (4 val.) Crie uma Query que liste o Director que realizou mais Movies. Se houver mais do que um Director com o valor máximo de Movies, devem ser incluidos na listagem.
SELECT D.director AS Realizador, COUNT(M.title) AS `Total de filmes realizados`
FROM Movie M
INNER JOIN Director D ON M.director_id = D.id
GROUP BY D.director
HAVING COUNT(M.title) = (
	SELECT MAX(TotalMovies)
    FROM (
		SELECT COUNT(M1.title) AS `TotalMovies`
        FROM Movie M1
        INNER JOIN Director D1 ON D1.id = M1.director_id
        GROUP BY D1.director)MaxMovies);
    
-- Confirmação da query anterior
SELECT D.director AS Realizador, COUNT(M.title) AS `Total de filmes realizados`
FROM Movie M
INNER JOIN Director D ON D.id = M.director_id
GROUP BY D.director
ORDER BY `Total de filmes realizados` DESC;