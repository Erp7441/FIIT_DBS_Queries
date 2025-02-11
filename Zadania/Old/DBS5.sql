toc.dat                                                                                             0000600 0004000 0002000 00000105163 14611227023 0014443 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP   '                    |        	   zadanie_4    16.2 (Debian 16.2-1.pgdg120+2)    16.2 L    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false         �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false         �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false         �           1262    189662 	   zadanie_4    DATABASE     t   CREATE DATABASE zadanie_4 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';
    DROP DATABASE zadanie_4;
                postgres    false                     2615    192838    public    SCHEMA     2   -- *not* creating schema, since initdb creates it
 2   -- *not* dropping schema, since initdb creates it
                postgres    false         �           0    0    SCHEMA public    COMMENT         COMMENT ON SCHEMA public IS '';
                   postgres    false    6         �           0    0    SCHEMA public    ACL     +   REVOKE USAGE ON SCHEMA public FROM PUBLIC;
                   postgres    false    6                     3079    192839    pgcrypto 	   EXTENSION     <   CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
    DROP EXTENSION pgcrypto;
                   false    6         �           0    0    EXTENSION pgcrypto    COMMENT     <   COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
                        false    2         �           1247    192877    check_state    TYPE     m   CREATE TYPE public.check_state AS ENUM (
    'waiting_for_arrival',
    'checking',
    'check_completed'
);
    DROP TYPE public.check_state;
       public          postgres    false    6         �           1247    192884    exemplar_status    TYPE     �   CREATE TYPE public.exemplar_status AS ENUM (
    'borrowed',
    'on_display',
    'in_warehouse',
    'returning',
    'sending',
    'controlling',
    'decommissioned'
);
 "   DROP TYPE public.exemplar_status;
       public          postgres    false    6         �           1247    192900    exposition_status    TYPE     b   CREATE TYPE public.exposition_status AS ENUM (
    'preparing',
    'ongoing',
    'completed'
);
 $   DROP TYPE public.exposition_status;
       public          postgres    false    6                    1255    192907 (   insert_exemplar(character varying, uuid) 	   PROCEDURE     �  CREATE PROCEDURE public.insert_exemplar(IN _name character varying, IN _categoryid uuid)
    LANGUAGE plpgsql
    AS $$
DECLARE
	new_exemplar_id UUID;
BEGIN
	INSERT INTO exemplars (name, status)
	VALUES (_name, 'in_warehouse')
	RETURNING id INTO new_exemplar_id; -- Vratenie ID noveho exemplara

	INSERT INTO exemplars_categories (exemplarid, categoriesid)
	VALUES (new_exemplar_id, _categoryid); -- Priradenie kategorie
END;
$$;
 X   DROP PROCEDURE public.insert_exemplar(IN _name character varying, IN _categoryid uuid);
       public          postgres    false    6                    1255    192908 k   lend_exemplar(uuid, uuid, uuid, timestamp with time zone, timestamp with time zone, time without time zone) 	   PROCEDURE     }  CREATE PROCEDURE public.lend_exemplar(IN _exemplarid uuid, IN _institutionid uuid, IN _ownerid uuid, IN _borrowdate timestamp with time zone, IN _returndate timestamp with time zone, IN _checklength time without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) != 'in_warehouse' THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be lend!', _exemplarid;
	END IF;

	INSERT INTO borrows (exemplarid, institutionid, ownerid, borrowdate, returndate, checkstate, checklength)
		VALUES (_exemplarid, _institutionid, _ownerid, _borrowdate, _returndate, 'sending', _checklength);
END;
$$;
 �   DROP PROCEDURE public.lend_exemplar(IN _exemplarid uuid, IN _institutionid uuid, IN _ownerid uuid, IN _borrowdate timestamp with time zone, IN _returndate timestamp with time zone, IN _checklength time without time zone);
       public          postgres    false    6                    1255    192909 M   move_exemplar(uuid, uuid, timestamp with time zone, timestamp with time zone) 	   PROCEDURE     �  CREATE PROCEDURE public.move_exemplar(IN _exemplarid uuid, IN _zoneid uuid, IN _begindate timestamp with time zone, IN _enddate timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
DECLARE
	_exemplar_status VARCHAR;
	_zone_exists BOOLEAN;
	_exemplar_exists BOOLEAN;
	_exemplar_current_location UUID;
	_exposition_id UUID;
BEGIN
	-- Kontrola, ci exemplar a zóna existujú
	SELECT EXISTS(SELECT id FROM zones WHERE id = _zoneid) INTO _zone_exists;
	SELECT EXISTS(SELECT id FROM exemplars WHERE id = _exemplarid) INTO _exemplar_exists;
	IF NOT _zone_exists THEN
		RAISE EXCEPTION 'Zone with ID % does not exist!', _zoneid;
	END IF;
	IF NOT _exemplar_exists THEN
		RAISE EXCEPTION 'Exemplar with ID % does not exist!', _exemplarid;
	END IF;

	-- Kontrola, stavu exemplara
	SELECT status INTO _exemplar_status FROM exemplars WHERE id = _exemplarid;
	IF _exemplar_status != 'on_display' THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be moved! It is not on display.', _exemplarid;
	END IF;

	-- Kontrola, ci exemplar už nie je v danej zóne
	SELECT locationid INTO _exemplar_current_location FROM exemplars WHERE id = _exemplarid;
	IF _exemplar_current_location = _zoneid THEN
		RAISE INFO 'Exemplar with ID % is already in zone %.', _exemplarid, _zoneid;
		RETURN;
	END IF;

	-- Kontrola, ci zóna patrí k expozícii
	SELECT e.id INTO _exposition_id FROM expositions e
		JOIN places p ON e.id = p.expositionid
		JOIN exemplars e2 ON p.zoneid = e2.locationid
		WHERE p.zoneid = _zoneid AND p.enddate >= NOW() AND e2.id = _exemplarid;

	IF _exposition_id IS NULL THEN
		RAISE EXCEPTION 'Zone with ID % does not belong to an exposition!', _zoneid;
	END IF;

	-- Aktualizacia polohy exemplara
	UPDATE exemplars SET locationid = _zoneid WHERE id = _exemplarid;
END;
$$;
 �   DROP PROCEDURE public.move_exemplar(IN _exemplarid uuid, IN _zoneid uuid, IN _begindate timestamp with time zone, IN _enddate timestamp with time zone);
       public          postgres    false    6                    1255    192910     move_exemplar_to_warehouse(uuid) 	   PROCEDURE     P  CREATE PROCEDURE public.move_exemplar_to_warehouse(IN _exemplarid uuid)
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) NOT IN ('on_display', 'controlling')
		OR ((
		SELECT removaldate FROM showcased_exemplars
		INNER JOIN expositions_showcased_exemplars ON showcased_exemplars.id = expositions_showcased_exemplars.showcasedexemplarsid
		WHERE expositions_showcased_exemplars.showcasedexemplarsid = _exemplarid
	) > NOW())
	THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be moved to warehouse!', _exemplarid;
	END IF;

	-- TODO:: Najdenie aktualneho zaznamu v places a setnutie enddate na NOW()

	-- Aktualizacia stavu exemplara na 'in_warehouse' a location_id na NULL
	UPDATE exemplars
	SET status = 'in_warehouse',
		locationid = NULL,
		lastchangedate = NOW()
	WHERE id = _exemplarid;
