DROP FUNCTION IF EXISTS fn_ncoa_distinct_submit_data(PARAM_BATCH_NO VARCHAR(32));
CREATE OR REPLACE FUNCTION "fn_ncoa_distinct_submit_data"(PARAM_BATCH_NO VARCHAR(32))
    RETURNS "pg_catalog"."void" AS $BODY$

DECLARE
    
    /**
     * Distinct the repeated address record.
     */
    V_ADDRESS_DATA RECORD;
    V_ADDRESS_DATA2 RECORD;
    V_ADDRESS VARCHAR;
    V_REFERENCE_MASTER_ID INT;
    V_REFERENCE_MASTER_ID2 INT;

BEGIN
    
    -- First Filteration. (address + postal code)
    FOR V_ADDRESS_DATA IN 
        SELECT
            COUNT (1),
            nem."originalAddress" AS "address",
            SUBSTRING (nem."originalPostalCode", 1, 3) AS "postalCode"
        FROM ncoa_estate_master nem
        WHERE 1 = 1
            AND nem."batchNo" = PARAM_BATCH_NO
        GROUP BY
            nem."originalAddress",
            SUBSTRING (nem."originalPostalCode", 1, 3)
        HAVING
            COUNT (1) = 2
        ORDER BY
            COUNT (1) DESC


    LOOP

        -- Abstract the record that trade_type_id = 1
        V_REFERENCE_MASTER_ID := (
            SELECT em."id" 
            FROM estate_master em
            WHERE 1 = 1
                AND em."tradeTypeId" = 1
                AND em."accuracyAddress" = V_ADDRESS_DATA."address"
                AND em."postalCode" LIKE V_ADDRESS_DATA."postalCode"
            LIMIT 1
        );

        -- Update master_id of trade_type_id = 2
        UPDATE ncoa_estate_master
        SET "referenceMasterId" = V_REFERENCE_MASTER_ID, "ncoaActiveFlag" = 'N'
        FROM (
                SELECT em."id"
                FROM  estate_master em 
                WHERE 1 = 1
                    AND em."tradeTypeId" = 2
                    AND em."accuracyAddress" = V_ADDRESS_DATA."address"
                    AND em."postalCode" LIKE V_ADDRESS_DATA."postalCode"
            ) em
        WHERE
            em."id" = ncoa_estate_master."masterId";

    END LOOP;


    -- Second Filteration. (address + city + province)
    <<LABEL1>> 
    FOR V_ADDRESS_DATA2 IN 
        SELECT
            COUNT(1),
            nem."originalAddress" AS "address",
            nem."originalProvince" AS "province",
            nem."originalCity" AS "city"
        FROM ncoa_estate_master nem
        WHERE 1 = 1
            AND nem."batchNo" = PARAM_BATCH_NO
        GROUP BY
            nem."originalAddress",
            nem."originalProvince",
            nem."originalCity"
        HAVING COUNT (1) = 2
        ORDER BY COUNT (1) DESC

    LOOP

        -- Search id of trade_type_id = 1 record.
        V_REFERENCE_MASTER_ID2 := (
            SELECT em."id"
            FROM estate_master em 
            WHERE 1 = 1
                AND em."tradeTypeId" = 1
                AND em."accuracyAddress" = V_ADDRESS_DATA2."address"
                AND em."province" = V_ADDRESS_DATA2."province"
                AND em."city" = V_ADDRESS_DATA2."city"
            LIMIT 1
        );

        -- Update the record that trade_type_id = 2
        UPDATE ncoa_estate_master
        SET "referenceMasterId" = V_REFERENCE_MASTER_ID2,"ncoaActiveFlag" = 'N'
        FROM (
                SELECT em."id"
                FROM estate_master em
                WHERE 1 = 1
                    AND em."tradeTypeId" = 2
                    AND em."accuracyAddress" = V_ADDRESS_DATA2."address"
                    AND em."province" = V_ADDRESS_DATA2."province"
                    AND em."city" = V_ADDRESS_DATA2."city"
            ) em
        WHERE
            em."id" = ncoa_estate_master."masterId";

    END LOOP LABEL1; 
      
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE;