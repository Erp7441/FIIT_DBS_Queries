-- Tento trigger aktualizuje datum poslednej zmeny na aktualny cas pri kazdej zmene zaznamu
CREATE OR REPLACE FUNCTION set_last_change_date()
RETURNS TRIGGER AS $$
BEGIN
	NEW.lastchangedate := NOW(); -- Aktualizacia lastchangedate pri zmene zaznamu
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Trigger, ktory sa spusti pred aktualizaciou zaznamu v tabulke exemplars
CREATE TRIGGER trigger_set_last_change_date_exemplars
BEFORE UPDATE ON exemplars
FOR EACH ROW EXECUTE FUNCTION set_last_change_date();