END;
$$;
 G   DROP PROCEDURE public.move_exemplar_to_warehouse(IN _exemplarid uuid);
       public          postgres    false    6                    1255    192911 ^   plan_exposition(character varying, timestamp with time zone, timestamp with time zone, uuid[]) 	   PROCEDURE     �  CREATE PROCEDURE public.plan_exposition(IN _name character varying, IN _begindate timestamp with time zone, IN _enddate timestamp with time zone, IN _zoneids uuid[])
    LANGUAGE plpgsql
    AS $$
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
$$;
 �   DROP PROCEDURE public.plan_exposition(IN _name character varying, IN _begindate timestamp with time zone, IN _enddate timestamp with time zone, IN _zoneids uuid[]);
       public          postgres    false    6                    1255    192912    prevent_creation_date_change()    FUNCTION       CREATE FUNCTION public.prevent_creation_date_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF OLD.creationdate IS DISTINCT FROM NEW.creationdate THEN
		RAISE EXCEPTION 'Change of CreationDate is not allowed!';
	END IF;
	RETURN NEW;
END;
$$;
 5   DROP FUNCTION public.prevent_creation_date_change();
       public          postgres    false    6                    1255    192913 $   prevent_decommission_status_change()    FUNCTION     M  CREATE FUNCTION public.prevent_decommission_status_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF OLD.status = 'decommissioned' AND OLD.status IS DISTINCT FROM NEW.status THEN
		RAISE EXCEPTION 'Changing decommissioned exemplar % is not allowed. Please create a new entry.', OLD.id;
	END IF;
	RETURN NEW;
END;
$$;
 ;   DROP FUNCTION public.prevent_decommission_status_change();
       public          postgres    false    6                    1255    192914 �   receive_exemplar(character varying, uuid, uuid, timestamp with time zone, timestamp with time zone, time without time zone, uuid) 	   PROCEDURE     �  CREATE PROCEDURE public.receive_exemplar(IN _name character varying, IN _institutionid uuid, IN _ownerid uuid, IN _borrowdate timestamp with time zone, IN _returndate timestamp with time zone, IN _checklength time without time zone, IN _categoryid uuid)
    LANGUAGE plpgsql
    AS $$
DECLARE
	new_exemplar_id UUID;
BEGIN
	-- Vytvorenie noveho exemplara
	SELECT insert_exemplar(_name, _categoryid) INTO new_exemplar_id;

	-- Vytvorenie noveho zaznamu v borrows
	INSERT INTO borrows (exemplarid, institutionid, ownerid, borrowdate, returndate, checkstate, checklength)
	VALUES (new_exemplar_id, _institutionid, _ownerid, _borrowdate, _returndate, 'waiting_for_arrival', _checklength);
END;
$$;
 �   DROP PROCEDURE public.receive_exemplar(IN _name character varying, IN _institutionid uuid, IN _ownerid uuid, IN _borrowdate timestamp with time zone, IN _returndate timestamp with time zone, IN _checklength time without time zone, IN _categoryid uuid);
       public          postgres    false    6                    1255    192915    set_last_change_date()    FUNCTION     �   CREATE FUNCTION public.set_last_change_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	NEW.lastchangedate := NOW(); -- Aktualizacia lastchangedate pri zmene zaznamu
	RETURN NEW;
END;
$$;
 -   DROP FUNCTION public.set_last_change_date();
       public          postgres    false    6                    1255    192916    set_status_decommissioned()    FUNCTION     �  CREATE FUNCTION public.set_status_decommissioned() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 2   DROP FUNCTION public.set_status_decommissioned();
       public          postgres    false    6                    1255    192917 W   showcase_exemplar(uuid, uuid, uuid, timestamp with time zone, timestamp with time zone) 	   PROCEDURE     �
  CREATE PROCEDURE public.showcase_exemplar(IN _exemplarid uuid, IN _expositionid uuid, IN _zoneid uuid, IN _showcaseddate timestamp with time zone, IN _removaldate timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
DECLARE
	new_showcased_exemplar_id UUID;
	new_zone_id UUID;
	exposition_start_date TIMESTAMP WITH TIME ZONE;
	exposition_end_date TIMESTAMP WITH TIME ZONE;
	is_showcased BOOLEAN;
	zone_belongs_to_exposition BOOLEAN;
BEGIN
	SELECT EXISTS(
		SELECT e.id FROM expositions e
		JOIN places p ON e.id = p.expositionid
		WHERE p.zoneid = _zoneid AND e.id = _expositionid
	) INTO zone_belongs_to_exposition;

	IF NOT zone_belongs_to_exposition THEN
		RAISE EXCEPTION 'Zone with ID % does not belong to exposition with ID %!', _zoneid, _expositionid;
	END IF;


	new_zone_id := (SELECT zoneid FROM places WHERE expositionid = _expositionid AND zoneid = _zoneid);
	exposition_start_date := (SELECT startdate FROM places WHERE expositionid = _expositionid AND zoneid = _zoneid);
	exposition_end_date := (SELECT enddate FROM places WHERE expositionid = _expositionid AND zoneid = _zoneid);
	SELECT EXISTS (
		SELECT 1 FROM showcased_exemplars se
		INNER JOIN expositions_showcased_exemplars ese ON se.id = ese.showcasedexemplarsid
		INNER JOIN exemplars_showcased_exemplars e on se.id = e.showcasedexemplarsid
		WHERE e.exemplarid = _exemplarid
		AND (
			(se.showcaseddate < _removaldate AND se.removaldate > _showcaseddate)
			OR
			(ese.expositionsid = _expositionid AND se.showcaseddate < _removaldate AND se.removaldate > _showcaseddate)
		)
	) INTO is_showcased;

	-- Kontrola, ci exemplar je 'in_warehouse' a nie je uz vystaveny alebo zapozicany v danom casovom obdobi
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) = 'in_warehouse'
		AND new_zone_id IS NOT NULL
		AND (exposition_start_date <= _showcaseddate AND exposition_end_date >= _removaldate)
		AND NOT is_showcased
	THEN
		-- Vytvorenie noveho zaznamu v tabulke showcased_exemplars
		INSERT INTO showcased_exemplars (showcaseddate, removaldate)
		VALUES (_showcaseddate, _removaldate)
		RETURNING id INTO new_showcased_exemplar_id;

		-- Aktualizacia stavu exemplara na 'on_display'
		UPDATE exemplars SET status = 'on_display', lastchangedate = NOW(), locationid = new_zone_id WHERE id = _exemplarid;

		-- Pridanie zaznamu do medzitabulky exemplars_showcased_exemplars
		INSERT INTO exemplars_showcased_exemplars (exemplarid, showcasedexemplarsid)
		VALUES (_exemplarid, new_showcased_exemplar_id);

		-- Pridanie zaznamu do medzitabulky expositions_showcased_exemplars
		INSERT INTO expositions_showcased_exemplars (expositionsid, showcasedexemplarsid)
		VALUES (_expositionid, new_showcased_exemplar_id);
	ELSE
		RAISE EXCEPTION 'Exemplar % is not showcaseable!', _exemplarid;
	END IF;
END;
$$;
 �   DROP PROCEDURE public.showcase_exemplar(IN _exemplarid uuid, IN _expositionid uuid, IN _zoneid uuid, IN _showcaseddate timestamp with time zone, IN _removaldate timestamp with time zone);
       public          postgres    false    6                    1255    192918 $   update_exemplar_status_to_borrowed()    FUNCTION     �  CREATE FUNCTION public.update_exemplar_status_to_borrowed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 ;   DROP FUNCTION public.update_exemplar_status_to_borrowed();
       public          postgres    false    6                    1255    192919    validate_borrow_dates()    FUNCTION       CREATE FUNCTION public.validate_borrow_dates() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.borrowdate >= NEW.returndate THEN
		RAISE EXCEPTION 'BorrowDate must be earlier than ReturnDate.'; -- Kontrola platnosti datumov
	END IF;
	RETURN NEW;
