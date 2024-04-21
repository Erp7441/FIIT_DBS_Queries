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
