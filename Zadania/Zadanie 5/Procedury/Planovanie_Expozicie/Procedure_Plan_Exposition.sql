-- Procedura pre naplanovanie novej expozicie s moznostou urcenia viacerych miest
CREATE OR REPLACE PROCEDURE plan_exposition(_name VARCHAR, _begindate TIMESTAMP WITH TIME ZONE, _enddate TIMESTAMP
WITH TIME ZONE, _zoneids UUID[]) AS $$
DECLARE
	_state exposition_status;
	_expositionid UUID;
	_zoneid UUID;
BEGIN
	-- Urcenie stavu expozicie na zaklade aktualneho datumu a casu
	IF _begindate > NOW() AND _enddate > NOW() THEN
		_state := 'preparing';
	ELSIF _begindate <= NOW() AND _enddate > NOW() THEN
		_state := 'ongoing';
	ELSE
		_state := 'completed';
	END IF;

	-- Vlozenie novej expozicie do tabulky expositions
	INSERT INTO expositions (name, begindate, enddate, status)
	VALUES (_name, _begindate, _enddate, _state)
	RETURNING id INTO _expositionid;

	-- Prechadzanie zoznamu identifikatorov zon a kontrola dostupnosti pre kazdu z nich
	FOREACH _zoneid IN ARRAY _zoneids
	LOOP
		-- Kontrola, ci sa v danej zone nekona ina expozicia v planovanom casovom obdobi
		IF NOT EXISTS (
			SELECT 1 FROM places
			WHERE zoneid = _zoneid AND (
			startdate <= _enddate AND enddate >= _begindate
			)
		) THEN
			-- Priradenie expozicie do miesta, ak je to mozne
			INSERT INTO places (expositionid, zoneid, startdate, enddate)
			VALUES (_expositionid, _zoneid, _begindate, _enddate);
		ELSE
			RAISE WARNING 'In a given % zone, another exposure is already taking place in the planned time period. Skipping...', _zoneid;
		END IF;
	END LOOP;
END;
$$ LANGUAGE plpgsql;