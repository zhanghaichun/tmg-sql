drop table  if exists master_search;
CREATE TABLE "public"."master_search" (
"id" serial NOT NULL PRIMARY KEY,
"masterId" int4,
"address" varchar(256) COLLATE "default",
"unit" varchar(16) COLLATE "default",
"streetNumber" varchar(16) COLLATE "default",
"streetName" varchar(128) COLLATE "default",
"city" varchar(128) COLLATE "default",
"province" varchar(32) COLLATE "default",
"provinceId" int,
"postalCode" varchar(8) COLLATE "default",
"projectClosingDate" date,
"latitude" varchar(20) COLLATE "default",
"longitude" varchar(20) COLLATE "default",
"contactName" varchar(64) COLLATE "default",
"contactPhone" varchar(16) COLLATE "default",
"occupancyType" varchar(32) COLLATE "default",
"propertyType" varchar(32) COLLATE "default",
"sellingPrice" varchar(64) COLLATE "default",
"rentAmount" varchar(64) COLLATE "default",
"postMover" varchar(32) COLLATE "default",
"livingArea" varchar(32) COLLATE "default",
"bedrooms" varchar(8) COLLATE "default",
"bathrooms" varchar(8) COLLATE "default",
"yearBuilt" varchar(16) COLLATE "default",
"garage" char(1) COLLATE "default",
"cableAvailable" char(1) COLLATE "default",
"recActiveFlag" char(1) COLLATE "default" DEFAULT 'Y'::bpchar
)
WITH (OIDS=FALSE)
;


CREATE INDEX "master_search_bathrooms_idx" ON "public"."master_search" USING btree ("bathrooms");

CREATE INDEX "master_search_bedrooms_idx" ON "public"."master_search" USING btree ("bedrooms");

CREATE INDEX "master_search_city_idx" ON "public"."master_search" USING btree ("city");

CREATE INDEX "master_search_livingArea_idx" ON "public"."master_search" USING btree ("livingArea");

CREATE INDEX "master_search_masterId_idx" ON "public"."master_search" USING btree ("masterId");

CREATE INDEX "master_search_projectClosingDate_idx" ON "public"."master_search" USING btree ("projectClosingDate");

CREATE INDEX "master_search_provinceId_idx" ON "public"."master_search" USING btree ("provinceId");

CREATE INDEX "master_search_rentAmount_idx" ON "public"."master_search" USING btree ("rentAmount");

CREATE INDEX "master_search_sellingPrice_idx" ON "public"."master_search" USING btree ("sellingPrice");

CREATE INDEX "master_search_postMover_idx" ON "public"."master_search" USING btree ("postMover");