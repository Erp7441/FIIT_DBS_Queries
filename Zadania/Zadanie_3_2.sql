SELECT
	post_id, title, displayname, text, posts_created_at, created_at,
	TO_CHAR(
			(EXTRACT(EPOCH FROM (created_at - last_comment_date)) || ' second')::INTERVAL,
			'HH24:MI:SS.MS'
	) AS diff
	-- TODO:: AVG pomocou array agregacie a AVG, mozno union pod tuto tabulku a z tejto tabulky vypocitat AVG?
FROM (
     SELECT
         p.id AS post_id,
         title,
         displayname,
         c.text AS text,
         p.creationdate AS posts_created_at,
         c.creationdate AS created_at,
         NULLIF((
             SELECT creationdate
             FROM comments
             WHERE postid = p.id AND creationdate < c.creationdate
             ORDER BY creationdate DESC
             LIMIT 1
         ),(
             SELECT creationdate
             FROM posts
             WHERE id = p.id
		 )) AS last_comment_date
     FROM
         comments c
             JOIN posts p ON c.postid = p.id
             JOIN users u ON c.userid = u.id
     WHERE c.postid = 1034137
) AS main_table
WHERE last_comment_date NOTNULL



















-- SELECT *
-- --     posts.id AS post_id,
-- --     posts.title,
-- --     displayname,
--     -- text komentara
-- --     posts.creationdate AS posts_created_at
--     -- Comment created at
--     -- diff
--     -- avg
-- FROM (
--     SELECT
--         postid,
--         title,
--         displayname,
--         c.text,
--         p.creationdate AS post_created,
--         c.creationdate AS comment_created,
--         (last_comment_date - c.creationdate) AS diff
--     FROM comments c
--     JOIN posts p ON c.postid = p.id
--     JOIN post_tags pt ON p.id = pt.post_id
--     JOIN tags t ON pt.tag_id = t.id
--     JOIN users ON c.userid = users.id
--     JOIN LATERAL (
--         SELECT
--             id,
--             creationdate AS last_comment_date
--         FROM comments c3
--         WHERE c.creationdate > c3.creationdate
--         ORDER BY creationdate DESC
--         LIMIT 1
--     ) AS c2 ON c2.id = c.id
--     WHERE tagname = 'networking'
-- ) AS c_count
-- WHERE c_count > 40
