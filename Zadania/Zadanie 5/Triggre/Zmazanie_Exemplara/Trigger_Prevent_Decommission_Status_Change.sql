CREATE OR REPLACE FUNCTION prevent_decommission_status_change()
RETURNS TRIGGER AS $$
BEGIN
	IF OLD.status = 'decommissioned' AND OLD.status IS DISTINCT FROM NEW.status THEN
		RAISE EXCEPTION 'Changing decommissioned exemplar % is not allowed. Please create a new entry.', OLD.id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_decommission_status_change
BEFORE UPDATE ON exemplars
FOR EACH ROW EXECUTE FUNCTION prevent_decommission_status_change();
