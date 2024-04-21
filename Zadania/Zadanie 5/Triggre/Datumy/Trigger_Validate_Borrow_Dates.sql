-- Tento trigger zabezpeci, ze datum pozicania je skor ako datum vratenia
CREATE OR REPLACE FUNCTION validate_borrow_dates()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.borrowdate >= NEW.returndate THEN
		RAISE EXCEPTION 'BorrowDate must be earlier than ReturnDate.'; -- Kontrola platnosti datumov
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger, ktory sa spusti pred vlozenim alebo aktualizaciou zaznamu v tabulke borrows
CREATE TRIGGER trigger_validate_borrow_dates
BEFORE INSERT OR UPDATE ON borrows
FOR EACH ROW EXECUTE FUNCTION validate_borrow_dates();