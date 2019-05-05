DROP TABLE IF EXISTS ncoa_submit;
CREATE TABLE "ncoa_submit" (
"id" SERIAL NOT NULL PRIMARY KEY,
"recActiveFlag" char(1) COLLATE "default" DEFAULT 'Y',
"masterId" int4,
"batchNo" varchar(32),
"preMoverFirstName" varchar(50) COLLATE "default",
"preMoverLastName" varchar(50) COLLATE "default",
"normalizedAddress" varchar(256) COLLATE "default",
"city" varchar(64) COLLATE "default",
"province" varchar(64) COLLATE "default",
"postalCode" varchar(12) COLLATE "default",
"createdTimestamp" timestamp(6)
);