CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE check_state AS ENUM(
    'waiting_for_arrival',
    'checking',
    'check_completed'
);

CREATE TYPE exemplar_status AS ENUM(
    'borrowed',
    'on_display',
    'in_warehouse',
    'returning',
    'sending',
    'controlling',
    'decommissioned'
);

CREATE TYPE exposition_status AS ENUM('preparing', 'ongoing', 'completed');

CREATE TABLE
    places (
        expositionid UUID NOT NULL,
        zoneid UUID NOT NULL,
        startdate TIMESTAMP WITH TIME ZONE NOT NULL,
        enddate TIMESTAMP WITH TIME ZONE NOT NULL
    );

CREATE TABLE
    expositions (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        NAME VARCHAR(100) NOT NULL,
        begindate TIMESTAMP WITH TIME ZONE NOT NULL,
        enddate TIMESTAMP WITH TIME ZONE NOT NULL,
        status exposition_status NOT NULL
    );

CREATE TABLE
    showcased_exemplars (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        showcaseddate TIMESTAMP WITH TIME ZONE NOT NULL,
        removaldate TIMESTAMP WITH TIME ZONE NOT NULL
    );

CREATE TABLE
    zones (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        NAME VARCHAR(100) NOT NULL,
        description VARCHAR(255)
    );

CREATE TABLE
    borrows (
        exemplarid UUID NOT NULL,
        institutionid UUID NOT NULL,
        ownerid UUID NOT NULL,
        borrowdate TIMESTAMP WITH TIME ZONE NOT NULL,
        returndate TIMESTAMP WITH TIME ZONE NOT NULL,
        checkstate check_state NOT NULL,
        checklength TIME NOT NULL
    );

CREATE TABLE
    exemplars (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        locationid UUID,
        NAME VARCHAR(100) NOT NULL,
        status exemplar_status NOT NULL,
        creationdate TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        lastchangedate TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );

CREATE TABLE
    categories (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        NAME VARCHAR(100) NOT NULL,
        description VARCHAR(255)
    );

CREATE TABLE
    institutions (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        NAME VARCHAR(100) NOT NULL,
        description VARCHAR(255),
        manager VARCHAR(50) NOT NULL
    );

CREATE TABLE
    exemplars_showcased_exemplars (
        showcasedexemplarsid UUID NOT NULL,
        exemplarid UUID NOT NULL
    );

CREATE TABLE
    expositions_showcased_exemplars (
        showcasedexemplarsid UUID NOT NULL,
        expositionsid UUID NOT NULL
    );

CREATE TABLE
    exemplars_categories (
        exemplarid UUID NOT NULL,
        categoriesid UUID NOT NULL
    );

ALTER TABLE expositions
ADD PRIMARY KEY (id);

ALTER TABLE places
ADD CONSTRAINT fkplaces1 FOREIGN KEY (expositionid) REFERENCES expositions;

ALTER TABLE showcased_exemplars
ADD PRIMARY KEY (id);

ALTER TABLE zones
ADD PRIMARY KEY (id);

ALTER TABLE places
ADD CONSTRAINT fkplaces2 FOREIGN KEY (zoneid) REFERENCES zones;

ALTER TABLE exemplars
ADD PRIMARY KEY (id);

ALTER TABLE exemplars
ADD CONSTRAINT fkexemplar1 FOREIGN KEY (locationid) REFERENCES zones;

ALTER TABLE borrows
ADD CONSTRAINT fkborrows1 FOREIGN KEY (exemplarid) REFERENCES exemplars;

ALTER TABLE categories
ADD PRIMARY KEY (id);

ALTER TABLE institutions
ADD PRIMARY KEY (id);

ALTER TABLE borrows
ADD CONSTRAINT fkborrows2 FOREIGN KEY (institutionid) REFERENCES institutions;

ALTER TABLE borrows
ADD CONSTRAINT fkborrows3 FOREIGN KEY (ownerid) REFERENCES institutions;

ALTER TABLE exemplars_showcased_exemplars
ADD PRIMARY KEY (showcasedexemplarsid, exemplarid);

