WITH user_comments AS (
    SELECT userid, creationdate
    FROM comments
    WHERE postid = 1819157
    ORDER BY creationdate DESC
),
unique_users AS (
    SELECT DISTINCT ON (userid) userid, creationdate AS lastcommentcreationdate
    FROM user_comments
)
SELECT
    id, reputation,
    (to_char(creationdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS creationdate,
    displayname,
    (to_char(lastaccessdate::TIMESTAMP AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS lastaccessdate,
    websiteurl, location, aboutme, views, upvotes, downvotes, profileimageurl, age, accountid
FROM users
JOIN unique_users ON users.id = unique_users.userid
ORDER BY lastcommentcreationdate DESC
