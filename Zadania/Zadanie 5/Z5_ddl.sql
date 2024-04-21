CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE check_state AS ENUM(
    'waiting_for_arrival',
    'checking',
    'check_completed'
);

CREATE TYPE exemplar_status AS ENUM(
    'borrowed',
    'on_display',
    'in_warehouse',
    'returning',
    'sending',
    'controlling',
    'decommissioned'
);

CREATE TYPE exposition_status AS ENUM('preparing', 'ongoing', 'completed');

CREATE TABLE
    places (
        expositionid UUID NOT NULL,
        zoneid UUID NOT NULL,
        startdate TIMESTAMP WITH TIME ZONE NOT NULL,
        enddate TIMESTAMP WITH TIME ZONE NOT NULL
    );

CREATE TABLE
    expositions (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        NAME VARCHAR(100) NOT NULL,
        begindate TIMESTAMP WITH TIME ZONE NOT NULL,
        enddate TIMESTAMP WITH TIME ZONE NOT NULL,
        status exposition_status NOT NULL
    );

CREATE TABLE
    showcased_exemplars (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        showcaseddate TIMESTAMP WITH TIME ZONE NOT NULL,
        removaldate TIMESTAMP WITH TIME ZONE NOT NULL
    );

CREATE TABLE
    zones (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        NAME VARCHAR(100) NOT NULL,
        description VARCHAR(255)
    );

CREATE TABLE
    borrows (
        exemplarid UUID NOT NULL,
        institutionid UUID NOT NULL,
        ownerid UUID NOT NULL,
        borrowdate TIMESTAMP WITH TIME ZONE NOT NULL,
        returndate TIMESTAMP WITH TIME ZONE NOT NULL,
        checkstate check_state NOT NULL,
        checklength TIME NOT NULL
    );

CREATE TABLE
    exemplars (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        locationid UUID,
        NAME VARCHAR(100) NOT NULL,
        status exemplar_status NOT NULL,
        creationdate TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        lastchangedate TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );

CREATE TABLE
    categories (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        NAME VARCHAR(100) NOT NULL,
        description VARCHAR(255)
    );

CREATE TABLE
    institutions (
        id UUID NOT NULL DEFAULT gen_random_uuid(),
        NAME VARCHAR(100) NOT NULL,
        description VARCHAR(255),
        manager VARCHAR(50) NOT NULL
    );

CREATE TABLE
    exemplars_showcased_exemplars (
        showcasedexemplarsid UUID NOT NULL,
        exemplarid UUID NOT NULL
    );

CREATE TABLE
    expositions_showcased_exemplars (
        showcasedexemplarsid UUID NOT NULL,
        expositionsid UUID NOT NULL
    );

CREATE TABLE
    exemplars_categories (
        exemplarid UUID NOT NULL,
        categoriesid UUID NOT NULL
    );

ALTER TABLE expositions
ADD PRIMARY KEY (id);

ALTER TABLE places
ADD CONSTRAINT fkplaces1 FOREIGN KEY (expositionid) REFERENCES expositions;

ALTER TABLE showcased_exemplars
ADD PRIMARY KEY (id);

ALTER TABLE zones
ADD PRIMARY KEY (id);

ALTER TABLE places
ADD CONSTRAINT fkplaces2 FOREIGN KEY (zoneid) REFERENCES zones;

ALTER TABLE exemplars
ADD PRIMARY KEY (id);

ALTER TABLE exemplars
ADD CONSTRAINT fkexemplar1 FOREIGN KEY (locationid) REFERENCES zones;

ALTER TABLE borrows
ADD CONSTRAINT fkborrows1 FOREIGN KEY (exemplarid) REFERENCES exemplars;

ALTER TABLE categories
ADD PRIMARY KEY (id);

ALTER TABLE institutions
ADD PRIMARY KEY (id);

ALTER TABLE borrows
ADD CONSTRAINT fkborrows2 FOREIGN KEY (institutionid) REFERENCES institutions;

ALTER TABLE borrows
ADD CONSTRAINT fkborrows3 FOREIGN KEY (ownerid) REFERENCES institutions;

ALTER TABLE exemplars_showcased_exemplars
ADD PRIMARY KEY (showcasedexemplarsid, exemplarid);

ALTER TABLE exemplars_showcased_exemplars
ADD CONSTRAINT fkexemplars_showcased_exemplars1 FOREIGN KEY (exemplarid) REFERENCES exemplars;

ALTER TABLE exemplars_showcased_exemplars
ADD CONSTRAINT fkexemplars_showcased_exemplars2 FOREIGN KEY (showcasedexemplarsid) REFERENCES showcased_exemplars;

ALTER TABLE expositions_showcased_exemplars
ADD PRIMARY KEY (showcasedexemplarsid, expositionsid);

ALTER TABLE expositions_showcased_exemplars
ADD CONSTRAINT fkexposition1 FOREIGN KEY (expositionsid) REFERENCES expositions;

ALTER TABLE expositions_showcased_exemplars
ADD CONSTRAINT fkexposition2 FOREIGN KEY (showcasedexemplarsid) REFERENCES showcased_exemplars;

ALTER TABLE exemplars_categories
ADD PRIMARY KEY (exemplarid, categoriesid);

ALTER TABLE exemplars_categories
ADD CONSTRAINT fkexemplars_categories1 FOREIGN KEY (exemplarid) REFERENCES exemplars;

ALTER TABLE exemplars_categories
ADD CONSTRAINT fkexemplars_categories2 FOREIGN KEY (categoriesid) REFERENCES categories;
