-- Vkladanie do tabuľky institutions
INSERT INTO institutions (name, description, manager) VALUES ('Moja Inštitúcia', 'Popis', 'Manažér');
INSERT INTO institutions (name, description, manager) VALUES ('Inštitúcia 1', 'Popis 1', 'Manažér 1');
INSERT INTO institutions (name, description, manager) VALUES ('Inštitúcia 2', 'Popis 2', 'Manažér 2');

-- Vkladanie do tabuľky categories
INSERT INTO categories (name, description) VALUES ('Kategória 1', 'Popis 1');
INSERT INTO categories (name, description) VALUES ('Kategória 2', 'Popis 2');

-- Vkladanie do tabuľky zones
INSERT INTO zones (name, description) VALUES ('Zóna 1', 'Popis 1');
INSERT INTO zones (name, description) VALUES ('Zóna 2', 'Popis 2');
INSERT INTO zones (name, description) VALUES ('Zóna 3', 'Popis 3');

-- Vkladanie do tabuľky exemplars
CALL insert_exemplar('Exemplár 1', 'b85be437-f92d-4497-83d1-5f013972a44f');
CALL insert_exemplar('Exemplár 2', '74580f8b-b4a3-4972-aed0-c86bbcbe0fc1');

-- Vkladanie do tabuľky expositions
CALL plan_exposition(
	'Expozícia 1',
	'2024-05-01 00:00:00+02',
	'2024-06-01 00:00:00+02',
	ARRAY['4a29ef14-c4bb-41be-abd6-affc909f015c', '5636f93f-92cd-4bc3-8a92-8c793357046a']::UUID[]
);

CALL plan_exposition(
	'Expozícia 2',
	'2024-07-01 00:00:00+02',
	'2024-08-01 00:00:00+02',
	ARRAY['57bf03e3-3b1d-4af8-9ca7-3633812b49f6']::UUID[]
);

-- Vystavenie exemplárov
CALL showcase_exemplar(
	'c3e38d72-2943-4e93-83f8-ed5d4260127c',
	'71bdc25c-9720-4f3c-871f-5437dc18e07b',
	'4a29ef14-c4bb-41be-abd6-affc909f015c',
	'2024-05-10 00:00:00+02',
	'2024-05-20 00:00:00+02'
);

CALL showcase_exemplar(
	'dea789e5-ba32-4685-a0c5-d5af72a3f56b',
	'14748207-c04e-4349-9c4a-d79546a3a451',
	'57bf03e3-3b1d-4af8-9ca7-3633812b49f6',
	'2024-07-10 00:00:00+02',
	'2024-07-20 00:00:00+02'
);

-- Presun exemplárov do zón
CALL move_exemplar(
	'c3e38d72-2943-4e93-83f8-ed5d4260127c',
	'5636f93f-92cd-4bc3-8a92-8c793357046a',
	'2024-05-20 22:00:00.000000 +00:00',
	'2024-05-25 22:00:00.000000 +00:00'
);


-- Fail lebo zone id nepatri do expozicie druheho exemplara
CALL move_exemplar(
	'dea789e5-ba32-4685-a0c5-d5af72a3f56b',
	'5636f93f-92cd-4bc3-8a92-8c793357046a',
	'2024-05-03 00:00:00+02',
	'2024-05-04 00:00:00+02'
);

-- Presun exemplarov do skladu
CALL move_exemplar_to_warehouse('c3e38d72-2943-4e93-83f8-ed5d4260127c');

-- Požičanie exemplárov
CALL lend_exemplar(
	'c3e38d72-2943-4e93-83f8-ed5d4260127c',
	'71bd160b-bb22-4c44-b0ab-b94dd85f11b6',
	'b7e4beef-dfae-4e39-a20c-bc9de3d49afd',
	'2024-09-01 00:00:00+02',
	'2024-10-01 00:00:00+02',
	'01:00:00'
);
CALL returning_exemplar('c3e38d72-2943-4e93-83f8-ed5d4260127c');
CALL move_exemplar_to_warehouse('c3e38d72-2943-4e93-83f8-ed5d4260127c'); -- Exemplar sa vratil spat do skladu
CALL check_exemplar('c3e38d72-2943-4e93-83f8-ed5d4260127c');
CALL complete_exemplar_check('c3e38d72-2943-4e93-83f8-ed5d4260127c');
-- V tomto bode pokial by kontrola zlyhala tak aplikacna logika by zavolala delete ktory by decomol ten exemplar

CALL receive_exemplar(
	'Artefact',
	'b7e4beef-dfae-4e39-a20c-bc9de3d49afd',
	'72157d79-3c3c-48c6-8d0b-ff37a680123d',
	'2024-11-01 00:00:00+02',
	'2024-12-01 00:00:00+02',
	'02:00:00',
	'74580f8b-b4a3-4972-aed0-c86bbcbe0fc1'
)