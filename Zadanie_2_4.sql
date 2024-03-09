WITH closed_posts_duration AS (
    SELECT id, round((extract(EPOCH from (closeddate - creationdate))::decimal / 60), 2) as duration
    FROM posts
    WHERE closeddate IS NOT NULL
    ORDER BY id
)
SELECT
    posts.id,
    (to_char(creationdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS creationdate,
    viewcount,
    (to_char(lasteditdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS lasteditdate,
    (to_char(lastactivitydate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS lastactivitydate,
    title,
    (to_char(closeddate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS closeddate,
    duration
FROM closed_posts_duration
JOIN posts ON posts.id = closed_posts_duration.id
WHERE duration <= 5
ORDER BY creationdate DESC
LIMIT 2

