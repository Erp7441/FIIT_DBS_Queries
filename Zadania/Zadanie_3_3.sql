SELECT
	id, displayname, body, text, score, position
FROM (
	-- Tabulka kde si najoinujem dohromady komentare, posty ktorym patria, tagoch tych postov a userov ktory
	-- vytvorili ten komentar
	SELECT
		c.id AS id,
		displayname, body, text,
		c.score AS score,
		-- Kalkulacia pozicie komentara v tabulke comments pomocou row number window funkcie
		-- Pozicia komentara je relativna v ramci postu
		ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY c.id) AS position,
		TO_CHAR(p.creationdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF:TZM') AS creationdate
	FROM comments c
	JOIN posts p ON c.postid = p.id
	JOIN post_tags pt on pt.post_id = p.id
	JOIN tags t on pt.tag_id = t.id
	LEFT JOIN users ON c.userid = users.id
	-- Odfiltrovanie podla tagnamu
	WHERE tagname = 'linux'  -- Parameter
) AS s
-- Filtrovanie kazdeho K komentara podla pozicie
WHERE position = 2  -- Parameter
ORDER BY creationdate
LIMIT 1  -- Parameter













































-- Uncommented
-- SELECT
-- 	id, displayname, body, text, score,
-- 	position + 2 AS position  -- Parameter
-- FROM (
-- 	SELECT
-- 		c.id AS id,
-- 		displayname, body, text,
-- 		c.score AS score,
-- 		(ROW_NUMBER() OVER (ORDER BY c.id)) % 2 AS position, -- Parameter
-- 		TO_CHAR(p.creationdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF:TZM') AS creationdate
-- 	FROM comments c
-- 	JOIN posts p ON c.postid = p.id
-- 	JOIN post_tags pt on pt.post_id = p.id
-- 	JOIN tags t on pt.tag_id = t.id
-- 	LEFT JOIN users ON c.userid = users.id
-- 	WHERE tagname = 'linux'  -- Parameter
-- ) AS s
-- WHERE position % 2 = 0  -- Parameter
-- ORDER BY creationdate
-- LIMIT 1  -- Parameter


