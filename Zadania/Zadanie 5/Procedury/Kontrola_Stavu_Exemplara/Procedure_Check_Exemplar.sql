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