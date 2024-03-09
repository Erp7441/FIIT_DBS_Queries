WITH post_id_tags AS (
    SELECT post_id, array_agg(tagname) as tags
    FROM post_tags
    JOIN tags ON post_tags.tag_id = tags.id
    GROUP BY post_id
)
SELECT
    id,
    (to_char(creationdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS creationdate,
    viewcount,
    (to_char(lasteditdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS lasteditdate,
    (to_char(lastactivitydate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS lastactivitydate,
    title, body, answercount,
    (to_char(closeddate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS closeddate,
    tags
FROM posts
JOIN post_id_tags ON post_id = posts.id
WHERE posts.title LIKE '%linux%' OR posts.body LIKE '%linux%'
ORDER BY creationdate DESC
LIMIT 1