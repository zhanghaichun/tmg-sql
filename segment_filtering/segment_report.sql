drop table if exists segment_report;
CREATE TABLE "public"."segment_report" (
  "id" serial NOT NULL primary key,
  "userId" int,
  "reportName" varchar(128) COLLATE "default",
  "regionDesc" varchar(256),
  "filters" jsonb,
  "createdTimestamp" TIMESTAMP default CURRENT_TIMESTAMP,
  "recActiveFlag" char(1) default 'Y'
);


CREATE INDEX "segment_report_reportName_idx" ON "public"."segment_report" USING btree ("reportName");