END;
$$;
 .   DROP FUNCTION public.validate_borrow_dates();
       public          postgres    false    6                    1255    192920    validate_showcased_dates()    FUNCTION       CREATE FUNCTION public.validate_showcased_dates() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.showcaseddate >= NEW.removaldate THEN
		RAISE EXCEPTION 'ShowcasedDate must be earlier than RemovalDate.'; -- Kontrola platnosti datumov
	END IF;
	RETURN NEW;
END;
$$;
 1   DROP FUNCTION public.validate_showcased_dates();
       public          postgres    false    6         �            1259    192921    borrows    TABLE     ;  CREATE TABLE public.borrows (
    exemplarid uuid NOT NULL,
    institutionid uuid NOT NULL,
    ownerid uuid NOT NULL,
    borrowdate timestamp with time zone NOT NULL,
    returndate timestamp with time zone NOT NULL,
    checkstate public.check_state NOT NULL,
    checklength time without time zone NOT NULL
);
    DROP TABLE public.borrows;
       public         heap    postgres    false    6    901         �            1259    192924 
   categories    TABLE     �   CREATE TABLE public.categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description character varying(255)
);
    DROP TABLE public.categories;
       public         heap    postgres    false    6         �            1259    192928 	   exemplars    TABLE     C  CREATE TABLE public.exemplars (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    locationid uuid,
    name character varying(100) NOT NULL,
    status public.exemplar_status NOT NULL,
    creationdate timestamp with time zone DEFAULT now() NOT NULL,
    lastchangedate timestamp with time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.exemplars;
       public         heap    postgres    false    6    904         �            1259    192934    exemplars_categories    TABLE     k   CREATE TABLE public.exemplars_categories (
    exemplarid uuid NOT NULL,
    categoriesid uuid NOT NULL
);
 (   DROP TABLE public.exemplars_categories;
       public         heap    postgres    false    6         �            1259    192937    exemplars_showcased_exemplars    TABLE     |   CREATE TABLE public.exemplars_showcased_exemplars (
    showcasedexemplarsid uuid NOT NULL,
    exemplarid uuid NOT NULL
);
 1   DROP TABLE public.exemplars_showcased_exemplars;
       public         heap    postgres    false    6         �            1259    192940    expositions    TABLE       CREATE TABLE public.expositions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    begindate timestamp with time zone NOT NULL,
    enddate timestamp with time zone NOT NULL,
    status public.exposition_status NOT NULL
);
    DROP TABLE public.expositions;
       public         heap    postgres    false    907    6         �            1259    192944    expositions_showcased_exemplars    TABLE     �   CREATE TABLE public.expositions_showcased_exemplars (
    showcasedexemplarsid uuid NOT NULL,
    expositionsid uuid NOT NULL
);
 3   DROP TABLE public.expositions_showcased_exemplars;
       public         heap    postgres    false    6         �            1259    192947    institutions    TABLE     �   CREATE TABLE public.institutions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description character varying(255),
    manager character varying(50) NOT NULL
);
     DROP TABLE public.institutions;
       public         heap    postgres    false    6         �            1259    192951    places    TABLE     �   CREATE TABLE public.places (
    expositionid uuid NOT NULL,
    zoneid uuid NOT NULL,
    startdate timestamp with time zone NOT NULL,
    enddate timestamp with time zone NOT NULL
);
    DROP TABLE public.places;
       public         heap    postgres    false    6         �            1259    192954    showcased_exemplars    TABLE     �   CREATE TABLE public.showcased_exemplars (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    showcaseddate timestamp with time zone NOT NULL,
    removaldate timestamp with time zone NOT NULL
);
 '   DROP TABLE public.showcased_exemplars;
       public         heap    postgres    false    6         �            1259    192958    zones    TABLE     �   CREATE TABLE public.zones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description character varying(255)
);
    DROP TABLE public.zones;
       public         heap    postgres    false    6         �          0    192921    borrows 
   TABLE DATA           v   COPY public.borrows (exemplarid, institutionid, ownerid, borrowdate, returndate, checkstate, checklength) FROM stdin;
    public          postgres    false    216       3490.dat �          0    192924 
   categories 
   TABLE DATA           ;   COPY public.categories (id, name, description) FROM stdin;
    public          postgres    false    217       3491.dat �          0    192928 	   exemplars 
   TABLE DATA           _   COPY public.exemplars (id, locationid, name, status, creationdate, lastchangedate) FROM stdin;
    public          postgres    false    218       3492.dat �          0    192934    exemplars_categories 
   TABLE DATA           H   COPY public.exemplars_categories (exemplarid, categoriesid) FROM stdin;
    public          postgres    false    219       3493.dat �          0    192937    exemplars_showcased_exemplars 
   TABLE DATA           Y   COPY public.exemplars_showcased_exemplars (showcasedexemplarsid, exemplarid) FROM stdin;
    public          postgres    false    220       3494.dat �          0    192940    expositions 
   TABLE DATA           K   COPY public.expositions (id, name, begindate, enddate, status) FROM stdin;
    public          postgres    false    221       3495.dat �          0    192944    expositions_showcased_exemplars 
   TABLE DATA           ^   COPY public.expositions_showcased_exemplars (showcasedexemplarsid, expositionsid) FROM stdin;
    public          postgres    false    222       3496.dat �          0    192947    institutions 
   TABLE DATA           F   COPY public.institutions (id, name, description, manager) FROM stdin;
    public          postgres    false    223       3497.dat �          0    192951    places 
   TABLE DATA           J   COPY public.places (expositionid, zoneid, startdate, enddate) FROM stdin;
    public          postgres    false    224       3498.dat �          0    192954    showcased_exemplars 
   TABLE DATA           M   COPY public.showcased_exemplars (id, showcaseddate, removaldate) FROM stdin;
    public          postgres    false    225       3499.dat �          0    192958    zones 
   TABLE DATA           6   COPY public.zones (id, name, description) FROM stdin;
    public          postgres    false    226       3500.dat �           2606    192963    categories categories_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.categories DROP CONSTRAINT categories_pkey;
       public            postgres    false    217         �           2606    192965 .   exemplars_categories exemplars_categories_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.exemplars_categories
    ADD CONSTRAINT exemplars_categories_pkey PRIMARY KEY (exemplarid, categoriesid);
 X   ALTER TABLE ONLY public.exemplars_categories DROP CONSTRAINT exemplars_categories_pkey;
       public            postgres    false    219    219         �           2606    192967    exemplars exemplars_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.exemplars
    ADD CONSTRAINT exemplars_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.exemplars DROP CONSTRAINT exemplars_pkey;
       public            postgres    false    218         �           2606    192969 @   exemplars_showcased_exemplars exemplars_showcased_exemplars_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.exemplars_showcased_exemplars
    ADD CONSTRAINT exemplars_showcased_exemplars_pkey PRIMARY KEY (showcasedexemplarsid, exemplarid);
 j   ALTER TABLE ONLY public.exemplars_showcased_exemplars DROP CONSTRAINT exemplars_showcased_exemplars_pkey;
       public            postgres    false    220    220         �           2606    192971    expositions expositions_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.expositions
    ADD CONSTRAINT expositions_pkey PRIMARY KEY (id);
 F   ALTER TABLE ONLY public.expositions DROP CONSTRAINT expositions_pkey;
       public            postgres    false    221         �           2606    192973 D   expositions_showcased_exemplars expositions_showcased_exemplars_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.expositions_showcased_exemplars
    ADD CONSTRAINT expositions_showcased_exemplars_pkey PRIMARY KEY (showcasedexemplarsid, expositionsid);
 n   ALTER TABLE ONLY public.expositions_showcased_exemplars DROP CONSTRAINT expositions_showcased_exemplars_pkey;
       public            postgres    false    222    222         �           2606    192975    institutions institutions_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.institutions
    ADD CONSTRAINT institutions_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.institutions DROP CONSTRAINT institutions_pkey;
       public            postgres    false    223         �           2606    192977 ,   showcased_exemplars showcased_exemplars_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.showcased_exemplars
    ADD CONSTRAINT showcased_exemplars_pkey PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.showcased_exemplars DROP CONSTRAINT showcased_exemplars_pkey;
       public            postgres    false    225         �           2606    192979    zones zones_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.zones DROP CONSTRAINT zones_pkey;
       public            postgres    false    226                    2620    192980 '   exemplars trigger_prevent_column_change    TRIGGER     �   CREATE TRIGGER trigger_prevent_column_change BEFORE UPDATE ON public.exemplars FOR EACH ROW EXECUTE FUNCTION public.prevent_creation_date_change();
 @   DROP TRIGGER trigger_prevent_column_change ON public.exemplars;
       public          postgres    false    218    278                    2620    192981 4   exemplars trigger_prevent_decommission_status_change    TRIGGER     �   CREATE TRIGGER trigger_prevent_decommission_status_change BEFORE UPDATE ON public.exemplars FOR EACH ROW EXECUTE FUNCTION public.prevent_decommission_status_change();
 M   DROP TRIGGER trigger_prevent_decommission_status_change ON public.exemplars;
       public          postgres    false    279    218                    2620    192982 0   exemplars trigger_set_last_change_date_exemplars    TRIGGER     �   CREATE TRIGGER trigger_set_last_change_date_exemplars BEFORE UPDATE ON public.exemplars FOR EACH ROW EXECUTE FUNCTION public.set_last_change_date();
 I   DROP TRIGGER trigger_set_last_change_date_exemplars ON public.exemplars;
       public          postgres    false    218    281                    2620    192983 +   exemplars trigger_set_status_decommissioned    TRIGGER     �   CREATE TRIGGER trigger_set_status_decommissioned BEFORE DELETE ON public.exemplars FOR EACH ROW EXECUTE FUNCTION public.set_status_decommissioned();
 D   DROP TRIGGER trigger_set_status_decommissioned ON public.exemplars;
       public          postgres    false    282    218                    2620    192984 2   borrows trigger_update_exemplar_status_to_borrowed    TRIGGER     �   CREATE TRIGGER trigger_update_exemplar_status_to_borrowed AFTER INSERT ON public.borrows FOR EACH ROW EXECUTE FUNCTION public.update_exemplar_status_to_borrowed();
 K   DROP TRIGGER trigger_update_exemplar_status_to_borrowed ON public.borrows;
       public          postgres    false    284    216                    2620    192985 %   borrows trigger_validate_borrow_dates    TRIGGER     �   CREATE TRIGGER trigger_validate_borrow_dates BEFORE INSERT OR UPDATE ON public.borrows FOR EACH ROW EXECUTE FUNCTION public.validate_borrow_dates();
 >   DROP TRIGGER trigger_validate_borrow_dates ON public.borrows;
       public          postgres    false    216    285                    2620    192986 4   showcased_exemplars trigger_validate_showcased_dates    TRIGGER     �   CREATE TRIGGER trigger_validate_showcased_dates BEFORE INSERT OR UPDATE ON public.showcased_exemplars FOR EACH ROW EXECUTE FUNCTION public.validate_showcased_dates();
 M   DROP TRIGGER trigger_validate_showcased_dates ON public.showcased_exemplars;
       public          postgres    false    225    286                     2606    192987    borrows fkborrows1    FK CONSTRAINT     x   ALTER TABLE ONLY public.borrows
    ADD CONSTRAINT fkborrows1 FOREIGN KEY (exemplarid) REFERENCES public.exemplars(id);
 <   ALTER TABLE ONLY public.borrows DROP CONSTRAINT fkborrows1;
       public          postgres    false    216    3313    218                    2606    192992    borrows fkborrows2    FK CONSTRAINT     ~   ALTER TABLE ONLY public.borrows
    ADD CONSTRAINT fkborrows2 FOREIGN KEY (institutionid) REFERENCES public.institutions(id);
 <   ALTER TABLE ONLY public.borrows DROP CONSTRAINT fkborrows2;
       public          postgres    false    3323    223    216                    2606    192997    borrows fkborrows3    FK CONSTRAINT     x   ALTER TABLE ONLY public.borrows
    ADD CONSTRAINT fkborrows3 FOREIGN KEY (ownerid) REFERENCES public.institutions(id);
 <   ALTER TABLE ONLY public.borrows DROP CONSTRAINT fkborrows3;
       public          postgres    false    216    223    3323                    2606    193002    exemplars fkexemplar1    FK CONSTRAINT     w   ALTER TABLE ONLY public.exemplars
    ADD CONSTRAINT fkexemplar1 FOREIGN KEY (locationid) REFERENCES public.zones(id);
 ?   ALTER TABLE ONLY public.exemplars DROP CONSTRAINT fkexemplar1;
       public          postgres    false    226    3327    218                    2606    193007 ,   exemplars_categories fkexemplars_categories1    FK CONSTRAINT     �   ALTER TABLE ONLY public.exemplars_categories
    ADD CONSTRAINT fkexemplars_categories1 FOREIGN KEY (exemplarid) REFERENCES public.exemplars(id);
 V   ALTER TABLE ONLY public.exemplars_categories DROP CONSTRAINT fkexemplars_categories1;
       public          postgres    false    3313    218    219                    2606    193012 ,   exemplars_categories fkexemplars_categories2    FK CONSTRAINT     �   ALTER TABLE ONLY public.exemplars_categories
    ADD CONSTRAINT fkexemplars_categories2 FOREIGN KEY (categoriesid) REFERENCES public.categories(id);
 V   ALTER TABLE ONLY public.exemplars_categories DROP CONSTRAINT fkexemplars_categories2;
       public          postgres    false    217    219    3311                    2606    193017 >   exemplars_showcased_exemplars fkexemplars_showcased_exemplars1    FK CONSTRAINT     �   ALTER TABLE ONLY public.exemplars_showcased_exemplars
    ADD CONSTRAINT fkexemplars_showcased_exemplars1 FOREIGN KEY (exemplarid) REFERENCES public.exemplars(id);
 h   ALTER TABLE ONLY public.exemplars_showcased_exemplars DROP CONSTRAINT fkexemplars_showcased_exemplars1;
       public          postgres    false    3313    218    220                    2606    193022 >   exemplars_showcased_exemplars fkexemplars_showcased_exemplars2    FK CONSTRAINT     �   ALTER TABLE ONLY public.exemplars_showcased_exemplars
    ADD CONSTRAINT fkexemplars_showcased_exemplars2 FOREIGN KEY (showcasedexemplarsid) REFERENCES public.showcased_exemplars(id);
 h   ALTER TABLE ONLY public.exemplars_showcased_exemplars DROP CONSTRAINT fkexemplars_showcased_exemplars2;
       public          postgres    false    225    3325    220                    2606    193027 -   expositions_showcased_exemplars fkexposition1    FK CONSTRAINT     �   ALTER TABLE ONLY public.expositions_showcased_exemplars
    ADD CONSTRAINT fkexposition1 FOREIGN KEY (expositionsid) REFERENCES public.expositions(id);
 W   ALTER TABLE ONLY public.expositions_showcased_exemplars DROP CONSTRAINT fkexposition1;
       public          postgres    false    222    221    3319         	           2606    193032 -   expositions_showcased_exemplars fkexposition2    FK CONSTRAINT     �   ALTER TABLE ONLY public.expositions_showcased_exemplars
    ADD CONSTRAINT fkexposition2 FOREIGN KEY (showcasedexemplarsid) REFERENCES public.showcased_exemplars(id);
 W   ALTER TABLE ONLY public.expositions_showcased_exemplars DROP CONSTRAINT fkexposition2;
       public          postgres    false    3325    222    225         
           2606    193037    places fkplaces1    FK CONSTRAINT     z   ALTER TABLE ONLY public.places
    ADD CONSTRAINT fkplaces1 FOREIGN KEY (expositionid) REFERENCES public.expositions(id);
 :   ALTER TABLE ONLY public.places DROP CONSTRAINT fkplaces1;
       public          postgres    false    224    221    3319                    2606    193042    places fkplaces2    FK CONSTRAINT     n   ALTER TABLE ONLY public.places
    ADD CONSTRAINT fkplaces2 FOREIGN KEY (zoneid) REFERENCES public.zones(id);
 :   ALTER TABLE ONLY public.places DROP CONSTRAINT fkplaces2;
       public          postgres    false    226    224    3327                                                                                                                                                                                                                                                                                                                                                                                                                     3490.dat                                                                                            0000600 0004000 0002000 00000000005 14611227023 0014242 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           3491.dat                                                                                            0000600 0004000 0002000 00000000171 14611227023 0014247 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        b85be437-f92d-4497-83d1-5f013972a44f	Kategória 1	Popis 1
