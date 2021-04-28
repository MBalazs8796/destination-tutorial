CREATE SCHEMA if not exists source2;

drop table if exists source2.hotels;

CREATE TABLE source2.hotels (
    id text PRIMARY KEY,
    english text NOT NULL,
    italian text,
    german text NOT NULL,
    htype text NOT NULL,
    lat float NOT NULL,
    long float NOT NULL,
    alt float NOT NULL,
    cat text NOT NULL,
    mun integer NOT NULL,
    geom geometry GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint("long", "lat", "alt"),4326)) STORED
);

INSERT INTO source2.hotels (id, english, italian, german, htype, lat, long, alt, cat, mun)
       (select a."Id", "AccoDetail-en-Name", "AccoDetail-it-Name", "AccoDetail-de-Name", "AccoTypeId", a."Latitude", a."Longitude", a."Altitude", "AccoCategoryId", m."IstatNumber"::integer 
       FROM v_accommodationsopen a join v_municipalitiesopen m on a."LocationInfo-MunicipalityInfo-Id" = m."Id"
       where a."LocationInfo-RegionInfo-Name-de" in ('Vinschgau'));

drop table if exists source2.weather_platforms;

CREATE TABLE source2.weather_platforms (
	id int8 NOT NULL,
	"name" varchar(255) NOT NULL,
	pointprojection geometry NOT NULL,
	CONSTRAINT station_pkey PRIMARY KEY (id)
);

INSERT INTO source2.weather_platforms (id, "name", pointprojection)
  (SELECT id, "name", pointprojection FROM intimev2.station WHERE stationtype='MeteoStation');


drop table if exists source2.weather_measurement;

CREATE TABLE source2.weather_measurement (
	id int8 NOT NULL,
	"period" int4 NOT NULL,
	"timestamp" timestamp NOT NULL,
    "name" text NOT NULL,
	double_value float8 NOT NULL,
    platform_id int8 NOT NULL,
	CONSTRAINT measurement_pkey PRIMARY KEY (id),
    CONSTRAINT fk_measurement_station_id_station_pk FOREIGN KEY (platform_id) REFERENCES source2.weather_platforms (id)
);

CREATE INDEX idx_measurement_timestamp ON source2.weather_measurement USING btree ("timestamp" DESC);

INSERT INTO source2.weather_measurement (id, "period", "timestamp", "name", "double_value", "platform_id")
 (SELECT m.id, m."period", m."timestamp", t.cname, double_value, station_id 
 FROM intimev2.measurement m, intimev2.station s, intimev2."type" t  
 WHERE m.station_id = s.id and s.stationtype='MeteoStation' and m.type_id = t.id 
       and cname IN ('NOX','Ozono','PM10','umidita_abs','umidita_rel','water-temperature','wind-direction','wind-speed','wind10m_direction','wind10m_speed','temp_aria'));