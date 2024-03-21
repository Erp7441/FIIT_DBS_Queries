--- Endpoint 1
-- Docastna tabulka CTE s komentarami userov na danom poste zoradena od najnovsieho po najstarsi
WITH user_comments AS (
    SELECT userid, creationdate  -- Select userov a datumom kedy vytvorili komentar
    FROM comments  -- Z tabulky comments
    WHERE postid = 1014866  -- Postu s ID
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








--- Endpoint 2
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
        WHERE posts.owneruserid = 233630 -- Post vytvorenym hladanym pouzivatelom
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
    WHERE userid = 233630  -- Post kde komentoval hladany pouzivatel
    ) -- AND userid != 1 -- Odfiltrovanie usera na ktoreho pozerame TODO:: Podla zadania mame mat kamarata seba
    )
ORDER BY users.creationdate





--- Endpoint 3
-- CTE overall poctu postov per weekday
WITH weekday_counts AS (
    SELECT
        trim(to_char(creationdate, 'day')) AS weekday,  -- Prekonvertovanie creation datumu na den tyzdna
        COUNT(id) AS total_count  -- Pocet vsetkych postov...
    FROM posts p
    GROUP BY weekday  -- ...podla tyzdna
)
SELECT
    trim(to_char(p.creationdate, 'day')) AS weekday,  -- Prekonvertovanie creation datumu na den tyzdna
    ROUND(((COUNT(t.tagname)::FLOAT / wc.total_count::FLOAT) * 100)::numeric, 2) AS percent  -- Vypocet percent
FROM
    tags t
        JOIN post_tags pt ON t.id = pt.tag_id  -- Aby sme vedeli priradit tagname k post_id
        JOIN posts p ON pt.post_id = p.id  -- Aby sme vedelit priradit post_id k samotnemu postu (s jeho attribs)
    -- Spojenie CTE tabulky na tyzdnoch. Tym dostaneme tabulku kde je stlpec overall postov per weekday a
    -- Pocet postov ktore su otagovane tagom ktory zvolime nizsie
        JOIN weekday_counts wc ON trim(to_char(p.creationdate, 'day')) = wc.weekday
WHERE t.tagname = 'linux' -- odfiltrovanie konkretneho tagu
GROUP BY trim(to_char(p.creationdate, 'day')), t.tagname, wc.total_count
ORDER BY
    -- Zoradenie od pondelka po nedelu
    CASE
        WHEN trim(to_char(p.creationdate, 'day')) = 'monday' THEN 1
        WHEN trim(to_char(p.creationdate, 'day')) = 'tuesday' THEN 2
        WHEN trim(to_char(p.creationdate, 'day')) = 'wednesday' THEN 3
        WHEN trim(to_char(p.creationdate, 'day')) = 'thursday' THEN 4
        WHEN trim(to_char(p.creationdate, 'day')) = 'friday' THEN 5
        WHEN trim(to_char(p.creationdate, 'day')) = 'saturday' THEN 6
        WHEN trim(to_char(p.creationdate, 'day')) = 'sunday' THEN 7
        END




--- Endpoint 4
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
)
-- Vyber vsetkych udajov o postoch ktore su kratsie alebo rovnako dlhe ako duration
SELECT *
FROM closed_posts_duration
WHERE duration <= 5  -- Parameter duration
ORDER BY creationdate DESC
LIMIT 10  -- Limit poctu postov vyobrazenych





--- Endpoint 5
-- CTE postov s zoznamom tagov
WITH post_id_tags AS (
    -- Vyber vsetkych post_id s zoznamom tagov
    SELECT post_id, array_agg(tagname) as tags
    FROM post_tags
             -- Spojenie tabuliek mien tagov a posts_tags podla ID aby sme dostali tabulku post_id s listom mien ich tagov
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
-- Spojenie s posts tabulkou na IDcke aby sme dostali zoznam postov s ich atributmi + novym zoznamom tags
         JOIN post_id_tags ON post_id = posts.id
-- Vyhladavanie stringu v tele a v titulku postu
WHERE posts.title LIKE '%linux%' OR posts.body LIKE '%linux%'
ORDER BY creationdate DESC
LIMIT 10  -- Limit poctu postov