74580f8b-b4a3-4972-aed0-c86bbcbe0fc1	Kategória 2	Popis 2
\.


                                                                                                                                                                                                                                                                                                                                                                                                       3492.dat                                                                                            0000600 0004000 0002000 00000000477 14611227023 0014261 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        dea789e5-ba32-4685-a0c5-d5af72a3f56b	57bf03e3-3b1d-4af8-9ca7-3633812b49f6	Exemplár 2	on_display	2024-04-21 14:44:42.329037+00	2024-04-21 15:07:21.075709+00
c3e38d72-2943-4e93-83f8-ed5d4260127c	5636f93f-92cd-4bc3-8a92-8c793357046a	Exemplár 1	on_display	2024-04-21 14:44:42.322687+00	2024-04-21 15:08:05.094415+00
\.


                                                                                                                                                                                                 3493.dat                                                                                            0000600 0004000 0002000 00000000231 14611227023 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        c3e38d72-2943-4e93-83f8-ed5d4260127c	b85be437-f92d-4497-83d1-5f013972a44f
dea789e5-ba32-4685-a0c5-d5af72a3f56b	74580f8b-b4a3-4972-aed0-c86bbcbe0fc1
\.


                                                                                                                                                                                                                                                                                                                                                                       3494.dat                                                                                            0000600 0004000 0002000 00000000231 14611227023 0014247 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        794da905-3bb6-4e58-9d53-dd48bd5d3c13	c3e38d72-2943-4e93-83f8-ed5d4260127c
