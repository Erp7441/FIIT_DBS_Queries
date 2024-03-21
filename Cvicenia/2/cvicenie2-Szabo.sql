-- 1. Uloha
-- SELECT firstname, lastname FROM players;

-- 2. Uloha
-- SELECT name FROM teams WHERE salary > 70000;

-- 3. Uloha
-- SELECT name FROM teams WHERE salary > 70000 AND owner ILIKE 'Dusan'; SELECT firstname, lastname FROM players WHERE id

-- 4. Uloha
-- SELECT firstname, lastname, games FROM players, player_statistics WHERE players.id = player_statistics.player_id AND games > 0

-- 5. Uloha
-- SELECT firstname, lastname, seasons.name FROM players, player_statistics, seasons WHERE players.id = player_statistics.player_id AND games > 0

-- 6. Uloha
-- SELECT firstname, lastname, seasons.name, (goals+assists) AS points
-- FROM players
-- JOIN player_statistics ON players.id = player_statistics.player_id
-- JOIN seasons ON seasons.id = player_statistics.season_id

-- 7. Uloha
-- SELECT
--     firstname,
--     lastname,
--     COALESCE(s.name, 'no season'),
--     COALESCE(goals+assists, 0) AS points
-- FROM players
-- LEFT JOIN player_statistics ON players.id = player_statistics.player_id
-- LEFT JOIN seasons AS s ON s.id = player_statistics.season_id

-- 8. Uloha
-- SELECT firstname, lastname, name AS team_name
-- FROM players
-- JOIN player_statistics ON players.id = player_statistics.player_id
-- JOIN teams AS t ON t.id = player_statistics.team_id

-- 9. Uloha
-- SELECT firstname, lastname, name AS team_name
-- FROM players
-- JOIN player_statistics ON players.id = player_statistics.player_id
-- JOIN teams AS t ON t.id = player_statistics.team_id
-- ORDER BY team_name

-- 10. Uloha
-- SELECT firstname, lastname, seasons.name AS season_name, (goals+assists) AS points
-- FROM players
-- LEFT JOIN player_statistics ON players.id = player_statistics.player_id
-- LEFT JOIN seasons ON seasons.id = player_statistics.season_id
-- WHERE seasons.name IS NULL

-- 11. Uloha
-- SELECT
--     firstname,
--     lastname,
--     COALESCE(goals+assists, 0) AS points,
--     CAST(((goals + assists) / games) AS FLOAT) AS statistics,
--     goals,
--     assists
-- FROM players
-- LEFT JOIN player_statistics AS ps ON players.id = ps.player_id
-- LEFT JOIN seasons AS s ON s.id = ps.season_id
-- WHERE s.name = '2019-2020'

-- 12. Uloha
-- SELECT firstname, lastname, name AS team_name
-- FROM players
-- JOIN player_statistics ON players.id = player_statistics.player_id
-- JOIN teams AS t ON t.id = player_statistics.team_id
-- WHERE t.name LIKE '%Arizona%'