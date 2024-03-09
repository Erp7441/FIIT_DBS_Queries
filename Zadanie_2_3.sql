-- Ziskaj count postov tagnutych podla tagu na vstupe (vsetko je v tags tabulke)
-- Podel to overall poctom postov


WITH weekday_counts AS (
    SELECT
        trim(to_char(creationdate, 'day')) AS weekday,  -- Prekonvertovanie creation datumu na den tyzdna
        COUNT(id) AS total_count  -- Pocet vsetkych postov...
    FROM posts p
    GROUP BY weekday  -- ...poda tyzdna
)
SELECT
    trim(to_char(p.creationdate, 'day')) AS weekday,  -- Prekonvertovanie creation datumu na den tyzdna
    ROUND(((COUNT(t.tagname)::FLOAT / wc.total_count::FLOAT) * 100)::numeric, 2) AS percent  -- Vypocet percent
FROM
    tags t
    JOIN post_tags pt ON t.id = pt.tag_id  -- Aby sme vedeli priradit tag_id k post_id
    JOIN posts p ON pt.post_id = p.id  -- Aby sme vedelit priradit post k post_id
    JOIN weekday_counts wc ON trim(to_char(p.creationdate, 'day')) = wc.weekday  -- Spojenie total count tabulky na
-- tyzdnoch
WHERE t.tagname = 'linux' -- odfiltrovanie tagu
GROUP BY trim(to_char(p.creationdate, 'day')), t.tagname, wc.total_count
ORDER BY
    CASE
        WHEN trim(to_char(p.creationdate, 'day')) = 'monday' THEN 1
        WHEN trim(to_char(p.creationdate, 'day')) = 'tuesday' THEN 2
        WHEN trim(to_char(p.creationdate, 'day')) = 'wednesday' THEN 3
        WHEN trim(to_char(p.creationdate, 'day')) = 'thursday' THEN 4
        WHEN trim(to_char(p.creationdate, 'day')) = 'friday' THEN 5
        WHEN trim(to_char(p.creationdate, 'day')) = 'saturday' THEN 6
        WHEN trim(to_char(p.creationdate, 'day')) = 'sunday' THEN 7
    END


-- Correct
-- WITH total_posts AS (
--     SELECT EXTRACT(DOW FROM posts.creationdate) AS weekday, COUNT(DISTINCT posts.id) AS total
--     FROM posts
--              JOIN post_tags ON posts.id = post_tags.post_id
--     GROUP BY weekday
-- ),
--      linux_posts AS (
--          SELECT EXTRACT(DOW FROM posts.creationdate) AS weekday, COUNT(DISTINCT posts.id) AS linux_total
--          FROM posts
--                   JOIN post_tags ON posts.id = post_tags.post_id
--                   JOIN tags ON post_tags.tag_id = tags.id
--          WHERE tagname = 'linux'
--          GROUP BY weekday
--      )
-- SELECT
--     CASE total_posts.weekday
--         WHEN 0 THEN 'Sunday'
--         WHEN 1 THEN 'Monday'
--         WHEN 2 THEN 'Tuesday'
--         WHEN 3 THEN 'Wednesday'
--         WHEN 4 THEN 'Thursday'
--         WHEN 5 THEN 'Friday'
--         WHEN 6 THEN 'Saturday'
--         END AS weekday_name,
--     (linux_posts.linux_total::decimal / total_posts.total * 100) AS percentage
-- FROM linux_posts
--          JOIN total_posts ON linux_posts.weekday = total_posts.weekday
-- ORDER BY total_posts.weekday;