SELECT
	displayname, body,
	TO_CHAR(p.creationdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF:TZM') AS creationdate
FROM posts p
LEFT JOIN users u ON p.owneruserid = u.id
-- Filtrovanie podla ID a parent ID postu pre ziskanie celeho threadu daneho post id.
WHERE p.id = 2154 OR p.parentid = 2154  -- Parametre
ORDER BY p.creationdate
LIMIT 2  -- Parameter