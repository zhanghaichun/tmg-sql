DROP FUNCTION IF EXISTS fn_ncoa_get_upload_data();
CREATE OR REPLACE FUNCTION "fn_ncoa_get_upload_data"()
  RETURNS VARCHAR(64) AS $BODY$

DECLARE
  
    /**
     * Put together a batch of data.
     * Use the data to carry out NCOA operation.
     */

    V_BATCH_NO VARCHAR(32);
    V_NCOA_COUNT_LIMIT INTEGER DEFAULT 3;
  
BEGIN
  

    V_BATCH_NO := TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISS');
  
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
    WHERE 1 = 1
        AND n."masterId" IS NULL -- Diff the duplicate record.
        AND em."delistedDate" <= (CURRENT_DATE - INTERVAL '90 DAYS')
        AND em."delistedDate" >= (CURRENT_DATE - INTERVAL '120 DAYS')
        AND COALESCE(em."postMoverFirstName", '') = ''
        AND COALESCE(em."postMoverLastName", '') = ''
        AND COALESCE(em."preMoverFirstName", '') != ''
        AND COALESCE(em."preMoverLastName", '') != ''
        AND em."preMoverFirstName" SIMILAR TO '[a-zA-Z]{2,}'
        AND em."preMoverLastName" SIMILAR TO '[a-zA-Z]{2,}'
        AND em."recActiveFlag" = 'Y'
        AND em."activeFlag" = 'Y';

    -- Update created_date
    -- According to specified space of time.
    UPDATE ncoa_estate_master
    SET "createdDate" = CURRENT_DATE
    WHERE 1 = 1
        AND "createdDate" <= CURRENT_DATE - INTERVAL '30 DAYS' 
        AND "createdDate" >= CURRENT_DATE - INTERVAL '36 DAYS'
        AND "ncoaActiveFlag" = 'Y'
        AND "recActiveFlag" = 'Y';

    -- Update ncoa state.
    UPDATE ncoa_estate_master 
    SET "ncoaWorkflowStatusId" = 1, "batchNo" = V_BATCH_NO  -- NCOA Init Data
    WHERE "recActiveFlag" = 'Y'
        AND "ncoaActiveFlag" = 'Y'
        AND "createdDate" = CURRENT_DATE;

    -- Distinct the repeated address records.
    PERFORM fn_ncoa_distinct_submit_data(V_BATCH_NO);

    -- Insert data records into noca_submit table that
    -- submitting the data to NCOA.
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

    -- After submitting the records, update the ncoa state.
    UPDATE ncoa_estate_master
    SET "ncoaCount" = "ncoaCount" + 1, "ncoaWorkflowStatusId" = 2
    WHERE "recActiveFlag" = 'Y'
    	AND "ncoaActiveFlag" = 'Y'
        AND "batchNo" = V_BATCH_NO;

    -- If a record have NCOA many times, Inactivate the record.
    -- there is a bound.
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