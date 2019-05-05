select "preMoverPhoneNumber", "postMoverPhoneNumber" from estate_master
limit 100;

select "preMoverPhoneNumber", "postMoverPhoneNumber" from estate_master
where "preMoverPhoneNumber" is not null
  and "postMoverPhoneNumber" is not null
  and "preMoverFirstName" = 'Ron'
  and "preMoverLastName" = 'Townley'
limit 100;

635-2946

select "preMoverFirstName", "preMoverLastName" from estate_master
where ("preMoverPhoneNumber" like '%635-2946%'
or "postMoverPhoneNumber" like '%635-2946%');

CREATE TABLE "public"."estate_master" (
"id" int4 DEFAULT nextval('estate_master_id_seq'::regclass) NOT NULL,
"listingDate" timestamp(6),
"delistedDate" timestamp(6),
"projectDelistedDate" timestamp(6),
"projectClosingDate" timestamp(6),
"listingPrice" numeric(20,2),
"projectSoldPrice" numeric(20,2),
"unit" varchar(100) COLLATE "default",
"streetNumber" varchar(100) COLLATE "default",
"streetName" varchar(255) COLLATE "default",
"address" varchar(500) COLLATE "default",
"fullAddress" varchar(300) COLLATE "default",
"district" varchar(10) COLLATE "default",
"city" varchar(100) COLLATE "default",
"province" varchar(50) COLLATE "default",
"postalCode" varchar(20) COLLATE "default",
"buildingTypeId" int4,
"tradeTypeId" int4,
"latitude" varchar(20) COLLATE "default",
"longitude" varchar(20) COLLATE "default",
"priceRangeId" int4,
"isDoNotContact" char(1) COLLATE "default" DEFAULT 'N'::bpchar,
"preMoverFirstName" varchar(50) COLLATE "default",
"preMoverLastName" varchar(50) COLLATE "default",
"preMoverPhoneNumber" varchar COLLATE "default",
"preMoverDNCallFlag" char(1) COLLATE "default" DEFAULT 'N'::bpchar,
"postMoverFirstName" varchar(255) COLLATE "default" DEFAULT NULL::character varying,
"postMoverLastName" varchar(255) COLLATE "default",
"postMoverPhoneNumber" varchar(50) COLLATE "default",
"postMoverTimestamp" timestamp(6),
"postMoverDNCallFlag" char(1) COLLATE "default" DEFAULT 'N'::bpchar,
"projectDaysOnMarket" int2,
"projectDaysOnMarketFrom" varchar(20) COLLATE "default",
"mlsNumber" varchar(50) COLLATE "default",
"pMlsNumber" varchar(50) COLLATE "default",
"contactFromApi" varchar(100) COLLATE "default",
"contactInfoFrom" int4,
"contactInfoReferenceId" int4,
"contactInfoTimestamp" timestamp(6),
"createFromSourceId" int4,
"createFromSourceDataId" int4,
"postMoverInfoFrom" int4,
"postMoverReferenceId" int4,
"provinceId" int4,
"streetType" varchar(255) COLLATE "default",
"createdTimestamp" timestamp(6),
"recActiveFlag" char(1) COLLATE "default" DEFAULT 'Y'::bpchar,
"waitPostMoverProcessFlag" char(1) COLLATE "default" DEFAULT 'N'::bpchar,
"waitPreMoverProcessFlag" char(1) COLLATE "default" DEFAULT 'N'::bpchar,
"accuracyAddress" varchar(500) COLLATE "default",
"activeFlag" char(1) COLLATE "default" DEFAULT 'Y'::bpchar,
CONSTRAINT "estate_master_pkey" PRIMARY KEY ("id")
)
WITH (OIDS=FALSE)
;

ALTER TABLE "public"."estate_master" OWNER TO "root";



CREATE INDEX "estate_master_createFromSourceDataId_idx" ON "public"."estate_master" USING btree ("createFromSourceDataId");

CREATE INDEX "estate_master_mlsNumber_idx" ON "public"."estate_master" USING btree ("mlsNumber");

CREATE INDEX "estate_master_pMlsNumber_idx" ON "public"."estate_master" USING btree ("pMlsNumber");

CREATE INDEX "estate_master_postalCode_idx" ON "public"."estate_master" USING btree ("postalCode");

CREATE INDEX "estate_master_provinceId_idx" ON "public"."estate_master" USING btree ("provinceId");

CREATE INDEX "estate_master_streetName_idx" ON "public"."estate_master" USING btree ("streetName");

CREATE INDEX "estate_master_streetNumber_idx" ON "public"."estate_master" USING btree ("streetNumber");

CREATE INDEX "estate_master_tradeTypeId_idx" ON "public"."estate_master" USING btree ("tradeTypeId");

CREATE INDEX "estate_master_unit_idx" ON "public"."estate_master" USING btree ("unit");

CREATE INDEX "estate_master_waitPreMoverProcessFlag_idx" ON "public"."estate_master" USING btree ("waitPreMoverProcessFlag");



CREATE TRIGGER "_tmg_db_replication_denyaccess" BEFORE INSERT OR UPDATE OR DELETE ON "public"."estate_master"
FOR EACH ROW
EXECUTE PROCEDURE "_tmg_db_replication"."denyaccess"('_tmg_db_replication');

CREATE TRIGGER "_tmg_db_replication_logtrigger" AFTER INSERT OR UPDATE OR DELETE ON "public"."estate_master"
FOR EACH ROW
EXECUTE PROCEDURE "_tmg_db_replication"."logtrigger"('_tmg_db_replication', '1', 'k');

CREATE TRIGGER "_tmg_db_replication_truncatedeny" BEFORE TRUNCATE ON "public"."estate_master"
FOR EACH STATEMENT
EXECUTE PROCEDURE "_tmg_db_replication"."deny_truncate"();

CREATE TRIGGER "_tmg_db_replication_truncatetrigger" BEFORE TRUNCATE ON "public"."estate_master"
FOR EACH STATEMENT
EXECUTE PROCEDURE "_tmg_db_replication"."log_truncate"('1');