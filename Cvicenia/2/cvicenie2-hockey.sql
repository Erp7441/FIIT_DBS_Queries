DROP TABLE IF EXISTS players CASCADE;
CREATE TABLE players (
	id serial NOT NULL PRIMARY KEY, -- nieco ako auto increment v MySQL
	firstname varchar(20) NOT NULL,
	lastname varchar(20) NOT NULL,
	day_of_birth timestamp 
);

DROP TABLE IF EXISTS teams CASCADE;
CREATE TABLE teams (
	id serial NOT NULL PRIMARY KEY, 
	name text NOT NULL,
	stadium_name TEXT,
	owner text NOT NULL,
	salary INTEGER NOT NULL
);

DROP TABLE IF EXISTS seasons CASCADE;
CREATE TABLE seasons (
	id serial NOT NULL PRIMARY KEY,
    name TEXT

);

DROP TABLE IF EXISTS player_statistics CASCADE;
CREATE TABLE player_statistics (
	id serial NOT NULL PRIMARY KEY,
	player_id INT not null REFERENCES players(id),
    team_id INT NOT NULL REFERENCES teams(id),
	season_id INT NOT NULL REFERENCES seasons(id),
	goals INT,
	assists INT,
	jersey INT,
	games INT,
	penalty_minutes INT,
	plus_minus INT,
	start_date timestamp,
	end_date timestamp



);
SELECT setval('players_id_seq', 8, true);
SELECT setval('teams_id_seq', 9, true);
SELECT setval('seasons_id_seq', 5, true);

INSERT INTO players(id,firstname,lastname,day_of_birth) VALUES
	(1,'Connor', 'McDavid','1993-1-13'),
	(2,'Claude', 'Giroux','1988-1-12'),
	(3,'Nikita', 'Kucherov','1993-6-17'),
	(4,'Nathan', 'MacKinnon','1995-9-1'),
	(5,'Taylor', 'Hall','1991-11-14'),
	(6,'Joe', 'Sakic','1987-10-2'),
	(7,'Phil', 'Kessel','1993-1-13'),
	(8,'Alex', 'Ovechkin','1985-9-17');


INSERT INTO teams(id,name,owner,salary) VALUES
	(1,'Arizona Coyotes', 'Jozef',70000),
    (2,'Philadelphia Flyers York', 'Fero',20000),
    (3,'Edmonton Oilers', 'Alojz',10000),
	(4,'Boston Bruins', 'Dusan',71000),
	(5,'Washington Capitols', 'Jan',90000),
	(6,'Colorado Avalanche', 'Patrik',60000),
	(7,'Tampa Bay Lighting', 'Dusan',150000),
    (8,'New jersey Devils', 'Nigma',150000),
    (9,'Pittsburgh Penguins', 'Galaxy',150000);
	
	

INSERT INTO seasons(id,name) VALUES
    (1,'2015-2016'),
    (2,'2016-2017'),
    (3,'2017-2018'),
    (4,'2018-2019'),
    (5,'2019-2020');
	

INSERT INTO player_statistics(player_id,team_id,season_id,	goals,assists ,jersey, games, penalty_minutes, plus_minus,start_date,end_date) VALUES
   (1,3,1,16,32,0,45,18,-1,null,null),
   (1,3,2,30,70,0,82,26,27,null,null),
   (1,3,3,41,67,0,82,26,20,null,null),
   (1,3,4,41,75,0,78,20,3,null,null),
   (1,3,5,34,63,0,64,28,-6,null,null),
   (2,2,1,22,45,0,78,53,-8,null,null),
   (2,2,2,14,44,0,82,38,-15,null,null),
   (2,2,3,34,68,0,82,20,28,null,null),
   (2,2,4,22,63,0,82,24,9,null,null),
   (2,2,5,21,32,0,69,28,7,null,null),
   (3,7,1,30,36,0,77,30,9,null,null),
   (3,7,2,40,45,0,74,38,13,null,null),
   (3,7,3,39,61,0,80,42,15,null,null),
   (3,7,4,41,87,0,82,62,24,null,null),
   (3,7,5,33,52,0,68,38,26,null,null),
   (4,6,1,21,31,0,72,20,-4,null,null),
   (4,6,2,16,37,0,82,16,-14,null,null),
   (4,6,3,39,58,0,74,55,11,null,null),
   (4,6,4,41,58,0,82,34,20,null,null),
   (4,6,5,35,58,0,69,12,13,null,null),
   (5,3,1,26,39,0,82,54,-4,null,null),
   (5,8,2,20,33,0,72,32,-9,null,null),
   (5,8,3,39,54,0,76,34,14,null,null),
   (5,8,4,11,26,0,33,16,-6,null,null),
   (5,8,5,6,19,0,30,20,-11,null,null),
   (5,1,5,10,17,0,35,14,-3,null,null),
   (7,9,1,26,33,0,82,18,9,null,null),
   (7,9,2,23,47,0,82,20,3,null,null),
   (7,9,3,34,58,0,82,36,-4,null,null),
   (7,9,4,27,55,0,82,28,-19,null,null),
   (7,1,5,14,24,0,70,22,-21,null,null),
   (8,5,1,50,21,0,79,53,21,null,null),
   (8,5,2,33,36,0,82,50,6,null,null),
   (8,5,3,49,38,0,82,32,3,null,null),
   (8,5,4,51,38,0,81,33,7,null,null),
   (8,5,5,48,19,0,68,35,-12,null,null);
   
