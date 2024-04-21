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