DROP FUNCTION IF EXISTS fn_ncoa_deal_result_data(PARAM_BATCH_NO VARCHAR(32));
CREATE OR REPLACE FUNCTION "fn_ncoa_deal_result_data"(PARAM_BATCH_NO VARCHAR(32))
  RETURNS "pg_catalog"."void" AS $BODY$

DECLARE

  -- 这是新逻辑
  
  /**
   * 将 ncoa 返回的数据进行处理，
   * 1, 首先更新 ncoa_estate_master 表中相关数据的状态
   * 2, 根据 master id 更新 estate_master 表中对应数据的状态
   *   如果是新地址，直接插入到 ncoa_estate_master 表中，
   *   标记为未处理的状态。
   * 3.如果是系统中原有的数据， 那么就更新对应数据的 post mover 数据。
   */
  V_NCOA_PROCESSED_DATA_RECORD RECORD;
  V_MATCHED_COUNT INT; 
  V_MATCHED_COUNT2 INT;

  V_CANADA_POST_DELAY_PERIOD INT DEFAULT 5; -- canada post mover 间隔天数
  V_NCOA_POST_DELAY_PERIOD INT DEFAULT 5; -- NCOA POST MOVER 间隔天数。

  V_PRE_MOVER_FIRST_NAME VARCHAR(64);
  V_PRE_MOVER_LAST_NAME VARCHAR(64);
  V_MASTER_IDS VARCHAR(64);
  V_MASTER_IDS2 VARCHAR(64);
  
  V_NCOA_PROJECT_CLOSING_DATE DATE;

