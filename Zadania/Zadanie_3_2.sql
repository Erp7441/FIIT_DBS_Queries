SELECT
	post_id, title, displayname, text, posts_created_at, created_at,
	TO_CHAR((created_at - last_comment_date), 'HH24:MI:SS.MS') AS diff,
	TO_CHAR(AVG((created_at - last_comment_date)) OVER (ORDER BY created_at), 'HH24:MI:SS.MS') AS avg_diff
FROM (
     SELECT
         p.id AS post_id,
         title,
         displayname,
         c.text AS text,
         p.creationdate AS posts_created_at,
         c.creationdate AS created_at,
         COALESCE((
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
		LEFT JOIN users u ON c.userid = u.id
		JOIN post_tags pt on p.id = pt.post_id
		JOIN tags t on t.id = pt.tag_id
     WHERE tagname = 'networking' AND p.commentcount > 40
) AS main_table
ORDER BY posts_created_at, created_at



















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
