SELECT *
FROM (
	SELECT
		c.id AS id,
		displayname, body, text,
		c.score AS score,
		(ROW_NUMBER() OVER (ORDER BY c.id)) % 2 + 1 AS position,
		p.creationdate AS creationdate
	FROM comments c
	JOIN posts p ON c.postid = p.id
	JOIN post_tags pt on pt.post_id = p.id
	JOIN tags t on pt.tag_id = t.id
	LEFT JOIN users ON c.userid = users.id
	WHERE tagname = 'linux'
) AS s
WHERE position % 2 = 0
ORDER BY creationdate
LIMIT 1


