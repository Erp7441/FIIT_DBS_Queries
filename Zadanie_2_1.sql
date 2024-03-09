-- Docastna tabulka CTE s komentarami userov na danom poste zoradena od najnovsieho po najstarsi
WITH user_comments AS (
    SELECT userid, creationdate  -- Select userov a datumom kedy vytvorili komentar
    FROM comments  -- Z tabulky comments
    WHERE postid = 1819157  -- Postu s ID
    ORDER BY creationdate DESC -- Zorad od najnovejsieho po najstarsi
),
-- CTE s unikatnymi usermi s poslednimi komentarami
unique_users AS (
    -- Vyber unikatnych userov z CTE user_comments s datumom ich poslednimi komentarami
    SELECT DISTINCT ON (userid) userid, creationdate AS lastcommentcreationdate
    FROM user_comments
)
SELECT
    id, reputation,
    -- Konverzia casu do UTC ISO8601
    (to_char(creationdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS creationdate,
    displayname,
    (to_char(lastaccessdate::TIMESTAMP AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF')) AS lastaccessdate,
    websiteurl, location, aboutme, views, upvotes, downvotes, profileimageurl, age, accountid
FROM users
-- Spojenie tabuliek o userov a unique_users CTE aby sme naparovali k userom datum ich latest komentare
JOIN unique_users ON users.id = unique_users.userid
ORDER BY lastcommentcreationdate DESC  -- Sort od najnovsieho po najstarsi komentar