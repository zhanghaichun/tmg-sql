
DROP TABLE IF EXISTS iaddress_street_type;
CREATE TABLE iaddress_street_type(
    id SERIAL NOT NULL PRIMARY KEY,
    "streetType" VARCHAR(32)
);


insert into iaddress_street_type("streetType")
values('AVE'),
('BLVD'),
    ('BOUL'),
('CH'),
('COVE'),
('CRES'),
('CROIS'),
('DR'),
('GREEN'),
('HTS'),
('LANE'),
('PL'),
('RANG'),
('RD'),
('RUE'),
('ST'),
('WAY'),

('AV'),
('CIR'),
('CLOSE'),
('CRT'),
('HWY'),
('TERR'),
('TSSE'),
('TRAIL');


    

