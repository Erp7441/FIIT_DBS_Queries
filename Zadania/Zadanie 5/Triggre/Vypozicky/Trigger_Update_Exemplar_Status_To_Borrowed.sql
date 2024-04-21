-- Tento trigger aktualizuje stav exemplara na 'borrowed' po vytvoreni noveho zaznamu v borrows
CREATE OR REPLACE FUNCTION update_exemplar_status_to_borrowed()
RETURNS TRIGGER AS $$
DECLARE
	_exemplarid UUID;
BEGIN
	_exemplarid := NEW.exemplarid;
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) != 'in_warehouse' THEN
		RAISE EXCEPTION 'Cannot update exemplar status to borrowed when it is not in warehouse!';
	END IF;
	UPDATE exemplars SET status = 'borrowed' WHERE id = _exemplarid; -- Zmena stavu na 'borrowed'
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger, ktory sa spusti po vlozeni noveho zaznamu do tabulky borrows
CREATE TRIGGER trigger_update_exemplar_status_to_borrowed
AFTER INSERT ON borrows
FOR EACH ROW EXECUTE FUNCTION update_exemplar_status_to_borrowed();