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