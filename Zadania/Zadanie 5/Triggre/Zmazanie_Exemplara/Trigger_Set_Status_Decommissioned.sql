CREATE OR REPLACE FUNCTION set_status_decommissioned()
RETURNS TRIGGER AS $$
BEGIN
	IF OLD.status = 'decommissioned' THEN
		RAISE INFO 'Exemplar with ID % is already decommissioned.', OLD.id;
	ELSEIF OLD.status != 'in_warehouse' THEN
		RAISE EXCEPTION 'Cannot decommission exemplar with ID % because it is not in warehouse.', OLD.id;
	ELSE
		-- Nastavenie stavu exemplara na 'decommissioned' namiesto jeho zmazania
		NEW.status := 'decommissioned';
		-- Aktualizacia zaznamu s novym stavom
		UPDATE exemplars SET status = NEW.status WHERE id = OLD.id;
		-- Zrusenie operacie DELETE a navrat hodnoty NULL
		RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_status_decommissioned
BEFORE DELETE ON exemplars
FOR EACH ROW EXECUTE FUNCTION set_status_decommissioned();