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