ALTER TABLE exemplars_showcased_exemplars
ADD CONSTRAINT fkexemplars_showcased_exemplars1 FOREIGN KEY (exemplarid) REFERENCES exemplars;

ALTER TABLE exemplars_showcased_exemplars
ADD CONSTRAINT fkexemplars_showcased_exemplars2 FOREIGN KEY (showcasedexemplarsid) REFERENCES showcased_exemplars;

ALTER TABLE expositions_showcased_exemplars
ADD PRIMARY KEY (showcasedexemplarsid, expositionsid);

ALTER TABLE expositions_showcased_exemplars
ADD CONSTRAINT fkexposition1 FOREIGN KEY (expositionsid) REFERENCES expositions;

ALTER TABLE expositions_showcased_exemplars
ADD CONSTRAINT fkexposition2 FOREIGN KEY (showcasedexemplarsid) REFERENCES showcased_exemplars;

ALTER TABLE exemplars_categories
ADD PRIMARY KEY (exemplarid, categoriesid);

ALTER TABLE exemplars_categories
ADD CONSTRAINT fkexemplars_categories1 FOREIGN KEY (exemplarid) REFERENCES exemplars;

ALTER TABLE exemplars_categories
ADD CONSTRAINT fkexemplars_categories2 FOREIGN KEY (categoriesid) REFERENCES categories;


------------------------------------------------------------------------------
--
-- Triggre
--
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- Datumy
------------------------------------------------------------------------------
-- Tento trigger aktualizuje datum poslednej zmeny na aktualny cas pri kazdej zmene zaznamu
CREATE OR REPLACE FUNCTION set_last_change_date()
RETURNS TRIGGER AS $$
BEGIN
	NEW.lastchangedate := NOW(); -- Aktualizacia lastchangedate pri zmene zaznamu
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Trigger, ktory sa spusti pred aktualizaciou zaznamu v tabulke exemplars
CREATE TRIGGER trigger_set_last_change_date_exemplars
BEFORE UPDATE ON exemplars
FOR EACH ROW EXECUTE FUNCTION set_last_change_date();


CREATE OR REPLACE FUNCTION prevent_creation_date_change()
RETURNS TRIGGER AS $$
BEGIN
	IF OLD.creationdate IS DISTINCT FROM NEW.creationdate THEN
		RAISE EXCEPTION 'Change of CreationDate is not allowed!';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_column_change
BEFORE UPDATE ON exemplars
FOR EACH ROW EXECUTE FUNCTION prevent_creation_date_change();

-- Tento trigger zabezpeci, ze datum vystavenia je skor ako datum odstranenia
CREATE OR REPLACE FUNCTION validate_showcased_dates()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.showcaseddate >= NEW.removaldate THEN
		RAISE EXCEPTION 'ShowcasedDate must be earlier than RemovalDate.'; -- Kontrola platnosti datumov
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger, ktory sa spusti pred vlozenim alebo aktualizaciou zaznamu v tabulke showcased_exemplars
CREATE TRIGGER trigger_validate_showcased_dates
BEFORE INSERT OR UPDATE ON showcased_exemplars
FOR EACH ROW EXECUTE FUNCTION validate_showcased_dates();


-- Tento trigger zabezpeci, ze datum pozicania je skor ako datum vratenia
CREATE OR REPLACE FUNCTION validate_borrow_dates()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.borrowdate >= NEW.returndate THEN
		RAISE EXCEPTION 'BorrowDate must be earlier than ReturnDate.'; -- Kontrola platnosti datumov
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger, ktory sa spusti pred vlozenim alebo aktualizaciou zaznamu v tabulke borrows
CREATE TRIGGER trigger_validate_borrow_dates
BEFORE INSERT OR UPDATE ON borrows
FOR EACH ROW EXECUTE FUNCTION validate_borrow_dates();


