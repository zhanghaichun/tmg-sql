DROP FUNCTION IF EXISTS fn_ncoa_deal_result_data(PARAM_BATCH_NO VARCHAR(32));
CREATE OR REPLACE FUNCTION "fn_ncoa_deal_result_data"(PARAM_BATCH_NO VARCHAR(32))
  RETURNS "pg_catalog"."void" AS $BODY$

DECLARE
  
    /**
     * Deal with the ncoa result data records.
     */

    V_NCOA_PROCESSED_DATA_RECORD RECORD;

    V_CANADA_POST_DELAY_PERIOD INT DEFAULT 5; 
    V_NCOA_POST_DELAY_PERIOD INT DEFAULT 5;

    V_NCOA_PROJECT_CLOSING_DATE DATE;

    
    -- For postal code matching.
    V_MATCHED_ID INT;
    V_MATCHED_DELISTED_DATE DATE; 
    V_MATCHED_PROJECT_CLOSING_DATE DATE;

    V_PRE_MOVER_FIRST_NAME VARCHAR(64);
    V_PRE_MOVER_LAST_NAME VARCHAR(64);
    V_POST_MOVER_FIRST_NAME VARCHAR(64);
    V_POST_MOVER_LAST_NAME VARCHAR(64); 

    -- For city, province matching.
    V_MATCHED_ID2 INT;
    V_MATCHED_PROJECT_CLOSING_DATE2 DATE;
    V_MATCHED_DELISTED_DATE2 DATE;

    V_PRE_MOVER_FIRST_NAME2 VARCHAR(64);
    V_PRE_MOVER_LAST_NAME2 VARCHAR(64);
    V_POST_MOVER_FIRST_NAME2 VARCHAR(64);
    V_POST_MOVER_LAST_NAME2 VARCHAR(64);

    

    