77f7d5a9-6609-4c49-94ae-99160cacaf41	dea789e5-ba32-4685-a0c5-d5af72a3f56b
\.


                                                                                                                                                                                                                                                                                                                                                                       3495.dat                                                                                            0000600 0004000 0002000 00000000331 14611227023 0014251 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        71bdc25c-9720-4f3c-871f-5437dc18e07b	Expozícia 1	2024-04-30 22:00:00+00	2024-05-31 22:00:00+00	preparing
14748207-c04e-4349-9c4a-d79546a3a451	Expozícia 2	2024-06-30 22:00:00+00	2024-07-31 22:00:00+00	preparing
\.


                                                                                                                                                                                                                                                                                                       3496.dat                                                                                            0000600 0004000 0002000 00000000231 14611227023 0014251 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        794da905-3bb6-4e58-9d53-dd48bd5d3c13	71bdc25c-9720-4f3c-871f-5437dc18e07b
77f7d5a9-6609-4c49-94ae-99160cacaf41	14748207-c04e-4349-9c4a-d79546a3a451
\.


                                                                                                                                                                                                                                                                                                                                                                       3497.dat                                                                                            0000600 0004000 0002000 00000000334 14611227023 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        b7e4beef-dfae-4e39-a20c-bc9de3d49afd	Moja Inštitúcia	Popis	Manažér
71bd160b-bb22-4c44-b0ab-b94dd85f11b6	Inštitúcia 1	Popis 1	Manažér 1
72157d79-3c3c-48c6-8d0b-ff37a680123d	Inštitúcia 2	Popis 2	Manažér 2
\.


                                                                                                                                                                                                                                                                                                    3498.dat                                                                                            0000600 0004000 0002000 00000000555 14611227023 0014264 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        71bdc25c-9720-4f3c-871f-5437dc18e07b	4a29ef14-c4bb-41be-abd6-affc909f015c	2024-04-30 22:00:00+00	2024-05-31 22:00:00+00
71bdc25c-9720-4f3c-871f-5437dc18e07b	5636f93f-92cd-4bc3-8a92-8c793357046a	2024-04-30 22:00:00+00	2024-05-31 22:00:00+00
14748207-c04e-4349-9c4a-d79546a3a451	57bf03e3-3b1d-4af8-9ca7-3633812b49f6	2024-06-30 22:00:00+00	2024-07-31 22:00:00+00
\.


                                                                                                                                                   3499.dat                                                                                            0000600 0004000 0002000 00000000253 14611227023 0014260 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        794da905-3bb6-4e58-9d53-dd48bd5d3c13	2024-05-09 22:00:00+00	2024-05-19 22:00:00+00
77f7d5a9-6609-4c49-94ae-99160cacaf41	2024-07-09 22:00:00+00	2024-07-19 22:00:00+00
\.


                                                                                                                                                                                                                                                                                                                                                     3500.dat                                                                                            0000600 0004000 0002000 00000000244 14611227023 0014237 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        4a29ef14-c4bb-41be-abd6-affc909f015c	Zóna 1	Popis 1
5636f93f-92cd-4bc3-8a92-8c793357046a	Zóna 2	Popis 2
57bf03e3-3b1d-4af8-9ca7-3633812b49f6	Zóna 3	Popis 3
\.


                                                                                                                                                                                                                                                                                                                                                            restore.sql                                                                                         0000600 0004000 0002000 00000074032 14611227023 0015370 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2 (Debian 16.2-1.pgdg120+2)
-- Dumped by pg_dump version 16.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE zadanie_4;
--
-- Name: zadanie_4; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE zadanie_4 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE zadanie_4 OWNER TO postgres;

\connect zadanie_4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: check_state; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.check_state AS ENUM (
    'waiting_for_arrival',
    'checking',
    'check_completed'
);


ALTER TYPE public.check_state OWNER TO postgres;

--
-- Name: exemplar_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.exemplar_status AS ENUM (
    'borrowed',
    'on_display',
    'in_warehouse',
    'returning',
    'sending',
    'controlling',
    'decommissioned'
);


ALTER TYPE public.exemplar_status OWNER TO postgres;

--
-- Name: exposition_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.exposition_status AS ENUM (
    'preparing',
    'ongoing',
    'completed'
);


ALTER TYPE public.exposition_status OWNER TO postgres;

--
-- Name: insert_exemplar(character varying, uuid); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.insert_exemplar(IN _name character varying, IN _categoryid uuid)
    LANGUAGE plpgsql
    AS $$