------------------------------------------------------------------------------
-- Zmazanie exemplara
------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_status_decommissioned()
RETURNS TRIGGER AS $$
BEGIN
	IF OLD.status = 'decommissioned' THEN
		RAISE INFO 'Exemplar with ID % is already decommissioned.', OLD.id;
	ELSEIF OLD.status != 'in_warehouse' THEN
		RAISE EXCEPTION 'Cannot decommission exemplar with ID % because it is not in warehouse.', OLD.id;
	ELSE
		-- Nastavenie stavu exemplara na 'decommissioned' namiesto jeho zmazania
		NEW.status := 'decommissioned';
		-- Aktualizacia zaznamu s novym stavom
		UPDATE exemplars SET status = NEW.status WHERE id = OLD.id;
		-- Zrusenie operacie DELETE a navrat hodnoty NULL
		RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_status_decommissioned
BEFORE DELETE ON exemplars
FOR EACH ROW EXECUTE FUNCTION set_status_decommissioned();


CREATE OR REPLACE FUNCTION prevent_decommission_status_change()
RETURNS TRIGGER AS $$
BEGIN
	IF OLD.status = 'decommissioned' AND OLD.status IS DISTINCT FROM NEW.status THEN
		RAISE EXCEPTION 'Changing decommissioned exemplar % is not allowed. Please create a new entry.', OLD.id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_decommission_status_change
BEFORE UPDATE ON exemplars
FOR EACH ROW EXECUTE FUNCTION prevent_decommission_status_change();


------------------------------------------------------------------------------
-- Vypozicky
------------------------------------------------------------------------------



-- Tento trigger aktualizuje stav exemplara na 'borrowed' po vytvoreni noveho zaznamu v borrows
CREATE OR REPLACE FUNCTION update_exemplar_status_to_borrowed()
RETURNS TRIGGER AS $$
DECLARE
	_exemplarid UUID;
BEGIN
	_exemplarid := NEW.exemplarid;
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) != 'in_warehouse' THEN
		RAISE EXCEPTION 'Cannot update exemplar status to borrowed when it is not in warehouse!';
	END IF;
	UPDATE exemplars SET status = 'borrowed' WHERE id = _exemplarid; -- Zmena stavu na 'borrowed'
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger, ktory sa spusti po vlozeni noveho zaznamu do tabulky borrows
CREATE TRIGGER trigger_update_exemplar_status_to_borrowed
AFTER INSERT ON borrows
FOR EACH ROW EXECUTE FUNCTION update_exemplar_status_to_borrowed();


------------------------------------------------------------------------------
--
-- Procedury
---
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- Planovanie expozicie
------------------------------------------------------------------------------
-- Procedura pre naplanovanie novej expozicie s moznostou urcenia viacerych miest
CREATE OR REPLACE PROCEDURE plan_exposition(_name VARCHAR, _begindate TIMESTAMP WITH TIME ZONE, _enddate TIMESTAMP
WITH TIME ZONE, _zoneids UUID[]) AS $$
DECLARE
	_state exposition_status;
	_expositionid UUID;
	_zoneid UUID;
BEGIN
	-- Urcenie stavu expozicie na zaklade aktualneho datumu a casu
	IF _begindate > NOW() AND _enddate > NOW() THEN
		_state := 'preparing';
	ELSIF _begindate <= NOW() AND _enddate > NOW() THEN
		_state := 'ongoing';
	ELSE
		_state := 'completed';
	END IF;

	-- Vlozenie novej expozicie do tabulky expositions
	INSERT INTO expositions (name, begindate, enddate, status)
	VALUES (_name, _begindate, _enddate, _state)
	RETURNING id INTO _expositionid;

	-- Prechadzanie zoznamu identifikatorov zon a kontrola dostupnosti pre kazdu z nich
	FOREACH _zoneid IN ARRAY _zoneids
	LOOP
		-- Kontrola, ci sa v danej zone nekona ina expozicia v planovanom casovom obdobi
		IF NOT EXISTS (
			SELECT 1 FROM places
			WHERE zoneid = _zoneid AND (
			startdate <= _enddate AND enddate >= _begindate
			)
		) THEN
			-- Priradenie expozicie do miesta, ak je to mozne
			INSERT INTO places (expositionid, zoneid, startdate, enddate)
			VALUES (_expositionid, _zoneid, _begindate, _enddate);
		ELSE
			RAISE WARNING 'In a given % zone, another exposure is already taking place in the planned time period. Skipping...', _zoneid;
		END IF;
	END LOOP;
