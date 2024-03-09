WITH closed_posts_duration AS (
    SELECT id, round((extract(EPOCH from (closeddate - creationdate))::decimal / 60), 2) as duration
    FROM posts
    WHERE closeddate IS NOT NULL
    ORDER BY id
)
SELECT posts.id, creationdate, viewcount, lasteditdate, lastactivitydate, title, closeddate, duration
FROM closed_posts_duration
JOIN posts ON posts.id = closed_posts_duration.id
WHERE duration <= 5
ORDER BY creationdate DESC
LIMIT 2

