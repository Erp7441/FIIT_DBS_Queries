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