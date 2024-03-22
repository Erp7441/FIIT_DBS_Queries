SELECT
	displayname,
	body,
	p.creationdate
FROM posts p
LEFT JOIN users u ON p.owneruserid = u.id
WHERE p.id = 2154 OR p.parentid = 2154
ORDER BY p.creationdate
LIMIT 2