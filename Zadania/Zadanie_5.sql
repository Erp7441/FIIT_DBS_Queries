CREATE EXTENSION pgcrypto;

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
-- Datumy
------------------------------------------------------------------------------
-- Tento trigger aktualizuje dátum poslednej zmeny na aktuálny čas pri každej zmene záznamu
CREATE OR REPLACE FUNCTION set_last_change_date()
RETURNS TRIGGER AS $$
BEGIN
	NEW.lastchangedate := NOW(); -- Aktualizácia lastchangedate pri zmene záznamu
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Trigger, ktorý sa spustí pred aktualizáciou záznamu v tabuľke exemplars
CREATE TRIGGER trigger_set_last_change_date_exemplars
BEFORE UPDATE ON exemplars
FOR EACH ROW EXECUTE FUNCTION set_last_change_date();


CREATE OR REPLACE FUNCTION prevent_creation_date_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.creationdate IS DISTINCT FROM NEW.creationdate THEN
    RAISE EXCEPTION 'Zmena hodnoty creationdate je zakázaná.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_column_change
BEFORE UPDATE ON exemplars
FOR EACH ROW
EXECUTE FUNCTION prevent_creation_date_change();



------------------------------------------------------------------------------
-- Vystavene exemplare
------------------------------------------------------------------------------
-- Tento trigger zabezpečí, že dátum vystavenia je skôr ako dátum odstránenia
CREATE OR REPLACE FUNCTION validate_showcased_dates()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.showcaseddate >= NEW.removaldate THEN
		RAISE EXCEPTION 'ShowcasedDate must be earlier than RemovalDate.'; -- Kontrola platnosti dátumov
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger, ktorý sa spustí pred vložením alebo aktualizáciou záznamu v tabuľke showcased_exemplars
CREATE TRIGGER trigger_validate_showcased_dates
BEFORE INSERT OR UPDATE ON showcased_exemplars
FOR EACH ROW EXECUTE FUNCTION validate_showcased_dates();


------------------------------------------------------------------------------
-- Zmazanie exemplara
------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_status_decommissioned()
RETURNS TRIGGER AS $$
BEGIN
	-- Nastavenie stavu exemplára na 'Decommissioned' namiesto jeho zmazania
	NEW.status := 'Decommissioned';
	-- Aktualizácia záznamu s novým stavom
	UPDATE exemplars SET status = NEW.status WHERE id = OLD.id;
	-- Zrušenie operácie DELETE a návrat hodnoty NULL
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_status_decommissioned
BEFORE DELETE ON exemplars
FOR EACH ROW EXECUTE FUNCTION set_status_decommissioned();

------------------------------------------------------------------------------
-- Vypozicky
------------------------------------------------------------------------------
-- Tento trigger zabezpečí, že dátum požičania je skôr ako dátum vrátenia
CREATE OR REPLACE FUNCTION validate_borrow_dates()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.borrowdate >= NEW.returndate THEN
		RAISE EXCEPTION 'BorrowDate must be earlier than ReturnDate.'; -- Kontrola platnosti dátumov
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger, ktorý sa spustí pred vložením alebo aktualizáciou záznamu v tabuľke borrows
CREATE TRIGGER trigger_validate_borrow_dates
BEFORE INSERT OR UPDATE ON borrows
FOR EACH ROW EXECUTE FUNCTION validate_borrow_dates();



-- Tento trigger aktualizuje stav exemplára na 'borrowed' po vytvorení nového záznamu v borrows
CREATE OR REPLACE FUNCTION update_exemplar_status_to_borrowed()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.status = 'in_warehouse' THEN
    	UPDATE exemplars SET status = 'borrowed' WHERE id = NEW.exemplarid; -- Zmena stavu na 'borrowed'
	ELSE
		RAISE EXCEPTION 'Cannot update exemplar status to borrowed when it is not in warehouse!';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger, ktorý sa spustí po vložení nového záznamu do tabuľky borrows
CREATE TRIGGER trigger_update_exemplar_status_to_borrowed
AFTER INSERT ON borrows
FOR EACH ROW EXECUTE FUNCTION update_exemplar_status_to_borrowed();




------------------------------------------------------------------------------
-- Planovanie expozicie
------------------------------------------------------------------------------
-- Procedúra pre naplánovanie novej expozície s možnosťou určenia viacerých miest
CREATE OR REPLACE FUNCTION plan_exposition(_name VARCHAR, _begindate TIMESTAMP, _enddate TIMESTAMP, _zoneids UUID[])
RETURNS VOID AS $$
DECLARE
  _state exposition_status;
  _expositionid UUID;
  _zoneid UUID;
BEGIN
  -- Určenie stavu expozície na základe aktuálneho dátumu a času
  IF _begindate > NOW() AND _enddate > NOW() THEN
    _state := 'preparing';
  ELSIF _begindate <= NOW() AND _enddate > NOW() THEN
    _state := 'ongoing';
  ELSE
    _state := 'completed';
  END IF;

  -- Vloženie novej expozície do tabuľky expositions
  INSERT INTO expositions (name, begindate, enddate, status)
  VALUES (_name, _begindate, _enddate, _state)
  RETURNING id INTO _expositionid;

  -- Prechádzanie zoznamu identifikátorov zón a kontrola dostupnosti pre každú z nich
  FOREACH _zoneid IN ARRAY _zoneids
  LOOP
    -- Kontrola, či sa v danej zóne nekoná iná expozícia v plánovanom časovom období
    IF NOT EXISTS (
      SELECT 1 FROM places
      WHERE zoneid = _zoneid AND (
        startdate < _enddate AND enddate > _begindate
      )
    ) THEN
      -- Priradenie expozície do miesta, ak je to možné
      INSERT INTO places (expositionid, zoneid, startdate, enddate)
      VALUES (_expositionid, _zoneid, _begindate, _enddate);
    ELSE
      RAISE WARNING 'V danej zóne % sa už koná iná expozícia v plánovanom časovom období. Skipujem', _zoneid;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;



