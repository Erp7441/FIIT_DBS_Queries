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