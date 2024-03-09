WITH post_id_tags AS (
    SELECT post_id, array_agg(tagname) as tags
    FROM post_tags
    JOIN tags ON post_tags.tag_id = tags.id
    GROUP BY post_id
)
SELECT id, creationdate, viewcount, lasteditdate, lastactivitydate, title, body, answercount, closeddate, tags
FROM posts
JOIN post_id_tags ON post_id = posts.id
WHERE posts.title LIKE '%%' OR posts.body LIKE '%%'
ORDER BY creationdate DESC
LIMIT 1