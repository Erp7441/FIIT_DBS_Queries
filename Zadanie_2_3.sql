-- Ziskaj count postov tagnutych podla tagu na vstupe (vsetko je v tags tabulke)
-- Podel to overall poctom postov


WITH weekday_counts AS (
    SELECT
        to_char(creationdate, 'day') AS weekday,  -- Prekonvertovanie creation datumu na den tyzdna
        COUNT(*) AS total_count  -- Pocet vsetkych postov...
    FROM posts
    GROUP BY weekday  -- ...podla tyzdna
)
SELECT
    to_char(p.creationdate, 'day') AS weekday,  -- Prekonvertovanie creation datumu na den tyzdna
    --COUNT(t.tagname),  -- spocitaj vsetky occurences odfiltrovaneho tagnamu TODO:: Remove
    --wc.total_count,  -- total count per tyzden TODO:: Remove
    ROUND(((COUNT(t.tagname)::FLOAT / wc.total_count::FLOAT) * 100)::numeric, 2) AS percent
FROM
    tags t
    JOIN post_tags pt ON t.id = pt.tag_id  -- Spojenie s tabolkou post tag id's
    JOIN posts p ON pt.post_id = p.id  -- Spojenie s tabulkou actual postov (aby sme si vedeli potiahnut creation date)
    JOIN weekday_counts wc ON to_char(p.creationdate, 'day') = wc.weekday  -- Spojenie total count tabulky na tyzdnoch
WHERE t.tagname = 'linux' -- odfiltrovanie tagnamu
GROUP BY to_char(p.creationdate, 'day'), t.tagname, wc.total_count
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