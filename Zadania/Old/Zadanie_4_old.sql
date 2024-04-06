create type check_state as enum ('waiting_for_arrival', 'checking', 'check_completed');
create type exemplar_status as enum ('borrowed', 'on_display', 'in_warehouse', 'returning', 'sending', 'controlling');
create type exposition_status as enum ('preparing', 'ongoing', 'completed');


create table expositions
(
	id uuid not null
		primary key,
	name varchar(100) not null,
	begindate timestamp with time zone not null,
	enddate timestamp with time zone not null,
	status exposition_status
);

create table showcased_exemplars
(
	id uuid not null
		primary key,
	showcaseddate timestamp with time zone not null,
	removaldate timestamp with time zone not null
);

create table zones
(
	id uuid not null
		primary key,
	name varchar(100) not null,
	description varchar(255)
);

create table places
(
	expositionid uuid not null
		constraint fkplaces1
			references expositions,
	zoneid uuid not null
		constraint fkplaces2
			references zones,
	startdate timestamp with time zone not null,
	enddate timestamp with time zone not null
);

create table exemplar
(
	id uuid not null
		primary key,
	locationid uuid
		constraint fkexemplar1
			references zones,
	name varchar(100) not null,
	status exemplar_status not null,
	creationdate timestamp with time zone not null,
	lastchangedate timestamp with time zone not null
);

create table categories
(
	id uuid not null
		primary key,
	name varchar(100) not null,
	description varchar(255)
);

create table institution
(
	id uuid not null
		primary key,
	name varchar(100) not null,
	description varchar(255),
	manager varchar(50) not null
);

create table borrows
(
	exemplarid uuid not null
		constraint fkborrows1
			references exemplar,
	institutionid uuid not null
		constraint fkborrows2
			references institution,
	ownerid uuid not null
		constraint fkborrows3
			references institution,
	borrowdate timestamp with time zone not null,
	returndate timestamp with time zone not null,
	checkstate check_state not null,
	checklength time not null
);

create table exemplar_showcased_exemplars
(
	showcasedexemplarsid uuid not null
		constraint fkexemplar_showcased_exemplars1
			references showcased_exemplars,
	exemplarid uuid not null
		constraint fkexemplar_showcased_exemplars2
			references exemplar,
	primary key (showcasedexemplarsid, exemplarid)
);

create table expositions_showcased_exemplars
(
	showcasedexemplarsid uuid not null
		constraint fkexposition_showcased_exemplars1
			references showcased_exemplars,
	expositionsid uuid not null
		constraint fkexposition_showcased_exemplars2
			references expositions,
	primary key (showcasedexemplarsid, expositionsid)
);

create table exemplar_categories
(
	exemplarid uuid not null
		constraint fkexemplar_categories1
			references exemplar,
	categoriesid uuid not null
		constraint fkexemplar_categories2
			references categories,
	primary key (exemplarid, categoriesid)
);