END;
$$ LANGUAGE plpgsql;



------------------------------------------------------------------------------
-- Vkladanie exemplara
------------------------------------------------------------------------------
-- Procedura pre vkladanie noveho exemplara s automatickym nastavenim stavu a datumov
CREATE OR REPLACE PROCEDURE insert_exemplar(_name VARCHAR, _categoryid UUID) AS $$
DECLARE
	new_exemplar_id UUID;
BEGIN
	INSERT INTO exemplars (name, status)
	VALUES (_name, 'in_warehouse')
	RETURNING id INTO new_exemplar_id; -- Vratenie ID noveho exemplara

	INSERT INTO exemplars_categories (exemplarid, categoriesid)
	VALUES (new_exemplar_id, _categoryid); -- Priradenie kategorie
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- Presuvanie exemplara
------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE move_exemplar(_exemplarid UUID, _zoneid UUID, _begindate TIMESTAMP WITH TIME ZONE,
_enddate TIMESTAMP WITH TIME ZONE)
AS $$
DECLARE
	_exemplar_status VARCHAR;
	_zone_exists BOOLEAN;
	_exemplar_exists BOOLEAN;
	_exemplar_current_location UUID;
	_exposition_id UUID;
BEGIN
	-- Kontrola, ci exemplar a zóna existujú
	SELECT EXISTS(SELECT id FROM zones WHERE id = _zoneid) INTO _zone_exists;
	SELECT EXISTS(SELECT id FROM exemplars WHERE id = _exemplarid) INTO _exemplar_exists;
	IF NOT _zone_exists THEN
		RAISE EXCEPTION 'Zone with ID % does not exist!', _zoneid;
	END IF;
	IF NOT _exemplar_exists THEN
		RAISE EXCEPTION 'Exemplar with ID % does not exist!', _exemplarid;
	END IF;

	-- Kontrola, stavu exemplara
	SELECT status INTO _exemplar_status FROM exemplars WHERE id = _exemplarid;
	IF _exemplar_status != 'on_display' THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be moved! It is not on display.', _exemplarid;
	END IF;

	-- Kontrola, ci exemplar už nie je v danej zóne
	SELECT locationid INTO _exemplar_current_location FROM exemplars WHERE id = _exemplarid;
	IF _exemplar_current_location = _zoneid THEN
		RAISE INFO 'Exemplar with ID % is already in zone %.', _exemplarid, _zoneid;
		RETURN;
	END IF;

	-- Kontrola, ci zóna patrí k expozícii
	SELECT e.id INTO _exposition_id FROM expositions e
		JOIN places p ON e.id = p.expositionid
		JOIN exemplars e2 ON p.zoneid = e2.locationid
		WHERE p.zoneid = _zoneid AND p.enddate >= NOW() AND e2.id = _exemplarid;

	IF _exposition_id IS NULL THEN
		RAISE EXCEPTION 'Zone with ID % does not belong to an exposition!', _zoneid;
	END IF;

	-- Aktualizacia polohy exemplara
	UPDATE exemplars SET locationid = _zoneid WHERE id = _exemplarid;
END;
$$ LANGUAGE plpgsql;


-- Procedura pre presun exemplara do skladu
CREATE OR REPLACE PROCEDURE move_exemplar_to_warehouse(_exemplarid UUID) AS $$
BEGIN
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) NOT IN ('on_display', 'controlling', 'returning',
	'borrowed') OR ((
		SELECT removaldate FROM showcased_exemplars
		INNER JOIN expositions_showcased_exemplars ON showcased_exemplars.id = expositions_showcased_exemplars.showcasedexemplarsid
		WHERE expositions_showcased_exemplars.showcasedexemplarsid = _exemplarid
	) > NOW())
	THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be moved to warehouse!', _exemplarid;
	END IF;

	-- Aktualizacia stavu exemplara na 'in_warehouse' a location_id na NULL
	UPDATE exemplars
	SET status = 'in_warehouse',
		locationid = NULL,
		lastchangedate = NOW()
	WHERE id = _exemplarid;
