CREATE OR REPLACE FUNCTION prevent_creation_date_change()
RETURNS TRIGGER AS $$
BEGIN
	IF OLD.creationdate IS DISTINCT FROM NEW.creationdate THEN
		RAISE EXCEPTION 'Change of CreationDate is not allowed!';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_column_change
BEFORE UPDATE ON exemplars
FOR EACH ROW EXECUTE FUNCTION prevent_creation_date_change();