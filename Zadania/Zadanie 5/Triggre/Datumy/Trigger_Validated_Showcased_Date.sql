-- Tento trigger zabezpeci, ze datum vystavenia je skor ako datum odstranenia
CREATE OR REPLACE FUNCTION validate_showcased_dates()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.showcaseddate >= NEW.removaldate THEN
		RAISE EXCEPTION 'ShowcasedDate must be earlier than RemovalDate.'; -- Kontrola platnosti datumov
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger, ktory sa spusti pred vlozenim alebo aktualizaciou zaznamu v tabulke showcased_exemplars
CREATE TRIGGER trigger_validate_showcased_dates
BEFORE INSERT OR UPDATE ON showcased_exemplars
FOR EACH ROW EXECUTE FUNCTION validate_showcased_dates();
