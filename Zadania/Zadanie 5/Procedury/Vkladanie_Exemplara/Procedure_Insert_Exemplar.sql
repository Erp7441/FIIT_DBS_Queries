-- Procedura pre vkladanie noveho exemplara s automatickym nastavenim stavu a datumov
CREATE OR REPLACE PROCEDURE insert_exemplar(_name VARCHAR, _categoryid UUID) AS $$
DECLARE
	new_exemplar_id UUID;
BEGIN
	INSERT INTO exemplars (name, status)
	VALUES (_name, 'in_warehouse')
	RETURNING id INTO new_exemplar_id; -- Vratenie ID noveho exemplara

	INSERT INTO exemplars_categories (exemplarid, categoriesid)
	VALUES (new_exemplar_id, _categoryid); -- Priradenie kategorie
END;
$$ LANGUAGE plpgsql;