DECLARE
	new_exemplar_id UUID;
BEGIN
	INSERT INTO exemplars (name, status)
	VALUES (_name, 'in_warehouse')
	RETURNING id INTO new_exemplar_id; -- Vratenie ID noveho exemplara

	INSERT INTO exemplars_categories (exemplarid, categoriesid)
	VALUES (new_exemplar_id, _categoryid); -- Priradenie kategorie
END;
$$;


ALTER PROCEDURE public.insert_exemplar(IN _name character varying, IN _categoryid uuid) OWNER TO postgres;

--
-- Name: lend_exemplar(uuid, uuid, uuid, timestamp with time zone, timestamp with time zone, time without time zone); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.lend_exemplar(IN _exemplarid uuid, IN _institutionid uuid, IN _ownerid uuid, IN _borrowdate timestamp with time zone, IN _returndate timestamp with time zone, IN _checklength time without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) != 'in_warehouse' THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be lend!', _exemplarid;
	END IF;

	INSERT INTO borrows (exemplarid, institutionid, ownerid, borrowdate, returndate, checkstate, checklength)
		VALUES (_exemplarid, _institutionid, _ownerid, _borrowdate, _returndate, 'sending', _checklength);
END;
$$;


ALTER PROCEDURE public.lend_exemplar(IN _exemplarid uuid, IN _institutionid uuid, IN _ownerid uuid, IN _borrowdate timestamp with time zone, IN _returndate timestamp with time zone, IN _checklength time without time zone) OWNER TO postgres;

--
-- Name: move_exemplar(uuid, uuid, timestamp with time zone, timestamp with time zone); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.move_exemplar(IN _exemplarid uuid, IN _zoneid uuid, IN _begindate timestamp with time zone, IN _enddate timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
DECLARE
	_exemplar_status VARCHAR;
	_zone_exists BOOLEAN;
	_exemplar_exists BOOLEAN;
	_exemplar_current_location UUID;
	_exposition_id UUID;
BEGIN
	-- Kontrola, ci exemplar a zóna existujú
	SELECT EXISTS(SELECT id FROM zones WHERE id = _zoneid) INTO _zone_exists;
	SELECT EXISTS(SELECT id FROM exemplars WHERE id = _exemplarid) INTO _exemplar_exists;
	IF NOT _zone_exists THEN
		RAISE EXCEPTION 'Zone with ID % does not exist!', _zoneid;
	END IF;
	IF NOT _exemplar_exists THEN
		RAISE EXCEPTION 'Exemplar with ID % does not exist!', _exemplarid;
	END IF;

	-- Kontrola, stavu exemplara
	SELECT status INTO _exemplar_status FROM exemplars WHERE id = _exemplarid;
	IF _exemplar_status != 'on_display' THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be moved! It is not on display.', _exemplarid;
	END IF;

	-- Kontrola, ci exemplar už nie je v danej zóne
	SELECT locationid INTO _exemplar_current_location FROM exemplars WHERE id = _exemplarid;
	IF _exemplar_current_location = _zoneid THEN
		RAISE INFO 'Exemplar with ID % is already in zone %.', _exemplarid, _zoneid;
		RETURN;
	END IF;

	-- Kontrola, ci zóna patrí k expozícii
	SELECT e.id INTO _exposition_id FROM expositions e
		JOIN places p ON e.id = p.expositionid
		JOIN exemplars e2 ON p.zoneid = e2.locationid
		WHERE p.zoneid = _zoneid AND p.enddate >= NOW() AND e2.id = _exemplarid;

	IF _exposition_id IS NULL THEN
		RAISE EXCEPTION 'Zone with ID % does not belong to an exposition!', _zoneid;
	END IF;

	-- Aktualizacia polohy exemplara
	UPDATE exemplars SET locationid = _zoneid WHERE id = _exemplarid;
END;
$$;


ALTER PROCEDURE public.move_exemplar(IN _exemplarid uuid, IN _zoneid uuid, IN _begindate timestamp with time zone, IN _enddate timestamp with time zone) OWNER TO postgres;

--
-- Name: move_exemplar_to_warehouse(uuid); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.move_exemplar_to_warehouse(IN _exemplarid uuid)
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) NOT IN ('on_display', 'controlling')
		OR ((
		SELECT removaldate FROM showcased_exemplars
		INNER JOIN expositions_showcased_exemplars ON showcased_exemplars.id = expositions_showcased_exemplars.showcasedexemplarsid
		WHERE expositions_showcased_exemplars.showcasedexemplarsid = _exemplarid
	) > NOW())
	THEN
		RAISE EXCEPTION 'Exemplar with ID % cannot be moved to warehouse!', _exemplarid;
	END IF;

	-- TODO:: Najdenie aktualneho zaznamu v places a setnutie enddate na NOW()

	-- Aktualizacia stavu exemplara na 'in_warehouse' a location_id na NULL
	UPDATE exemplars
	SET status = 'in_warehouse',
		locationid = NULL,
		lastchangedate = NOW()
	WHERE id = _exemplarid;
END;
$$;


ALTER PROCEDURE public.move_exemplar_to_warehouse(IN _exemplarid uuid) OWNER TO postgres;

--
-- Name: plan_exposition(character varying, timestamp with time zone, timestamp with time zone, uuid[]); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.plan_exposition(IN _name character varying, IN _begindate timestamp with time zone, IN _enddate timestamp with time zone, IN _zoneids uuid[])
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER PROCEDURE public.plan_exposition(IN _name character varying, IN _begindate timestamp with time zone, IN _enddate timestamp with time zone, IN _zoneids uuid[]) OWNER TO postgres;

--
-- Name: prevent_creation_date_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_creation_date_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF OLD.creationdate IS DISTINCT FROM NEW.creationdate THEN
		RAISE EXCEPTION 'Change of CreationDate is not allowed!';
	END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.prevent_creation_date_change() OWNER TO postgres;

--
-- Name: prevent_decommission_status_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_decommission_status_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF OLD.status = 'decommissioned' AND OLD.status IS DISTINCT FROM NEW.status THEN
		RAISE EXCEPTION 'Changing decommissioned exemplar % is not allowed. Please create a new entry.', OLD.id;
	END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.prevent_decommission_status_change() OWNER TO postgres;

--
-- Name: receive_exemplar(character varying, uuid, uuid, timestamp with time zone, timestamp with time zone, time without time zone, uuid); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.receive_exemplar(IN _name character varying, IN _institutionid uuid, IN _ownerid uuid, IN _borrowdate timestamp with time zone, IN _returndate timestamp with time zone, IN _checklength time without time zone, IN _categoryid uuid)
    LANGUAGE plpgsql
    AS $$
DECLARE
	new_exemplar_id UUID;
BEGIN
	-- Vytvorenie noveho exemplara
	SELECT insert_exemplar(_name, _categoryid) INTO new_exemplar_id;

	-- Vytvorenie noveho zaznamu v borrows
	INSERT INTO borrows (exemplarid, institutionid, ownerid, borrowdate, returndate, checkstate, checklength)
	VALUES (new_exemplar_id, _institutionid, _ownerid, _borrowdate, _returndate, 'waiting_for_arrival', _checklength);
END;
$$;


ALTER PROCEDURE public.receive_exemplar(IN _name character varying, IN _institutionid uuid, IN _ownerid uuid, IN _borrowdate timestamp with time zone, IN _returndate timestamp with time zone, IN _checklength time without time zone, IN _categoryid uuid) OWNER TO postgres;

