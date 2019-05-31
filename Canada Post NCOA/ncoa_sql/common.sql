
CREATE TABLE "public"."iaddress_data" (
"id" serial NOT NULL primary key,
"originalId" int4,
"address" varchar(255) COLLATE "default",
"province" varchar(255) COLLATE "default",
"city" varchar(255) COLLATE "default",
"rval" varchar(16) COLLATE "default",
"postalCode" varchar(255) COLLATE "default",
"sourceFrom" varchar(255) COLLATE "default",
"unit" varchar(255) COLLATE "default",
"unitType" varchar(255) COLLATE "default",
"streetNumber" varchar(255) COLLATE "default",
"streetName" varchar(255) COLLATE "default",
"streetDir" varchar(255) COLLATE "default",
"streetType" varchar(255) COLLATE "default",
"addressType" varchar(255) COLLATE "default",
"reason" varchar(255) COLLATE "default",
"rRNo" varchar(255) COLLATE "default",
"rRType" varchar(255) COLLATE "default",
"eInfo" varchar(255) COLLATE "default",
"gDLong" varchar(255) COLLATE "default"
)
WITH (OIDS=FALSE)
;

ALTER TABLE "public"."iaddress_data" OWNER TO "dealtap"; 


-- Import data from ncoa_submit table.
select "masterId", "batchNo", "preMoverFirstName", "preMoverLastName", "normalizedAddress" as "address", city, province, "postalCode" from ncoa_submit
where "batchNo" = '20190509074250';


-- 20190509074250
-- 20190517001450
-- 20190524003202
-- 上面的这三批数据是需要恢复 project closing date 的。
select * from ncoa_estate_master
where "batchNo" in (
	'20190509074250',
	'20190517001450',
	'20190524003202'
);


