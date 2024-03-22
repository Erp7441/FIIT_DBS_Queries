-- My comments

-- SELECT
-- 	ROW_NUMBER() OVER () AS position,
-- 	badge_id,
-- 	badge_name,
-- 	TO_CHAR(badge_date AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF:TZM') AS badge_date,
-- 	ROW_NUMBER() OVER () AS position,
-- 	post_id,
-- 	post_title,
-- 	TO_CHAR(post_date AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF:TZM') AS badge_date
-- FROM (
-- 	SELECT
-- 		DISTINCT ON (comment_date)
-- 		*
-- 	FROM (
-- 		 SELECT
-- 			 DISTINCT ON (badge_id)  -- Vyfiltrovanie duplikatov z subquery
-- 				 badge_id,
-- 				 badge_name,
-- 				 badge_date,
-- 				 p.id AS post_id,
-- 				 p.title AS post_title,
-- 				 p.creationdate AS post_date,
-- 				 comment_date
-- 		FROM (
-- 			-- Ziska badge info + komentare ktore boli vytvorene skor ako badge
-- 			SELECT
-- 				b2.id AS badge_id,
-- 				b2.name AS badge_name,
-- 				b2.date AS badge_date,
-- 				c2.creationdate AS comment_date,
-- 				c2.postid AS post_id
-- 			-- Vytvori tabulu s infom o useroch, ich badges a ich komentarov
-- 			FROM users
-- 				JOIN badges b2 ON users.id = b2.userid
-- 				JOIN comments c2 ON users.id = c2.userid
-- 			-- Filtrovanie userid a vsetkych komentare ktore boli vytvorene skor ako badge
-- 			WHERE users.id = 120 AND b2.date >= c2.creationdate
-- 		) AS badge_comment
-- 		JOIN posts p ON badge_comment.post_id = p.id
-- 		ORDER BY badge_id, badge_comment.comment_date DESC  -- Toto zaruci ze zaznamy su zoradene od najnovsieho komentara. To znamena ze DISTINCT na zaciatku odfiltruje vsetky stare komentare
-- 	) AS submain
-- 	ORDER BY comment_date, post_id
-- ) AS main

;

-- My posts
SELECT
	badge_id, badge_name,
	TO_CHAR(badge_date AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF:TZM') AS badge_date,
	post_id, post_title,
	TO_CHAR(post_date AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF:TZM') AS post_date
FROM (
	SELECT
		DISTINCT ON (post_date)
		*
	FROM (
		SELECT
			DISTINCT ON (badge_id)  -- Vyfiltrovanie duplikatov z subquery
			*
		FROM (
			-- Ziska badge info + komentare ktore boli vytvorene skor ako badge
			SELECT
				b2.id AS badge_id,
				b2.name AS badge_name,
				b2.date AS badge_date,
				p2.id AS post_id,
				p2.creationdate AS post_date,
				p2.title AS post_title
			-- Vytvori tabulu s infom o useroch, ich badges a ich postoch
			FROM users
				JOIN badges b2 ON users.id = b2.userid
				JOIN posts p2 ON p2.owneruserid = b2.userid
			-- Filtrovanie userid a vsetkych postov ktore boli vytvorene skor ako badge
			WHERE users.id = 120 AND b2.date >= p2.creationdate  -- userid je parameter
		) AS bp
		ORDER BY badge_id, bp.post_date DESC  -- Toto zaruci ze zaznamy su zoradene od najnovsieho postu.
		-- To namena ze DISTINCT na zaciatku odfiltruje vsetky stare posty
	) AS s
	ORDER BY post_date, post_id
) AS m


-- Bajo (for reference only)
-- SELECT
--     ROW_NUMBER() OVER () AS poradie,
--     *
-- FROM
--     (
--     SELECT
--         --zgrupnute podla badges a ocisluje posty od najstarsich po najstarsie
--         ROW_NUMBER() OVER (PARTITION BY bg.id ORDER BY pt.creationdate DESC) AS group_A,
--         --zgrupne podla posts a ocisluje badges od najmladsich po najstarsie
--         ROW_NUMBER() OVER (PARTITION BY pt.id ORDER BY bg.date ASC) AS group_B,
--         pt.id AS posts_id,
--         bg.id AS badges_id,
--         pt.title AS posts_title,
--         bg.name AS badges_name,
--         TO_CHAR(pt.creationdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF:TZM') AS posts_creationdate,
--         TO_CHAR(bg.date AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MSOF:TZM') AS badges_date
--     FROM posts AS pt
--     INNER JOIN badges AS bg
--     ON pt.owneruserid=120 AND pt.owneruserid=bg.userid AND pt.creationdate < bg.date
--     ORDER BY pt.creationdate
-- ) AS subquery
-- WHERE group_A=1 AND group_B=1;






-- Badge + comment date
-- SELECT
--     DISTINCT ON (id)
--     *
-- FROM badges b, LATERAL (
--     SELECT
--         b2.id AS badge_id,
--         c2.creationdate AS comment_date
--     FROM users
--              JOIN badges b2 ON users.id = b2.userid
--              JOIN comments c2 ON users.id = c2.userid
--              JOIN posts p2 ON c2.postid = p2.id
--     WHERE users.id = 120 AND b2.id = b.id AND b2.date >= c2.creationdate
--     ORDER BY comment_date DESC
--     ) AS badge_comment

-- Working query but not really that optimal
-- SELECT
--     DISTINCT ON (id)
--     badge_comment.badge_id,
--     b.name,
--     b.date,
--     badge_comment.post_id,
--     badge_comment.post_title,
--     badge_comment.post_date
-- FROM badges b, LATERAL (
--     SELECT
--         b2.id AS badge_id,
--         c2.creationdate AS comment_date,
--         p2.id AS post_id,
--         p2.title AS post_title,
--         p2.creationdate AS post_date
--     FROM users
--         JOIN badges b2 ON users.id = b2.userid
--         JOIN comments c2 ON users.id = c2.userid
--         JOIN posts p2 ON c2.postid = p2.id
--     WHERE users.id = 120 AND b2.id = b.id AND b2.date >= c2.creationdate
--     ORDER BY comment_date DESC
--     ) AS badge_comment

-- Optimalized query 1
-- SELECT
--     DISTINCT ON (badge_id)
--     badge_comment.badge_id,
--     badge_name,
--     badge_date,
--     p.id AS post_id,
--     p.title AS post_title,
--     badge_comment.comment_date,
--     p.creationdate AS post_date
-- FROM (
--          SELECT
--              b2.id AS badge_id,
--              b2.name AS badge_name,
--              b2.date AS badge_date,
--              c2.creationdate AS comment_date,
--              c2.postid AS post_id
--          FROM users
--                   JOIN badges b2 ON users.id = b2.userid
--                   JOIN comments c2 ON users.id = c2.userid
--          WHERE users.id = 120 AND b2.date >= c2.creationdate
--      ) AS badge_comment
--          JOIN posts p ON badge_comment.post_id = p.id
-- ORDER BY badge_id, badge_comment.comment_date DESC


-- /w duplicates
-- SELECT
-- 	DISTINCT ON (badge_id)  -- Vyfiltrovanie duplikatov z subquery
-- 							badge_comment.badge_id,
-- 							badge_name,
-- 							badge_date,
-- 							p.id AS post_id,
-- 							p.title AS post_title,
-- 							p.creationdate AS post_date,
-- 							comment_date
-- 	FROM (
-- 			 -- Ziska badge info + komentare ktore boli vytvorene skor ako badge
-- 			 SELECT
-- 				 b2.id AS badge_id,
-- 				 b2.name AS badge_name,
-- 				 b2.date AS badge_date,
-- 				 c2.creationdate AS comment_date,
-- 				 c2.postid AS post_id
-- 			 -- Vytvori tabulu s infom o useroch, ich badges a ich komentarov
-- 				 FROM users
-- 						  JOIN badges b2 ON users.id = b2.userid
-- 						  JOIN comments c2 ON users.id = c2.userid
-- 			 -- Filtrovanie userid a vsetkych komentare ktore boli vytvorene skor ako badge
-- 				 WHERE users.id = 120 AND b2.date >= c2.creationdate
-- 		 ) AS badge_comment
-- 			 JOIN posts p ON badge_comment.post_id = p.id
-- 	ORDER BY badge_id, badge_comment.comment_date DESC  -- Toto zaruci ze zaznamy su zoradene od najnovsieho komentara. To znamena ze DISTINCT na zaciatku odfiltruje vsetky stare komentare


-- Koment verzia
-- SELECT
-- 	ROW_NUMBER() OVER () AS position,
-- 	badge_id,
-- 	badge_name,
-- 	badge_date,
-- 	ROW_NUMBER() OVER () AS position,
-- 	post_id,
-- 	post_title,
-- 	post_date
-- FROM (
-- 	SELECT
-- 		DISTINCT ON (comment_date)
-- 		*
-- 	FROM (
-- 		 SELECT
-- 			 DISTINCT ON (badge_id)  -- Vyfiltrovanie duplikatov z subquery
-- 				 badge_id,
-- 				 badge_name,
-- 				 badge_date,
-- 				 p.id AS post_id,
-- 				 p.title AS post_title,
-- 				 p.creationdate AS post_date,
-- 				 comment_date
-- 		FROM (
-- 			-- Ziska badge info + komentare ktore boli vytvorene skor ako badge
-- 			SELECT
-- 				b2.id AS badge_id,
-- 				b2.name AS badge_name,
-- 				b2.date AS badge_date,
-- 				c2.creationdate AS comment_date,
-- 				c2.postid AS post_id
-- 			-- Vytvori tabulu s infom o useroch, ich badges a ich komentarov
-- 			FROM users
-- 				JOIN badges b2 ON users.id = b2.userid
-- 				JOIN comments c2 ON users.id = c2.userid
-- 			-- Filtrovanie userid a vsetkych komentare ktore boli vytvorene skor ako badge
-- 			WHERE users.id = 120 AND b2.date >= c2.creationdate
-- 		) AS badge_comment
-- 		JOIN posts p ON badge_comment.post_id = p.id
-- 		ORDER BY badge_id, badge_comment.comment_date DESC  -- Toto zaruci ze zaznamy su zoradene od najnovsieho komentara. To znamena ze DISTINCT na zaciatku odfiltruje vsetky stare komentare
-- 	) AS submain
-- 	ORDER BY comment_date, post_id
-- ) AS main

