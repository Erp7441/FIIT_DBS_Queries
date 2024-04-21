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