-- Procedura pre na vracajuci sa pozicany exemplar
CREATE OR REPLACE PROCEDURE returning_exemplar(_exemplarid UUID) AS $$
BEGIN
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) != 'borrowed' THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be returning!', _exemplarid;
	END IF;

	UPDATE exemplars SET status = 'returning' WHERE id = _exemplarid;
END; $$ LANGUAGE plpgsql;