--
-- Name: set_last_change_date(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_last_change_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	NEW.lastchangedate := NOW(); -- Aktualizacia lastchangedate pri zmene zaznamu
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_last_change_date() OWNER TO postgres;

--
-- Name: set_status_decommissioned(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_status_decommissioned() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.set_status_decommissioned() OWNER TO postgres;

--
-- Name: showcase_exemplar(uuid, uuid, uuid, timestamp with time zone, timestamp with time zone); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.showcase_exemplar(IN _exemplarid uuid, IN _expositionid uuid, IN _zoneid uuid, IN _showcaseddate timestamp with time zone, IN _removaldate timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
DECLARE
	new_showcased_exemplar_id UUID;
	new_zone_id UUID;
	exposition_start_date TIMESTAMP WITH TIME ZONE;
	exposition_end_date TIMESTAMP WITH TIME ZONE;
	is_showcased BOOLEAN;
	zone_belongs_to_exposition BOOLEAN;
BEGIN
	SELECT EXISTS(
		SELECT e.id FROM expositions e
		JOIN places p ON e.id = p.expositionid
		WHERE p.zoneid = _zoneid AND e.id = _expositionid
	) INTO zone_belongs_to_exposition;

	IF NOT zone_belongs_to_exposition THEN
		RAISE EXCEPTION 'Zone with ID % does not belong to exposition with ID %!', _zoneid, _expositionid;
	END IF;


	new_zone_id := (SELECT zoneid FROM places WHERE expositionid = _expositionid AND zoneid = _zoneid);
	exposition_start_date := (SELECT startdate FROM places WHERE expositionid = _expositionid AND zoneid = _zoneid);
	exposition_end_date := (SELECT enddate FROM places WHERE expositionid = _expositionid AND zoneid = _zoneid);
	SELECT EXISTS (
		SELECT 1 FROM showcased_exemplars se
		INNER JOIN expositions_showcased_exemplars ese ON se.id = ese.showcasedexemplarsid
		INNER JOIN exemplars_showcased_exemplars e on se.id = e.showcasedexemplarsid
		WHERE e.exemplarid = _exemplarid
		AND (
			(se.showcaseddate < _removaldate AND se.removaldate > _showcaseddate)
			OR
			(ese.expositionsid = _expositionid AND se.showcaseddate < _removaldate AND se.removaldate > _showcaseddate)
		)
	) INTO is_showcased;

	-- Kontrola, ci exemplar je 'in_warehouse' a nie je uz vystaveny alebo zapozicany v danom casovom obdobi
	IF (SELECT status FROM exemplars WHERE id = _exemplarid) = 'in_warehouse'
		AND new_zone_id IS NOT NULL
		AND (exposition_start_date <= _showcaseddate AND exposition_end_date >= _removaldate)
		AND NOT is_showcased
	THEN
		-- Vytvorenie noveho zaznamu v tabulke showcased_exemplars
		INSERT INTO showcased_exemplars (showcaseddate, removaldate)
		VALUES (_showcaseddate, _removaldate)
		RETURNING id INTO new_showcased_exemplar_id;

		-- Aktualizacia stavu exemplara na 'on_display'
		UPDATE exemplars SET status = 'on_display', lastchangedate = NOW(), locationid = new_zone_id WHERE id = _exemplarid;

		-- Pridanie zaznamu do medzitabulky exemplars_showcased_exemplars
		INSERT INTO exemplars_showcased_exemplars (exemplarid, showcasedexemplarsid)
		VALUES (_exemplarid, new_showcased_exemplar_id);

		-- Pridanie zaznamu do medzitabulky expositions_showcased_exemplars
		INSERT INTO expositions_showcased_exemplars (expositionsid, showcasedexemplarsid)
		VALUES (_expositionid, new_showcased_exemplar_id);
	ELSE
		RAISE EXCEPTION 'Exemplar % is not showcaseable!', _exemplarid;
	END IF;
END;
$$;


ALTER PROCEDURE public.showcase_exemplar(IN _exemplarid uuid, IN _expositionid uuid, IN _zoneid uuid, IN _showcaseddate timestamp with time zone, IN _removaldate timestamp with time zone) OWNER TO postgres;

--
-- Name: update_exemplar_status_to_borrowed(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_exemplar_status_to_borrowed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.update_exemplar_status_to_borrowed() OWNER TO postgres;

--
-- Name: validate_borrow_dates(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_borrow_dates() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.borrowdate >= NEW.returndate THEN
		RAISE EXCEPTION 'BorrowDate must be earlier than ReturnDate.'; -- Kontrola platnosti datumov
	END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.validate_borrow_dates() OWNER TO postgres;

--
-- Name: validate_showcased_dates(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_showcased_dates() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.showcaseddate >= NEW.removaldate THEN
		RAISE EXCEPTION 'ShowcasedDate must be earlier than RemovalDate.'; -- Kontrola platnosti datumov
	END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.validate_showcased_dates() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: borrows; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.borrows (
    exemplarid uuid NOT NULL,
    institutionid uuid NOT NULL,
    ownerid uuid NOT NULL,
    borrowdate timestamp with time zone NOT NULL,
    returndate timestamp with time zone NOT NULL,
    checkstate public.check_state NOT NULL,
    checklength time without time zone NOT NULL
);


ALTER TABLE public.borrows OWNER TO postgres;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description character varying(255)
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: exemplars; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exemplars (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    locationid uuid,
    name character varying(100) NOT NULL,
    status public.exemplar_status NOT NULL,
    creationdate timestamp with time zone DEFAULT now() NOT NULL,
    lastchangedate timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.exemplars OWNER TO postgres;

--
-- Name: exemplars_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exemplars_categories (
    exemplarid uuid NOT NULL,
    categoriesid uuid NOT NULL
);


ALTER TABLE public.exemplars_categories OWNER TO postgres;

--
-- Name: exemplars_showcased_exemplars; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exemplars_showcased_exemplars (
    showcasedexemplarsid uuid NOT NULL,
    exemplarid uuid NOT NULL
);


ALTER TABLE public.exemplars_showcased_exemplars OWNER TO postgres;

--
-- Name: expositions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expositions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    begindate timestamp with time zone NOT NULL,
    enddate timestamp with time zone NOT NULL,
    status public.exposition_status NOT NULL
);


ALTER TABLE public.expositions OWNER TO postgres;

--
-- Name: expositions_showcased_exemplars; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expositions_showcased_exemplars (
    showcasedexemplarsid uuid NOT NULL,
    expositionsid uuid NOT NULL
);


ALTER TABLE public.expositions_showcased_exemplars OWNER TO postgres;

--
-- Name: institutions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.institutions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description character varying(255),
    manager character varying(50) NOT NULL
);


ALTER TABLE public.institutions OWNER TO postgres;

--
-- Name: places; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.places (
    expositionid uuid NOT NULL,
    zoneid uuid NOT NULL,
    startdate timestamp with time zone NOT NULL,
    enddate timestamp with time zone NOT NULL
);


ALTER TABLE public.places OWNER TO postgres;

--
-- Name: showcased_exemplars; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.showcased_exemplars (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    showcaseddate timestamp with time zone NOT NULL,
    removaldate timestamp with time zone NOT NULL
);


ALTER TABLE public.showcased_exemplars OWNER TO postgres;

--
-- Name: zones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description character varying(255)
);


ALTER TABLE public.zones OWNER TO postgres;

--
-- Data for Name: borrows; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.borrows (exemplarid, institutionid, ownerid, borrowdate, returndate, checkstate, checklength) FROM stdin;
\.
COPY public.borrows (exemplarid, institutionid, ownerid, borrowdate, returndate, checkstate, checklength) FROM '$$PATH$$/3490.dat';

--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (id, name, description) FROM stdin;
\.
COPY public.categories (id, name, description) FROM '$$PATH$$/3491.dat';

--
-- Data for Name: exemplars; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exemplars (id, locationid, name, status, creationdate, lastchangedate) FROM stdin;
\.
COPY public.exemplars (id, locationid, name, status, creationdate, lastchangedate) FROM '$$PATH$$/3492.dat';

--
-- Data for Name: exemplars_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exemplars_categories (exemplarid, categoriesid) FROM stdin;
\.
COPY public.exemplars_categories (exemplarid, categoriesid) FROM '$$PATH$$/3493.dat';

--
-- Data for Name: exemplars_showcased_exemplars; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exemplars_showcased_exemplars (showcasedexemplarsid, exemplarid) FROM stdin;
\.
COPY public.exemplars_showcased_exemplars (showcasedexemplarsid, exemplarid) FROM '$$PATH$$/3494.dat';

--
-- Data for Name: expositions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expositions (id, name, begindate, enddate, status) FROM stdin;
\.
COPY public.expositions (id, name, begindate, enddate, status) FROM '$$PATH$$/3495.dat';

--
-- Data for Name: expositions_showcased_exemplars; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expositions_showcased_exemplars (showcasedexemplarsid, expositionsid) FROM stdin;
\.
COPY public.expositions_showcased_exemplars (showcasedexemplarsid, expositionsid) FROM '$$PATH$$/3496.dat';

--
-- Data for Name: institutions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.institutions (id, name, description, manager) FROM stdin;
\.
COPY public.institutions (id, name, description, manager) FROM '$$PATH$$/3497.dat';

--
-- Data for Name: places; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.places (expositionid, zoneid, startdate, enddate) FROM stdin;
\.
COPY public.places (expositionid, zoneid, startdate, enddate) FROM '$$PATH$$/3498.dat';

--
-- Data for Name: showcased_exemplars; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.showcased_exemplars (id, showcaseddate, removaldate) FROM stdin;
\.
COPY public.showcased_exemplars (id, showcaseddate, removaldate) FROM '$$PATH$$/3499.dat';

--
-- Data for Name: zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zones (id, name, description) FROM stdin;
\.
COPY public.zones (id, name, description) FROM '$$PATH$$/3500.dat';

--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: exemplars_categories exemplars_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exemplars_categories
    ADD CONSTRAINT exemplars_categories_pkey PRIMARY KEY (exemplarid, categoriesid);


--
-- Name: exemplars exemplars_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exemplars
    ADD CONSTRAINT exemplars_pkey PRIMARY KEY (id);


--
-- Name: exemplars_showcased_exemplars exemplars_showcased_exemplars_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exemplars_showcased_exemplars
    ADD CONSTRAINT exemplars_showcased_exemplars_pkey PRIMARY KEY (showcasedexemplarsid, exemplarid);


--
-- Name: expositions expositions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expositions
    ADD CONSTRAINT expositions_pkey PRIMARY KEY (id);


--
-- Name: expositions_showcased_exemplars expositions_showcased_exemplars_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expositions_showcased_exemplars
    ADD CONSTRAINT expositions_showcased_exemplars_pkey PRIMARY KEY (showcasedexemplarsid, expositionsid);


--
-- Name: institutions institutions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.institutions
    ADD CONSTRAINT institutions_pkey PRIMARY KEY (id);


--
-- Name: showcased_exemplars showcased_exemplars_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.showcased_exemplars
    ADD CONSTRAINT showcased_exemplars_pkey PRIMARY KEY (id);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: exemplars trigger_prevent_column_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_prevent_column_change BEFORE UPDATE ON public.exemplars FOR EACH ROW EXECUTE FUNCTION public.prevent_creation_date_change();


--
-- Name: exemplars trigger_prevent_decommission_status_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_prevent_decommission_status_change BEFORE UPDATE ON public.exemplars FOR EACH ROW EXECUTE FUNCTION public.prevent_decommission_status_change();


--
-- Name: exemplars trigger_set_last_change_date_exemplars; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_set_last_change_date_exemplars BEFORE UPDATE ON public.exemplars FOR EACH ROW EXECUTE FUNCTION public.set_last_change_date();


--
-- Name: exemplars trigger_set_status_decommissioned; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_set_status_decommissioned BEFORE DELETE ON public.exemplars FOR EACH ROW EXECUTE FUNCTION public.set_status_decommissioned();


--
-- Name: borrows trigger_update_exemplar_status_to_borrowed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_exemplar_status_to_borrowed AFTER INSERT ON public.borrows FOR EACH ROW EXECUTE FUNCTION public.update_exemplar_status_to_borrowed();


--
-- Name: borrows trigger_validate_borrow_dates; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_validate_borrow_dates BEFORE INSERT OR UPDATE ON public.borrows FOR EACH ROW EXECUTE FUNCTION public.validate_borrow_dates();


--
-- Name: showcased_exemplars trigger_validate_showcased_dates; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_validate_showcased_dates BEFORE INSERT OR UPDATE ON public.showcased_exemplars FOR EACH ROW EXECUTE FUNCTION public.validate_showcased_dates();


--
-- Name: borrows fkborrows1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.borrows
    ADD CONSTRAINT fkborrows1 FOREIGN KEY (exemplarid) REFERENCES public.exemplars(id);


--
-- Name: borrows fkborrows2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.borrows
    ADD CONSTRAINT fkborrows2 FOREIGN KEY (institutionid) REFERENCES public.institutions(id);


--
-- Name: borrows fkborrows3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.borrows
    ADD CONSTRAINT fkborrows3 FOREIGN KEY (ownerid) REFERENCES public.institutions(id);


--
-- Name: exemplars fkexemplar1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exemplars
    ADD CONSTRAINT fkexemplar1 FOREIGN KEY (locationid) REFERENCES public.zones(id);


--
-- Name: exemplars_categories fkexemplars_categories1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exemplars_categories
    ADD CONSTRAINT fkexemplars_categories1 FOREIGN KEY (exemplarid) REFERENCES public.exemplars(id);


--
-- Name: exemplars_categories fkexemplars_categories2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exemplars_categories
    ADD CONSTRAINT fkexemplars_categories2 FOREIGN KEY (categoriesid) REFERENCES public.categories(id);


--
-- Name: exemplars_showcased_exemplars fkexemplars_showcased_exemplars1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exemplars_showcased_exemplars
    ADD CONSTRAINT fkexemplars_showcased_exemplars1 FOREIGN KEY (exemplarid) REFERENCES public.exemplars(id);


--
-- Name: exemplars_showcased_exemplars fkexemplars_showcased_exemplars2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exemplars_showcased_exemplars
    ADD CONSTRAINT fkexemplars_showcased_exemplars2 FOREIGN KEY (showcasedexemplarsid) REFERENCES public.showcased_exemplars(id);


--
-- Name: expositions_showcased_exemplars fkexposition1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expositions_showcased_exemplars
    ADD CONSTRAINT fkexposition1 FOREIGN KEY (expositionsid) REFERENCES public.expositions(id);


--
-- Name: expositions_showcased_exemplars fkexposition2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expositions_showcased_exemplars
    ADD CONSTRAINT fkexposition2 FOREIGN KEY (showcasedexemplarsid) REFERENCES public.showcased_exemplars(id);


--
-- Name: places fkplaces1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places
    ADD CONSTRAINT fkplaces1 FOREIGN KEY (expositionid) REFERENCES public.expositions(id);


--
-- Name: places fkplaces2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places
    ADD CONSTRAINT fkplaces2 FOREIGN KEY (zoneid) REFERENCES public.zones(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      