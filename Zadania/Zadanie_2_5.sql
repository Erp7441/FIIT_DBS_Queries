-- CTE postov s zoznamom tagov
WITH post_id_tags AS (
    -- Vyber vsetkych post_id s zoznamom tagov
    SELECT post_id, array_agg(tagname) as tags
    FROM post_tags
    -- Spojenie tabuliek mien tagov a posts_tags podla ID aby sme dostali tabulku post_id s listom mien ich tagov
    LEFT JOIN tags ON post_tags.tag_id = tags.id
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
-- Spojenie s posts tabulkou na IDcke aby sme dostali zoznam postov s ich atributmi + novym zoznamom tags
LEFT JOIN post_id_tags ON post_id = posts.id
-- Vyhladavanie stringu v tele a v titulku postu
WHERE posts.title ILIKE '%%' OR posts.body ILIKE '%%'
ORDER BY creationdate DESC
--LIMIT 2  -- Limit poctu postov