SELECT
    id, reputation,
    (to_char(creationdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS creationdate,
    displayname,
    (to_char(lastaccessdate::TIMESTAMP AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF') ) AS lastaccessdate,
    websiteurl, location, aboutme, views, upvotes, downvotes, profileimageurl, age, accountid
FROM users
-- Kde user_id sa nachadza v subquery userov ktory komentovali na poste ktory bol vytvoreny hladanym pouzivatelom
WHERE id IN (
    -- Ziskaj userov ktory komentovali na poste ktory bol vytvoreny hladanym pouzivatelom
    SELECT DISTINCT userid
    FROM comments
    WHERE postid IN (
        SELECT id
        FROM posts
        WHERE posts.owneruserid = 1076348 -- Post vytvorenym hladanym pouzivatelom
    ) -- AND userid != 1 -- Odfiltrovanie usera na ktoreho pozerame TODO:: Podla zadania mame mat kamarata seba
    GROUP BY userid
)
-- Alebo sa user_id nachadza v subquery userov ktory komentovali na poste na ktorom komentoval hladany pouzivatel
OR id IN (
    -- Ziskaj userov ktory komentovali na poste na ktorom komentoval hladany pouzivatel
    SELECT DISTINCT userid
    FROM comments
    WHERE postid IN (
        SELECT postid
        FROM comments
        WHERE userid = 1076348  -- Post kde komentoval hladany pouzivatel
    ) -- AND userid != 1 -- Odfiltrovanie usera na ktoreho pozerame TODO:: Podla zadania mame mat kamarata seba
)
ORDER BY users.creationdate