DROP FUNCTION IF EXISTS fn_ncoa_get_upload_data();
CREATE OR REPLACE FUNCTION "fn_ncoa_get_upload_data"()
  RETURNS VARCHAR(64) AS $BODY$

DECLARE
  
  /**
   * 整理出一批需要 ncoa 的数据。
   * 1. 从 estate_master 表中将符合条件的数据导出到 ncoa_estate_master 中，
   * 记录批次号
   * 2. 去除当前批次中地址重复的记录
   * 3. 将去重之后的数据导入到 ncoa_submit 表中。
   */

  V_BATCH_NO VARCHAR(32);
  V_NCOA_COUNT_LIMIT INTEGER DEFAULT 3;
  V_VOID VARCHAR(32);
  
BEGIN
  
  -- TRUNCATE TABLE ncoa_estate_master RESTART IDENTITY CASCADE;

  -- 生成 batch NO
	V_BATCH_NO := TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISS');
  
  -- 从 estate_master 表中查询数据, 插入到 ncoa_estate_master 表中
 	INSERT INTO ncoa_estate_master(
	 		"masterId", 
      "batchNo",
      "createdDate",
	 		"originalFirstName", 
	 		"originalLastName",
	 		"originalAddress", 
	 		"originalCity", 
	 		"originalProvince", 
	 		"originalPostalCode",
      "preProjectClosingDate",
      "createdTimestamp"
 		)
 	SELECT 
 		em.id,
    V_BATCH_NO,
    CURRENT_DATE,
 		em."preMoverFirstName",
 		em."preMoverLastName",
 		em."accuracyAddress",
 		em."city",
 		em."province",
 		em."postalCode",
    em."projectClosingDate",
    CURRENT_TIMESTAMP
 	FROM estate_master em
    LEFT JOIN ncoa_estate_master n ON em."id" = n."masterId"
 	WHERE em."recActiveFlag" = 'Y'
 		AND em."activeFlag" = 'Y'
    AND em."iAddressFlag" = 'Y'
 		AND em."postMoverFirstName" IS NULL
 		AND em."postMoverLastName" IS NULL
    AND (em."preMoverFirstName" IS NOT NULL)
    AND LENGTH(em."preMoverFirstName") > 2 -- First Name 必须是非简写的形式
    AND em."preMoverFirstName" ~ '[a-zA-Z]'
    AND em."preMoverLastName" IS NOT NULL
    AND LENGTH(em."preMoverLastName") > 2 -- Last Name 也必须是非简写的形式
    AND em."preMoverLastName" ~ '[a-zA-Z]'
    AND n."masterId" IS NULL -- 保证 ncoa_estate_master 表中 'masterId' 的唯一性
    AND em."delistedDate" <= (CURRENT_DATE - INTERVAL '90 DAYS')
    AND em."delistedDate" >= (CURRENT_DATE - INTERVAL '120 DAYS')
 	LIMIT 1;

  -- 更新创建日期，以便进行多次 NCOA.
  -- 按照指定的时间间隔。
  -- UPDATE ncoa_estate_master
  -- SET "createdDate" = CURRENT_DATE
  -- WHERE "recActiveFlag" = 'Y'
  --   AND "ncoaActiveFlag" = 'Y'
  --   -- 下面是做 ncoa 的指定时间间隔
  --   AND "createdDate" <= CURRENT_DATE - INTERVAL '30 DAYS' 
  --   AND "createdDate" >= CURRENT_DATE - INTERVAL '36 DAYS';

  -- 更新这批数据的 batch No 和 ncoa workflow status.
  -- UPDATE ncoa_estate_master 
  -- SET "ncoaWorkflowStatusId" = 1, "batchNo" = V_BATCH_NO  -- NCOA Init Data
  -- WHERE "recActiveFlag" = 'Y'
  --   AND "ncoaActiveFlag" = 'Y'
  --   AND "createdDate" = CURRENT_DATE;

  /**
   * 对当前批次数据进行去重。
   */
  -- PERFORM fn_ncoa_distinct_submit_data(V_BATCH_NO);

  -- 向 ncoa_submit 表中插入数据，此表中的数据是需要向
  -- NCOA 提交的最终数据。
  INSERT INTO ncoa_submit(
  		"masterId",
  		"batchNo",
  		"preMoverFirstName",
  		"preMoverLastName",
  		"normalizedAddress",
  		"city",
  		"province",
  		"postalCode",
      "createdTimestamp"
  	)
  SELECT
  	nem."masterId",
  	nem."batchNo",
  	nem."originalFirstName",
  	nem."originalLastName",
  	nem."originalAddress",
  	nem."originalCity",
  	nem."originalProvince",
  	nem."originalPostalCode",
    CURRENT_TIMESTAMP
  FROM ncoa_estate_master nem
  WHERE "recActiveFlag" = 'Y'
  	AND "ncoaActiveFlag" = 'Y'
    AND "batchNo" = V_BATCH_NO;

  -- 数据提交到 ncoa 之后，
  -- 更新 ncoa count 和 ncoa workflow status.
  UPDATE ncoa_estate_master
  SET "ncoaCount" = "ncoaCount" + 1, "ncoaWorkflowStatusId" = 2
  WHERE "recActiveFlag" = 'Y'
  	AND "ncoaActiveFlag" = 'Y'
    AND "batchNo" = V_BATCH_NO;

  -- 通过 ncoa count 更新 ncoa active flag.
  UPDATE ncoa_estate_master   
  SET "ncoaActiveFlag" = 'N'
  WHERE "recActiveFlag" = 'Y'
  	AND "ncoaActiveFlag" = 'Y'
  	AND "ncoaCount" >= V_NCOA_COUNT_LIMIT;

  RETURN V_BATCH_NO;

END 
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
;