BEGIN
  
    V_NCOA_PROJECT_CLOSING_DATE := fn_ncoa_avoid_holiday_and_weekend(
            CURRENT_DATE - (V_CANADA_POST_DELAY_PERIOD + V_CANADA_POST_DELAY_PERIOD)
        );

    -- Manually, import ncoa result excel data to ncoa_result DB table.
    FOR V_NCOA_PROCESSED_DATA_RECORD IN
        SELECT *
        FROM ncoa_result nr
        WHERE nr."batchNo" = PARAM_BATCH_NO
        -- LIMIT 10
    LOOP

        UPDATE ncoa_estate_master
        SET 
            "ncoaWorkflowStatusId" = 3, -- ncoa state.
            "ncoa" = V_NCOA_PROCESSED_DATA_RECORD."ncoa",
            "firstName" = V_NCOA_PROCESSED_DATA_RECORD."firstName",
            "lastName" = V_NCOA_PROCESSED_DATA_RECORD."lastName",
            "address" = V_NCOA_PROCESSED_DATA_RECORD."address" ,
            "city" = V_NCOA_PROCESSED_DATA_RECORD."city",
            "provAcronym" = V_NCOA_PROCESSED_DATA_RECORD."provAcronym",
            "postalCode" = replace(V_NCOA_PROCESSED_DATA_RECORD."postalCode", ' ', ''),
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
          AND "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId";
                
        -- Update ncoa flag.
        UPDATE ncoa_estate_master
        SET "ncoaActiveFlag" = (
            CASE 
                WHEN V_NCOA_PROCESSED_DATA_RECORD."ncoa" IN ('AI', 'AB', 'AF', 'UM') THEN
                    'N'
                WHEN V_NCOA_PROCESSED_DATA_RECORD."ncoa" = 'NM' THEN
                    'Y'
            END
        )
        WHERE "recActiveFlag" = 'Y'
            AND "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId";
               
        -- 根据 ncoa 之后的状态来处理返回的数据。
        IF ( V_NCOA_PROCESSED_DATA_RECORD."ncoa" IN ('AI', 'AB', 'AF') ) THEN -- Moved

            -- Update 'projectClosingDate' in ncoa_estate_master database table.
            UPDATE ncoa_estate_master
            SET "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE
            WHERE "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId" ;

            -- Update 'projectClosingDate' in estate_master database table.
            UPDATE estate_master
            SET "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE
            WHERE "id" = V_NCOA_PROCESSED_DATA_RECORD."masterId";
            
            SELECT 
                em.id ,
                em."delistedDate", 
                em."projectClosingDate",
                COALESCE(em."preMoverFirstName", ''), 
                COALESCE(em."preMoverLastName", ''),
                COALESCE(em."postMoverFirstName", ''),
                COALESCE(em."postMoverLastName", '')
                    INTO 
                        V_MATCHED_ID,
                        V_MATCHED_DELISTED_DATE,
                        V_MATCHED_PROJECT_CLOSING_DATE,
                        V_PRE_MOVER_FIRST_NAME,
                        V_PRE_MOVER_LAST_NAME,
                        V_POST_MOVER_FIRST_NAME,
                        V_POST_MOVER_LAST_NAME
            FROM estate_master em
            WHERE 1 = 1
                AND em."recActiveFlag" = 'Y'
                AND em."activeFlag" = 'Y'
                AND em."accuracyAddress" = V_NCOA_PROCESSED_DATA_RECORD."address"
                AND SUBSTRING(em."postalCode", 1, 3) = SUBSTRING(V_NCOA_PROCESSED_DATA_RECORD."postalCode", 1, 3)
            LIMIT 1;

            SELECT 
                em.id ,
                em."delistedDate", 
                em."projectClosingDate",
                COALESCE(em."preMoverFirstName", ''), 
                COALESCE(em."preMoverLastName", ''),
                COALESCE(em."postMoverFirstName", ''),
                COALESCE(em."postMoverLastName", '')
                    INTO 
                        V_MATCHED_ID2,
                        V_MATCHED_DELISTED_DATE2,
                        V_MATCHED_PROJECT_CLOSING_DATE2,
                        V_PRE_MOVER_FIRST_NAME2,
                        V_PRE_MOVER_LAST_NAME2,
                        V_POST_MOVER_FIRST_NAME2,
                        V_POST_MOVER_LAST_NAME2 
            FROM estate_master em
                LEFT JOIN province p ON p."id" = em."provinceId" 
            WHERE 1 = 1
                AND em."recActiveFlag" = 'Y'
                AND em."activeFlag" = 'Y'
                AND em."accuracyAddress" = V_NCOA_PROCESSED_DATA_RECORD."address"
                AND em."city" = V_NCOA_PROCESSED_DATA_RECORD."city"
                AND p."code" = V_NCOA_PROCESSED_DATA_RECORD."provAcronym"
            LIMIT 1;

            IF (V_MATCHED_ID IS NOT NULL OR V_MATCHED_ID2 IS NOT NULL) THEN -- 系统中存在返回的 '新地址'

                -- Matched by accuracyAddress + postalCode
                IF V_MATCHED_ID IS NOT NULL THEN

                    UPDATE ncoa_estate_master
                    SET "ncoaMatchedMasterIds" = V_MATCHED_ID, 
                        "ncoaMatchedProjectClosingDate" = V_MATCHED_PROJECT_CLOSING_DATE
                    WHERE "recActiveFlag" = 'Y'
                        AND "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId";

                    -- Judging pre mover info.
                    IF V_PRE_MOVER_FIRST_NAME = V_NCOA_PROCESSED_DATA_RECORD."firstName" 
                        AND V_PRE_MOVER_LAST_NAME = V_NCOA_PROCESSED_DATA_RECORD."lastName" THEN

                        IF V_POST_MOVER_FIRST_NAME != V_NCOA_PROCESSED_DATA_RECORD."firstName" OR V_POST_MOVER_LAST_NAME != V_NCOA_PROCESSED_DATA_RECORD."lastName" THEN

                            -- address 和 postal code 前三位
                            UPDATE estate_master
                            SET
                                "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE,
                                "preMoverFirstName" = NULL,
                                "preMoverLastName" = NULL,
                                "preMoverPhoneNumber" = NULL,
                                "postMoverFirstName" = V_NCOA_PROCESSED_DATA_RECORD."firstName",
                                "postMoverLastName" = V_NCOA_PROCESSED_DATA_RECORD."lastName",
                                "postMoverPhoneNumber" = NULL,
                                "postMoverInfoFrom" = 6 -- NCOA
                            WHERE 1 = 1
                                AND "recActiveFlag" = 'Y'
                                AND "activeFlag" = 'Y'
                                AND "accuracyAddress" = V_NCOA_PROCESSED_DATA_RECORD."address"
                                AND SUBSTRING("postalCode", 1, 3) = SUBSTRING(V_NCOA_PROCESSED_DATA_RECORD."postalCode", 1, 3);

                        END IF;

                    ELSE

                        IF V_POST_MOVER_FIRST_NAME != V_NCOA_PROCESSED_DATA_RECORD."firstName" OR V_POST_MOVER_LAST_NAME != V_NCOA_PROCESSED_DATA_RECORD."lastName" THEN

                            -- address 和 postal code 前三位
                            UPDATE estate_master
                            SET
                                "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE,
                                "postMoverFirstName" = V_NCOA_PROCESSED_DATA_RECORD."firstName",
                                "postMoverLastName" = V_NCOA_PROCESSED_DATA_RECORD."lastName",
                                "postMoverPhoneNumber" = NULL,
                                "postMoverInfoFrom" = 6 -- NCOA
                            WHERE 1 = 1
                                AND "recActiveFlag" = 'Y'
                                AND "activeFlag" = 'Y'
                                AND "accuracyAddress" = V_NCOA_PROCESSED_DATA_RECORD."address"
                                AND SUBSTRING("postalCode", 1, 3) = SUBSTRING(V_NCOA_PROCESSED_DATA_RECORD."postalCode", 1, 3);

                        END IF;
                        

                    END IF;

                    -- Updating delisted date when delisted date is null of matched record.
                    IF V_MATCHED_DELISTED_DATE IS NULL THEN

                        UPDATE estate_master
                        SET "delistedDate" = fn_calculate_delisted_date(V_NCOA_PROJECT_CLOSING_DATE, id),
                            "projectDelistedDate" = fn_calculate_delisted_date(V_NCOA_PROJECT_CLOSING_DATE, id)
                        WHERE 1 = 1
                            AND "recActiveFlag" = 'Y'
                            AND "activeFlag" = 'Y'
                            AND "accuracyAddress" = V_NCOA_PROCESSED_DATA_RECORD."address"
                            AND SUBSTRING("postalCode", 1, 3) = SUBSTRING(V_NCOA_PROCESSED_DATA_RECORD."postalCode", 1, 3);

                    END IF;

                END IF;

                -- Matched by accuracyAddress + city + province.
                IF V_MATCHED_ID2 IS NOT NULL THEN

                    UPDATE ncoa_estate_master
                    SET 
                        "ncoaMatchedMasterIds" = V_MATCHED_ID2,
                        "ncoaMatchedProjectClosingDate" = V_MATCHED_PROJECT_CLOSING_DATE2
                    WHERE "recActiveFlag" = 'Y'
                        AND "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId";

                    IF V_PRE_MOVER_FIRST_NAME2 = V_NCOA_PROCESSED_DATA_RECORD."firstName" 
                        AND V_PRE_MOVER_LAST_NAME2 = V_NCOA_PROCESSED_DATA_RECORD."lastName" THEN

                        IF V_POST_MOVER_FIRST_NAME2 != V_NCOA_PROCESSED_DATA_RECORD."firstName" OR V_POST_MOVER_LAST_NAME2 != V_NCOA_PROCESSED_DATA_RECORD."lastName" THEN

                            -- address， province, city 作为补充。
                            UPDATE estate_master em
                            SET
                                "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE,
                                "preMoverFirstName" = NULL,
                                "preMoverLastName" = NULL,
                                "preMoverPhoneNumber" = NULL,
                                "postMoverFirstName" = V_NCOA_PROCESSED_DATA_RECORD."firstName",
                                "postMoverLastName" = V_NCOA_PROCESSED_DATA_RECORD."lastName",
                                "postMoverPhoneNumber" = NULL,
                                "postMoverInfoFrom" = 6 -- NCOA
                            FROM province p
                            WHERE 1 = 1
                                AND em."recActiveFlag" = 'Y'
                                AND em."activeFlag" = 'Y'
                                AND p."id" = em."provinceId"
                                AND em."accuracyAddress" = V_NCOA_PROCESSED_DATA_RECORD."address"
                                AND em."city" = V_NCOA_PROCESSED_DATA_RECORD."city"
                                AND p."code" = V_NCOA_PROCESSED_DATA_RECORD."provAcronym";

                        END IF;

                    ELSE

                        IF V_POST_MOVER_FIRST_NAME2 != V_NCOA_PROCESSED_DATA_RECORD."firstName" OR V_POST_MOVER_LAST_NAME2 != V_NCOA_PROCESSED_DATA_RECORD."lastName" THEN

                            -- address， province, city 作为补充。
                            UPDATE estate_master em
                            SET
                                "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE,
                                "postMoverFirstName" = V_NCOA_PROCESSED_DATA_RECORD."firstName",
                                "postMoverLastName" = V_NCOA_PROCESSED_DATA_RECORD."lastName",
                                "postMoverPhoneNumber" = NULL,
                                "postMoverInfoFrom" = 6 -- NCOA
                            FROM province p
                            WHERE 1 = 1
                                AND em."recActiveFlag" = 'Y'
                                AND em."activeFlag" = 'Y'
                                AND p."id" = em."provinceId"
                                AND em."accuracyAddress" = V_NCOA_PROCESSED_DATA_RECORD."address"
                                AND em."city" = V_NCOA_PROCESSED_DATA_RECORD."city"
                                AND p."code" = V_NCOA_PROCESSED_DATA_RECORD."provAcronym";

                        END IF;
                        

                    END IF;

                    -- When the delistedDate is null
                    IF V_MATCHED_DELISTED_DATE2 IS NULL THEN

                        UPDATE estate_master em
                        SET "delistedDate" = fn_calculate_delisted_date(V_NCOA_PROJECT_CLOSING_DATE, id),
                            "projectDelistedDate" = fn_calculate_delisted_date(V_NCOA_PROJECT_CLOSING_DATE, id)
                        FROM province p
                        WHERE 1 = 1
                            AND em."recActiveFlag" = 'Y'
                            AND em."activeFlag" = 'Y'
                            AND p."id" = em."provinceId"
                            AND em."accuracyAddress" = V_NCOA_PROCESSED_DATA_RECORD."address"
                            AND em."city" = V_NCOA_PROCESSED_DATA_RECORD."city"
                            AND p."code" = V_NCOA_PROCESSED_DATA_RECORD."provAcronym";

                    END IF;

                END IF;

                -- 更新 ncoa 流程状态。
                UPDATE ncoa_estate_master
                SET "ncoaWorkflowStatusId" = 4
                WHERE "recActiveFlag" = 'Y'
                    AND "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId";

            ELSE -- 系统中不存在返回的新地址

                UPDATE ncoa_estate_master
                SET "ncoaWorkflowStatusId" = 5
                WHERE "recActiveFlag" = 'Y'
                    AND "masterId" = V_NCOA_PROCESSED_DATA_RECORD."masterId";

            END IF; -- MATCHED_DELISTED_DATE2 IS NOT NULL OR V_MATCHED_DELISTED_DATE IS NOT NULL

        END IF;

    END LOOP;

    -- Update 'UN' flag data
    UPDATE ncoa_estate_master
    SET ncoa = 'UN', "ncoaActiveFlag" = 'N', "projectClosingDate" = V_NCOA_PROJECT_CLOSING_DATE
    WHERE "recActiveFlag" = 'Y'
        AND ncoa IS NULL
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