BEGIN
  
  -- NCOA 返回的数据中 postal code 中间有空格。
  /*UPDATE ncoa_result
  SET "postalCode" = REPLACE("postalCode", ' ', '')
  WHERE "recActiveFlag" = 'Y'
    AND "batchNo" = PARAM_BATCH_NO;*/

  -- According to delay days, calculate project closing date.
  V_NCOA_PROJECT_CLOSING_DATE := CURRENT_DATE - (V_CANADA_POST_DELAY_PERIOD + V_CANADA_POST_DELAY_PERIOD);

  /**
   * Updating ncoa_estate_master table according to batchNo of ncoa_result table .
   */
  FOR V_NCOA_PROCESSED_DATA_RECORD IN
    SELECT *
    FROM ncoa_result nr
    WHERE nr."recActiveFlag" = 'Y'
      AND nr."batchNo" = PARAM_BATCH_NO
  LOOP

  --   -- 更新 NCOA 流程状态
    UPDATE ncoa_estate_master
    SET 
      "ncoaWorkflowStatusId" = 3,
      "ncoa" = V_NCOA_PROCESSED_DATA_RECORD."ncoa",
      "firstName" = V_NCOA_PROCESSED_DATA_RECORD."firstName",
      "lastName" = V_NCOA_PROCESSED_DATA_RECORD."lastName",
      "address" = V_NCOA_PROCESSED_DATA_RECORD."address" ,
      "city" = V_NCOA_PROCESSED_DATA_RECORD."city",
      "provAcronym" = V_NCOA_PROCESSED_DATA_RECORD."provAcronym",
      "postalCode" = V_NCOA_PROCESSED_DATA_RECORD."postalCode",
      "address2"  = V_NCOA_PROCESSED_DATA_RECORD."address2",
      "country" = V_NCOA_PROCESSED_DATA_RECORD."country",
      "originalFirstName" = V_NCOA_PROCESSED_DATA_RECORD."originalFirstName",
      "originalLastName" = V_NCOA_PROCESSED_DATA_RECORD."originalLastName",
      "originalAddress" = V_NCOA_PROCESSED_DATA_RECORD."originalAddress" ,
      "originalCity" = V_NCOA_PROCESSED_DATA_RECORD."originalCity",
      "originalProvince" = V_NCOA_PROCESSED_DATA_RECORD."originalProvince",
      "originalPostalCode" = V_NCOA_PROCESSED_DATA_RECORD."originalPostalCode",
      "originalAddress2" = V_NCOA_PROCESSED_DATA_RECORD."originalAddress2" ,
      "phone" = V_NCOA_PROCESSED_DATA_RECORD."phone",
      "bagbun" = V_NCOA_PROCESSED_DATA_RECORD."bagbun" ,
      "dmc" = V_NCOA_PROCESSED_DATA_RECORD."dmc" ,
      "sortedId" = V_NCOA_PROCESSED_DATA_RECORD."sortedId",
      "listOrder" = V_NCOA_PROCESSED_DATA_RECORD."listOrder",
      "dupes" = V_NCOA_PROCESSED_DATA_RECORD."dupes",
      "isDupe" = V_NCOA_PROCESSED_DATA_RECORD."isDupe",
      "isCommon" = V_NCOA_PROCESSED_DATA_RECORD."isCommon",
      "correct" = V_NCOA_PROCESSED_DATA_RECORD."correct",
      "correctText" = V_NCOA_PROCESSED_DATA_RECORD."correctText" ,
      "valid" = V_NCOA_PROCESSED_DATA_RECORD."valid",
      "mergefile" = V_NCOA_PROCESSED_DATA_RECORD."mergefile" ,
      "addType" = V_NCOA_PROCESSED_DATA_RECORD."addType",
      "breaks" = V_NCOA_PROCESSED_DATA_RECORD."breaks",
      "iaddstatus" = V_NCOA_PROCESSED_DATA_RECORD."iaddstatus",
      "bun" = V_NCOA_PROCESSED_DATA_RECORD."bun",
      "bunType" = V_NCOA_PROCESSED_DATA_RECORD."bunType",
      "bag" = V_NCOA_PROCESSED_DATA_RECORD."bag",
      "lang" = V_NCOA_PROCESSED_DATA_RECORD."lang",
      "oel" = V_NCOA_PROCESSED_DATA_RECORD."oel",
      "price" = V_NCOA_PROCESSED_DATA_RECORD."price",
      "addressLocale" = V_NCOA_PROCESSED_DATA_RECORD."addressLocale",
      "dnmCodes" = V_NCOA_PROCESSED_DATA_RECORD."dnmCodes",
      "mvupCodes" = V_NCOA_PROCESSED_DATA_RECORD."mvupCodes",
      "flgGeoLat" = V_NCOA_PROCESSED_DATA_RECORD."flgGeoLat",
      "flgGeoLong" = V_NCOA_PROCESSED_DATA_RECORD."flgGeoLong",
      "flgNearestpc" = V_NCOA_PROCESSED_DATA_RECORD."flgNearestpc",
      "flgDistance" = V_NCOA_PROCESSED_DATA_RECORD."flgDistance",
      "flgTimezone" = V_NCOA_PROCESSED_DATA_RECORD."flgTimezone",
      "caWeightG" = V_NCOA_PROCESSED_DATA_RECORD."caWeightG",
      "caThicknessMM" = V_NCOA_PROCESSED_DATA_RECORD."caThicknessMM",
      "barcode" = V_NCOA_PROCESSED_DATA_RECORD."barcode",
      "resbus" = V_NCOA_PROCESSED_DATA_RECORD."resbus",
      "iAddressId" = V_NCOA_PROCESSED_DATA_RECORD."iAddressId",
      "pallet" = V_NCOA_PROCESSED_DATA_RECORD."pallet",
      "streetNumber" = V_NCOA_PROCESSED_DATA_RECORD."streetNumber",
      "streetName" = V_NCOA_PROCESSED_DATA_RECORD."streetName",
      "streetType" = V_NCOA_PROCESSED_DATA_RECORD."streetType",
      "streetDir" = V_NCOA_PROCESSED_DATA_RECORD."streetDir",
      "suite" = V_NCOA_PROCESSED_DATA_RECORD."suite",
      "poboxNumber" = V_NCOA_PROCESSED_DATA_RECORD."poboxNumber",
      "rrNumber" = V_NCOA_PROCESSED_DATA_RECORD."rrNumber",
      "status" = V_NCOA_PROCESSED_DATA_RECORD."status",
      "comment" = V_NCOA_PROCESSED_DATA_RECORD."comment",
      "addExtra" = V_NCOA_PROCESSED_DATA_RECORD."addExtra"      
    WHERE "recActiveFlag" = 'Y' 
      AND (
            "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
            OR
            "referenceMasterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
          );

    -- 更新 ncoa_estate_master 表中 ncoa active flag。
    UPDATE ncoa_estate_master
    SET "ncoaActiveFlag" = (
        CASE 
          WHEN V_NCOA_PROCESSED_DATA_RECORD."ncoa" IN ('AI', 'AB', 'AF', 'UM') THEN
            'N'
          ELSE
            'Y'
        END
      )
    WHERE "recActiveFlag" = 'Y'
      AND (
            "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
            OR
            "referenceMasterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
          );

    -- 根据 ncoa 之后的状态来处理返回的数据。
    IF ( V_NCOA_PROCESSED_DATA_RECORD."ncoa" IN ('AI', 'AB', 'AF') ) THEN -- 已搬家
      
      -- 更新 project closing date.
      UPDATE estate_master
      SET "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE
      WHERE 1 = 1 
        AND "id" in (
            SELECT "masterId" FROM ncoa_estate_master
            WHERE "recActiveFlag" = 'Y'
              AND (
                  "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
                  OR
                  "referenceMasterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
                )
          );

      -- 检索搬家后的 '新地址' 是否存在于数据库中
      -- address + postal code 查询
      SELECT COUNT(1), ARRAY_TO_STRING( ARRAY( SELECT unnest(array_agg(id)) ), ',') 
        INTO 
          V_MATCHED_COUNT,
          V_MASTER_IDS 
      FROM estate_master em
      WHERE 1 = 1
        AND em."recActiveFlag" = 'Y'
        AND em."activeFlag" = 'Y'
        AND LOWER(em."accuracyAddress") = LOWER(V_NCOA_PROCESSED_DATA_RECORD."address")
        AND SUBSTRING(em."postalCode", 1, 3) = SUBSTRING(V_NCOA_PROCESSED_DATA_RECORD."postalCode", 1, 3);

      -- address + province + city 查询
      SELECT COUNT(1), ARRAY_TO_STRING( ARRAY( SELECT unnest(array_agg(em.id)) ), ',')
        INTO 
          V_MATCHED_COUNT2,
          V_MASTER_IDS2 
      FROM estate_master em
        LEFT JOIN province p ON p."id" = em."provinceId" 
      WHERE 1 = 1
        AND em."recActiveFlag" = 'Y'
        AND em."activeFlag" = 'Y'
        AND LOWER(em."accuracyAddress") = LOWER(V_NCOA_PROCESSED_DATA_RECORD."address")
        AND UPPER(em."city") = UPPER(V_NCOA_PROCESSED_DATA_RECORD."city")
        AND p."code" = V_NCOA_PROCESSED_DATA_RECORD."provAcronym";

      IF (V_MATCHED_COUNT > 0 OR V_MATCHED_COUNT2 > 0) THEN -- 系统中存在返回的 '新地址'
        
        IF V_MATCHED_COUNT > 0 THEN

          UPDATE ncoa_estate_master
          SET "ncoaMatchedMasterIds" = V_MASTER_IDS
          WHERE "recActiveFlag" = 'Y'
              AND (
                  "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
                  OR
                  "referenceMasterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
                );

          SELECT em."preMoverFirstName", em."preMoverLastName" 
            INTO 
              V_PRE_MOVER_FIRST_NAME,
              V_PRE_MOVER_LAST_NAME
          FROM estate_master em
          WHERE em."recActiveFlag" = 'Y'
            AND em."activeFlag" =  'Y'
            AND LOWER(em."accuracyAddress") = LOWER(V_NCOA_PROCESSED_DATA_RECORD."address")
            AND SUBSTRING(em."postalCode", 1, 3) = SUBSTRING(V_NCOA_PROCESSED_DATA_RECORD."postalCode", 1, 3);

          IF V_PRE_MOVER_FIRST_NAME = V_NCOA_PROCESSED_DATA_RECORD."firstName" 
            AND V_PRE_MOVER_LAST_NAME = V_NCOA_PROCESSED_DATA_RECORD."lastName" THEN

            -- address 和 postal code 前三位
            UPDATE estate_master
            SET
              "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE,
              "preMoverFirstName" = NULL,
              "preMoverLastName" = NULL,
              "preMoverPhoneNumber" = NULL,
              "postMoverFirstName" = V_NCOA_PROCESSED_DATA_RECORD."firstName",
              "postMoverLastName" = V_NCOA_PROCESSED_DATA_RECORD."lastName",
              "postMoverInfoFrom" = 6 -- NCOA
            WHERE 1 = 1
              AND "recActiveFlag" = 'Y'
              AND "activeFlag" = 'Y'
              AND LOWER("accuracyAddress") = LOWER(V_NCOA_PROCESSED_DATA_RECORD."address")
              AND SUBSTRING("postalCode", 1, 3) = SUBSTRING(V_NCOA_PROCESSED_DATA_RECORD."postalCode", 1, 3);

          ELSE

            -- address 和 postal code 前三位
            UPDATE estate_master
            SET
              "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE,
              "postMoverFirstName" = V_NCOA_PROCESSED_DATA_RECORD."firstName",
              "postMoverLastName" = V_NCOA_PROCESSED_DATA_RECORD."lastName",
              "postMoverInfoFrom" = 6 -- NCOA
            WHERE 1 = 1
              AND "recActiveFlag" = 'Y'
              AND "activeFlag" = 'Y'
              AND LOWER("accuracyAddress") = LOWER(V_NCOA_PROCESSED_DATA_RECORD."address")
              AND SUBSTRING("postalCode", 1, 3) = SUBSTRING(V_NCOA_PROCESSED_DATA_RECORD."postalCode", 1, 3);

          END IF;

        END IF;

        IF V_MATCHED_COUNT2 > 0 THEN

          UPDATE ncoa_estate_master
          SET "ncoaMatchedMasterIds" = V_MASTER_IDS2
          WHERE "recActiveFlag" = 'Y'
              AND (
                  "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
                  OR
                  "referenceMasterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
                );

          SELECT em."preMoverFirstName", em."preMoverLastName" 
            INTO 
              V_PRE_MOVER_FIRST_NAME,
              V_PRE_MOVER_LAST_NAME
          FROM estate_master em LEFT JOIN province p ON p."id" = em."provinceId"
          WHERE em."recActiveFlag" = 'Y'
            AND em."activeFlag" =  'Y'
            AND LOWER(em."accuracyAddress") = LOWER(V_NCOA_PROCESSED_DATA_RECORD."address")
            AND LOWER(em."city") = LOWER(V_NCOA_PROCESSED_DATA_RECORD."city")
            AND p."code" = V_NCOA_PROCESSED_DATA_RECORD."provAcronym";


          IF V_PRE_MOVER_FIRST_NAME = V_NCOA_PROCESSED_DATA_RECORD."firstName" 
            AND V_PRE_MOVER_LAST_NAME = V_NCOA_PROCESSED_DATA_RECORD."lastName" THEN

            -- address， province, city 作为补充。
            UPDATE estate_master em
            SET
              "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE,
              "preMoverFirstName" = NULL,
              "preMoverLastName" = NULL,
              "preMoverPhoneNumber" = NULL,
              "postMoverFirstName" = V_NCOA_PROCESSED_DATA_RECORD."firstName",
              "postMoverLastName" = V_NCOA_PROCESSED_DATA_RECORD."lastName",
              "postMoverInfoFrom" = 6 -- NCOA
            FROM province p
            WHERE 1 = 1
              AND em."recActiveFlag" = 'Y'
              AND em."activeFlag" = 'Y'
              AND p."id" = em."provinceId"
              AND LOWER(em."accuracyAddress") = LOWER(V_NCOA_PROCESSED_DATA_RECORD."address")
              AND LOWER(em."city") = LOWER(V_NCOA_PROCESSED_DATA_RECORD."city")
              AND p."code" = V_NCOA_PROCESSED_DATA_RECORD."provAcronym";

          ELSE

            -- address， province, city 作为补充。
            UPDATE estate_master em
            SET
              "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE,
              "postMoverFirstName" = V_NCOA_PROCESSED_DATA_RECORD."firstName",
              "postMoverLastName" = V_NCOA_PROCESSED_DATA_RECORD."lastName",
              "postMoverInfoFrom" = 6 -- NCOA
            FROM province p
            WHERE 1 = 1
              AND em."recActiveFlag" = 'Y'
              AND em."activeFlag" = 'Y'
              AND p."id" = em."provinceId"
              AND LOWER(em."accuracyAddress") = LOWER(V_NCOA_PROCESSED_DATA_RECORD."address")
              AND LOWER(em."city") = LOWER(V_NCOA_PROCESSED_DATA_RECORD."city")
              AND p."code" = V_NCOA_PROCESSED_DATA_RECORD."provAcronym";

          END IF;

        END IF;

        -- 更新 ncoa 流程状态。
        UPDATE ncoa_estate_master
        SET "ncoaWorkflowStatusId" = 4
        WHERE "recActiveFlag" = 'Y'
          AND (
            "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
            OR
            "referenceMasterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
          );

      ELSE -- 系统中不存在返回的新地址

        UPDATE ncoa_estate_master
        SET "ncoaWorkflowStatusId" = 5
        WHERE "recActiveFlag" = 'Y'
          AND (
            "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
            OR
            "referenceMasterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId"
          );

      END IF;

    END IF;

  END LOOP;

  -- Update 'UN' flag data
  UPDATE ncoa_estate_master
  SET ncoa = 'UN', "ncoaActiveFlag" = 'N'
  WHERE "recActiveFlag" = 'Y'
    AND COALESCE(ncoa, '') = ''
    AND "batchNo" = PARAM_BATCH_NO;

  UPDATE estate_master em
  SET "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE
  FROM ncoa_estate_master nem
  WHERE nem."recActiveFlag" = 'Y'
    AND nem.ncoa = 'UN'
    AND nem."masterId" = em.id
    AND nem."batchNo" = PARAM_BATCH_NO;

END; 
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
;