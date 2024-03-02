SELECT *
FROM users
WHERE id IN (
    SELECT userid
    FROM comments
    WHERE postid = 1819157
    GROUP BY userid
    ORDER BY MAX(creationdate) DESC
)
