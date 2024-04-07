create type check_state as enum
(
	'waiting_for_arrival',
	'checking',
	'check_completed'
);

create type exemplar_status as enum
(
	'borrowed',
	'on_display',
	'in_warehouse',
	'returning',
	'sending',
	'controlling'
);

create type exposition_status as enum
(
	'preparing',
	'ongoing',
	'completed'
);

create table places
(
	expositionid uuid not null,
	zoneid uuid not null,
	startdate timestamp with time zone not null,
	enddate timestamp with time zone not null
);

create table expositions
(
	id uuid not null,
	name varchar(100) not null,
	begindate timestamp with time zone not null,
	enddate timestamp with time zone not null,
	status exposition_status
);

create table showcased_exemplars
(
	id uuid not null,
	showcaseddate timestamp with time zone not null,
	removaldate timestamp with time zone not null
);

create table zones
(
	id uuid not null,
	name varchar(100) not null,
	description varchar(255)
);

create table borrows
(
	exemplarid uuid not null,
	institutionid uuid not null,
	ownerid uuid not null,
	borrowdate timestamp with time zone not null,
	returndate timestamp with time zone not null,
	checkstate check_state not null,
	checklength time not null
);

create table exemplar
(
	id uuid not null,
	locationid uuid,
	name varchar(100) not null,
	status exemplar_status not null,
	creationdate timestamp with time zone not null,
	lastchangedate timestamp with time zone not null
);

create table categories
(
	id uuid not null,
	name varchar(100) not null,
	description varchar(255)
);

create table institution
(
	id uuid not null,
	name varchar(100) not null,
	description varchar(255),
	manager varchar(50) not null
);

create table exemplar_showcased_exemplars
(
	showcasedexemplarsid uuid not null,
	exemplarid uuid not null
);

create table expositions_showcased_exemplars
(
	showcasedexemplarsid uuid not null,
	expositionsid uuid not null
);

create table exemplar_categories
(
	exemplarid uuid not null,
	categoriesid uuid not null
);

alter table expositions
	add primary key (id);

alter table places
	add constraint fkplaces1
		foreign key (expositionid) references expositions;

alter table showcased_exemplars
	add primary key (id);

alter table zones
	add primary key (id);

alter table places
	add constraint fkplaces2
		foreign key (zoneid) references zones;

alter table exemplar
	add primary key (id);

alter table exemplar
	add constraint fkexemplar1
		foreign key (locationid) references zones;

alter table borrows
	add constraint fkborrows1
		foreign key (exemplarid) references exemplar;

alter table categories
	add primary key (id);

alter table institution
	add primary key (id);

alter table borrows
	add constraint fkborrows2
		foreign key (institutionid) references institution;

alter table borrows
	add constraint fkborrows3
		foreign key (ownerid) references institution;

alter table exemplar_showcased_exemplars
	add primary key (showcasedexemplarsid, exemplarid);

alter table exemplar_showcased_exemplars
	add constraint fkexemplar_showcased_exemplars1
		foreign key (exemplarid) references exemplar;

alter table exemplar_showcased_exemplars
	add constraint fkexemplar_showcased_exemplars2
		foreign key (showcasedexemplarsid) references showcased_exemplars;

alter table expositions_showcased_exemplars
	add primary key (showcasedexemplarsid, expositionsid);

alter table expositions_showcased_exemplars
	add constraint fkexposition1
		foreign key (expositionsid) references expositions;

alter table expositions_showcased_exemplars
	add constraint fkexposition2
		foreign key (showcasedexemplarsid) references showcased_exemplars;

alter table exemplar_categories
	add primary key (exemplarid, categoriesid);

alter table exemplar_categories
	add constraint fkexemplar_categories1
		foreign key (exemplarid) references exemplar;

alter table exemplar_categories
	add constraint fkexemplar_categories2
		foreign key (categoriesid) references categories;
