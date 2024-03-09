WITH user_comments AS (
    SELECT userid, creationdate
    FROM comments
    WHERE postid = 1
    ORDER BY creationdate DESC
),
unique_users AS (
    SELECT DISTINCT ON (userid) userid, creationdate AS lastcommentcreationdate
    FROM user_comments
)
SELECT users.*
FROM users
JOIN unique_users ON users.id = unique_users.userid
ORDER BY lastcommentcreationdate DESC
