-- CTE s zavretymi postami a casom ich trvania (closed - creation time) v minutach zaokruhlenym na 2 desatinne miesta
WITH closed_posts_duration AS (
    SELECT
        posts.id,
        (to_char(creationdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS creationdate,
        viewcount,
        (to_char(lasteditdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS lasteditdate,
        (to_char(lastactivitydate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS lastactivitydate,
        title,
        (to_char(closeddate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS closeddate,
        round((extract(EPOCH from (closeddate - creationdate))::decimal / 60), 2) as duration
    FROM posts
    WHERE closeddate IS NOT NULL
    ORDER BY id
)
-- Vyber vsetkych udajov o postoch ktore su kratsie alebo rovnako dlhe ako duration
SELECT *
FROM closed_posts_duration
WHERE duration <= 5  -- Parameter duration
ORDER BY creationdate DESC
LIMIT 2  -- Limit poctu postov vyobrazenych