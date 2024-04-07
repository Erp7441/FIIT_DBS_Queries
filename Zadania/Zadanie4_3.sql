-- Planovanie expozicie
INSERT INTO expositions (name, begindate, enddate, status)
	VALUES ('TestExpo', '2024-01-01', '2024-12-31', 'preparing');



-- Pridanie exemplara
INSERT INTO exemplars (name, status, creationdate, lastchangedate)
	VALUES ('TestExemp', 'in_warehouse', '2024-01-01', '2024-12-31');
-- Priradenie aspon jednej kategorie
INSERT INTO exemplars_categories (exemplarid, categoriesid)
	VALUES ('9ed428db-2078-4d08-b4d5-6999ce650856', '6ed428db-2078-4d08-b4d5-6999ce650856');



-- Presun exemplara
-- Updatenem exemplar
UPDATE exemplars
	SET status = 'on_display', lastchangedate = current_timestamp, locationid = '8ed428db-2078-4d08-b4d5-6999ce650859'
	WHERE ID = '9ed428db-2078-4d08-b4d5-6999ce650856';
-- Pridam novy zaznam o vystaveni
INSERT INTO showcased_exemplars (showcaseddate, removaldate)
	VALUES ('2024-01-01', '2024-12-31');
-- Napojim na seba exemplar a kedy bol vystaveny
INSERT INTO exemplars_showcased_exemplars (showcasedexemplarsid, exemplarid)
	VALUES ('9ed428db-2078-4d08-b4d5-6999ce650866', '9ed428db-2078-4d08-b4d5-6999ce650856');
INSERT INTO expositions_showcased_exemplars (showcasedexemplarsid, expositionsid)
	VALUES ('9ed428db-2078-4d08-b4d5-6999ce650866', '8ed428db-2078-4d08-b4d5-6999ce650856');


-- Prijatie exemplara
INSERT INTO borrows (exemplarid, institutionid, ownerid, borrowdate, returndate, checkstate, checklength)
	VALUES ('9ed428db-2078-4d08-b4d5-6999ce650856', '8ad428db-2078-4d08-b4d5-6999ce650856',
'8bd428db-2078-4d08-b4d5-6999ce650856', '2024-01-01', '2024-06-01', 'waiting_for_arrival', '14:00');

-- Ked pride exemplar tak skontrolujeme jeho stav
UPDATE borrows SET checkstate = 'checking' WHERE exemplarid = '9ed428db-2078-4d08-b4d5-6999ce650856';

-- Ked je okontrolovany tak ho zaradime na vystavovanie
INSERT INTO exemplars (name, status, creationdate, lastchangedate)
	VALUES ('TestExemp', 'in_warehouse', '2024-01-01', '2024-12-31');



-- Pozicanie exemplara
UPDATE exemplars SET status = 'borrowed', lastchangedate = current_timestamp WHERE ID = '7ed428db-2078-4d08-b4d5-6999ce650856';

INSERT INTO borrows (exemplarid, institutionid, ownerid, borrowdate, returndate, checkstate, checklength)
	VALUES ('7ed428db-2078-4d08-b4d5-6999ce650856', '8bd428db-2078-4d08-b4d5-6999ce650856',
'8ad428db-2078-4d08-b4d5-6999ce650856', '2024-01-01', '2024-06-01', 'waiting_for_arrival', '14:00');