END;
$$ LANGUAGE plpgsql;




------------------------------------------------------------------------------
-- Prevzatie exemplara
------------------------------------------------------------------------------
-- Procedura pre prevzatie exemplara z inej institucie a vytvorenie zaznamu v borrows
CREATE OR REPLACE PROCEDURE receive_exemplar(_name VARCHAR, _institutionid UUID, _ownerid UUID, _borrowdate TIMESTAMP
 WITH TIME ZONE, _returndate TIMESTAMP WITH TIME ZONE, _checklength TIME, _categoryid UUID) AS $$
DECLARE
	new_exemplar_id UUID;
BEGIN
	-- Vytvorenie noveho exemplara
	INSERT INTO exemplars (name, status)
	VALUES (_name, 'in_warehouse')
	RETURNING id INTO new_exemplar_id; -- Vratenie ID noveho exemplara

	INSERT INTO exemplars_categories (exemplarid, categoriesid)
	VALUES (new_exemplar_id, _categoryid); -- Priradenie kategorie

	-- Vytvorenie noveho zaznamu v borrows
	INSERT INTO borrows (exemplarid, institutionid, ownerid, borrowdate, returndate, checkstate, checklength)
	VALUES (new_exemplar_id, _institutionid, _ownerid, _borrowdate, _returndate, 'waiting_for_arrival', _checklength);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE return_borrowed_exemplar(_exemplarid UUID) AS $$
DECLARE
	borrowed_exemplar_id BOOLEAN;
BEGIN
	SELECT EXISTS(
		SELECT exemplarid
		FROM borrows b
		WHERE b.exemplarid = _exemplarid AND returndate >= NOW()
	) INTO borrowed_exemplar_id;

	IF NOT borrowed_exemplar_id THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be returned!', _exemplarid;
	END IF;
	UPDATE exemplars SET status = 'returning' WHERE id = _exemplarid;
	-- Ked bude exemplar uspesne vrateny aplikacna vrstva zavola delete na exemplar a tym ho decommisione.
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- Pozicanie exemplara
------------------------------------------------------------------------------
-- Procedura pre zapozicanie exemplara inej institucii
CREATE OR REPLACE PROCEDURE lend_exemplar(_exemplarid UUID, _institutionid UUID, _ownerid UUID, _borrowdate TIMESTAMP
 WITH TIME ZONE, _returndate TIMESTAMP WITH TIME ZONE, _checklength TIME) AS $$
BEGIN
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) != 'in_warehouse' THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be lend!', _exemplarid;
	END IF;

	INSERT INTO borrows (exemplarid, institutionid, ownerid, borrowdate, returndate, checkstate, checklength)
		VALUES (_exemplarid, _institutionid, _ownerid, _borrowdate, _returndate, 'waiting_for_arrival', _checklength);
END;
$$ LANGUAGE plpgsql;

-- Procedura pre na vracajuci sa pozicany exemplar
CREATE OR REPLACE PROCEDURE returning_exemplar(_exemplarid UUID) AS $$
BEGIN
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) != 'borrowed' THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be returning!', _exemplarid;
	END IF;

	UPDATE exemplars SET status = 'returning' WHERE id = _exemplarid;
END; $$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- Vystavenie exemplara
------------------------------------------------------------------------------
-- Procedura pre vystavenie exemplara v expozicii s kontrolou kolizie datumov a stavu exemplara
CREATE OR REPLACE PROCEDURE showcase_exemplar(_exemplarid UUID, _expositionid UUID, _zoneid UUID, _showcaseddate
TIMESTAMP WITH TIME ZONE, _removaldate TIMESTAMP WITH TIME ZONE) AS $$
DECLARE
	new_showcased_exemplar_id UUID;
	new_zone_id UUID;
	exposition_start_date TIMESTAMP WITH TIME ZONE;
	exposition_end_date TIMESTAMP WITH TIME ZONE;
	is_showcased BOOLEAN;
	zone_belongs_to_exposition BOOLEAN;
BEGIN
	SELECT EXISTS(
		SELECT e.id FROM expositions e
		JOIN places p ON e.id = p.expositionid
		WHERE p.zoneid = _zoneid AND e.id = _expositionid
	) INTO zone_belongs_to_exposition;

	IF NOT zone_belongs_to_exposition THEN
		RAISE EXCEPTION 'Zone with ID % does not belong to exposition with ID %!', _zoneid, _expositionid;
	END IF;


	new_zone_id := (SELECT zoneid FROM places WHERE expositionid = _expositionid AND zoneid = _zoneid);
	exposition_start_date := (SELECT startdate FROM places WHERE expositionid = _expositionid AND zoneid = _zoneid);
	exposition_end_date := (SELECT enddate FROM places WHERE expositionid = _expositionid AND zoneid = _zoneid);
	SELECT EXISTS (
		SELECT 1 FROM showcased_exemplars se
		INNER JOIN expositions_showcased_exemplars ese ON se.id = ese.showcasedexemplarsid
		INNER JOIN exemplars_showcased_exemplars e on se.id = e.showcasedexemplarsid
		WHERE e.exemplarid = _exemplarid
		AND (
			(se.showcaseddate < _removaldate AND se.removaldate > _showcaseddate)
			OR
			(ese.expositionsid = _expositionid AND se.showcaseddate < _removaldate AND se.removaldate > _showcaseddate)
		)
	) INTO is_showcased;

	-- Kontrola, ci exemplar je 'in_warehouse' a nie je uz vystaveny alebo zapozicany v danom casovom obdobi
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) = 'in_warehouse'
		AND new_zone_id IS NOT NULL
		AND (exposition_start_date <= _showcaseddate AND exposition_end_date >= _removaldate)
		AND NOT is_showcased
	THEN
		-- Vytvorenie noveho zaznamu v tabulke showcased_exemplars
		INSERT INTO showcased_exemplars (showcaseddate, removaldate)
		VALUES (_showcaseddate, _removaldate)
		RETURNING id INTO new_showcased_exemplar_id;

		-- Aktualizacia stavu exemplara na 'on_display'
		UPDATE exemplars SET status = 'on_display', lastchangedate = NOW(), locationid = new_zone_id WHERE id = _exemplarid;

		-- Pridanie zaznamu do medzitabulky exemplars_showcased_exemplars
		INSERT INTO exemplars_showcased_exemplars (exemplarid, showcasedexemplarsid)
		VALUES (_exemplarid, new_showcased_exemplar_id);

		-- Pridanie zaznamu do medzitabulky expositions_showcased_exemplars
		INSERT INTO expositions_showcased_exemplars (expositionsid, showcasedexemplarsid)
		VALUES (_expositionid, new_showcased_exemplar_id);
	ELSE
		RAISE EXCEPTION 'Exemplar % is not showcaseable!', _exemplarid;
	END IF;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- Kontrola stavu exemplara
------------------------------------------------------------------------------
-- Checkovanie stavu exemplara
-- Z aplikacnej logiky by sa malo zavolat pred odoslanim a po prijati exemplara.
-- Dlzka a aktualizacia stavu kontroly by mala byt implementovana v aplikacnej logike ako time based event.
CREATE OR REPLACE PROCEDURE check_exemplar(_exemplarid UUID) AS $$
DECLARE
BEGIN
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) != 'in_warehouse' THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be checked!', _exemplarid;
	END IF;

	UPDATE exemplars SET status = 'controlling' WHERE id = _exemplarid;

	UPDATE borrows SET checkstate = 'checking'
	WHERE exemplarid = _exemplarid AND checkstate NOT IN ('check_completed', 'checking');

END; $$ LANGUAGE plpgsql;

-- Dokoncenie kontroly
CREATE OR REPLACE PROCEDURE complete_exemplar_check(_exemplarid UUID) AS $$
DECLARE
BEGIN
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) != 'controlling' THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be checked!', _exemplarid;
	END IF;

	UPDATE borrows SET checkstate = 'check_completed'
	WHERE exemplarid = _exemplarid AND checkstate = 'checking';

	CALL move_exemplar_to_warehouse(_exemplarid);

END; $$ LANGUAGE plpgsql;