------------------------------------------------------------------------------
-- Vkladanie exemplara
------------------------------------------------------------------------------
-- Procedúra pre vkladanie nového exemplára s automatickým nastavením stavu a dátumov
CREATE OR REPLACE PROCEDURE insert_exemplar(_name VARCHAR, _categoryid UUID) AS $$
DECLARE
	new_exemplar_id UUID;
BEGIN
	INSERT INTO exemplars (name, status)
	VALUES (_name, 'in_warehouse')
	RETURNING id INTO new_exemplar_id; -- Vrátenie ID nového exemplára

	INSERT INTO exemplars_categories (exemplarid, categoriesid)
	VALUES (new_exemplar_id, _categoryid); -- Priradenie kategórie
END;
$$ LANGUAGE plpgsql;


-- Procedúra pre presun exemplára do inej zóny
CREATE OR REPLACE PROCEDURE move_exemplar(_exemplarid UUID, _zoneid UUID) AS $$
BEGIN
  UPDATE exemplars SET locationid = _zoneid WHERE id = _exemplarid; -- Aktualizácia polohy exemplára
END;
$$ LANGUAGE plpgsql;



------------------------------------------------------------------------------
-- Prevzatie exemplara
------------------------------------------------------------------------------
-- Procedúra pre prevzatie exemplára z inej inštitúcie a vytvorenie záznamu v borrows
CREATE OR REPLACE PROCEDURE receive_exemplar(_name VARCHAR, _ownerid UUID, _borrowdate TIMESTAMP, _returndate TIMESTAMP,
_checklength TIME, _categoryid UUID) AS $$
DECLARE
  new_exemplar_id UUID;
BEGIN
  -- Vytvorenie nového exemplára
  SELECT insert_exemplar(_name, _categoryid) INTO new_exemplar_id;

  -- Vytvorenie nového záznamu v borrows
  INSERT INTO borrows (exemplarid, ownerid, borrowdate, returndate, checkstate, checklength)
  VALUES (new_exemplar_id, _ownerid, _borrowdate, _returndate, 'waiting_for_arrival', _checklength);
END;
$$ LANGUAGE plpgsql;


------------------------------------------------------------------------------
-- Pozicanie exemplara
------------------------------------------------------------------------------
-- Procedúra pre zapožičanie exemplára inej inštitúcií
CREATE OR REPLACE PROCEDURE lend_exemplar(_exemplarid UUID, _institutionid UUID, _borrowdate TIMESTAMP,
_returndate
TIMESTAMP, _checklength TIME) AS $$
BEGIN
  INSERT INTO borrows (exemplarid, institutionid, borrowdate, returndate, checkstate, checklength)
  VALUES (_exemplarid, _institutionid, _borrowdate, _returndate, 'sending', _checklength);
END;
$$ LANGUAGE plpgsql;


------------------------------------------------------------------------------
-- Vystavenie exemplara
------------------------------------------------------------------------------
-- Procedúra pre vystavenie exemplára v expozícii s kontrolou kolízie dátumov a stavu exemplára
CREATE OR REPLACE PROCEDURE showcase_exemplar(_exemplarid UUID, _expositionid UUID, _showcaseddate TIMESTAMP,
_removaldate TIMESTAMP) AS $$
DECLARE
  new_showcased_exemplar_id UUID;
BEGIN
  -- Kontrola, či exemplár je 'in_warehouse' a nie je už vystavený alebo zapožičaný v danom časovom období
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) = 'in_warehouse' AND NOT EXISTS (
		SELECT 1 FROM showcased_exemplars se
		INNER JOIN expositions_showcased_exemplars ese ON se.id = ese.showcasedexemplarsid
		INNER JOIN exemplars_showcased_exemplars e on se.id = e.showcasedexemplarsid
		WHERE e.exemplarid = _exemplarid
		AND (
			(se.showcaseddate < _removaldate AND se.removaldate > _showcaseddate)
		   	OR
		   	(ese.expositionsid = _expositionid AND se.showcaseddate < _removaldate AND se.removaldate > _showcaseddate)
		)
	) THEN
	-- Vytvorenie nového záznamu v tabuľke showcased_exemplars
	INSERT INTO showcased_exemplars (showcaseddate, removaldate)
	VALUES (_showcaseddate, _removaldate)
	RETURNING id INTO new_showcased_exemplar_id;

	-- Aktualizácia stavu exemplára na 'on_display'
	UPDATE exemplars SET status = 'on_display', lastchangedate = NOW() WHERE id = _exemplarid;

	-- Pridanie záznamu do medzitabuľky exemplars_showcased_exemplars
	INSERT INTO exemplars_showcased_exemplars (exemplarid, showcasedexemplarsid)
	VALUES (_exemplarid, new_showcased_exemplar_id);

	-- Pridanie záznamu do medzitabuľky expositions_showcased_exemplars
	INSERT INTO expositions_showcased_exemplars (expositionsid, showcasedexemplarsid)
	VALUES (_expositionid, new_showcased_exemplar_id);
	ELSE
	RAISE EXCEPTION 'Exemplar % nie je vystavitelny', _exemplarid;
	END IF;
END;
$$ LANGUAGE plpgsql;
