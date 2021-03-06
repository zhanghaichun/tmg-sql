DROP FUNCTION IF EXISTS fn_calculate_delisted_date();
CREATE OR REPLACE FUNCTION "fn_calculate_delisted_date"(
    PARAM_PROJECT_CLOSING_DATE DATE,
    PARAM_MASTER_ID INT
) RETURNS DATE AS $BODY$

DECLARE
    
    /**
        If the delisted date of matched record is null, fill a value by calculating.
    */

    V_DELISTED_DATE DATE;
    V_LISTING_DATE DATE;
    V_INTERVAL_DAYS INT;

BEGIN
    
    SELECT "listingDate" FROM estate_master
        INTO V_LISTING_DATE
    WHERE id = PARAM_MASTER_ID;

    V_INTERVAL_DAYS :=  (PARAM_PROJECT_CLOSING_DATE - V_LISTING_DATE::DATE) * 1 / 3;

    -- The limit value is 60
    IF V_INTERVAL_DAYS > 60 THEN
        V_INTERVAL_DAYS := 60;
    END IF;

    RETURN PARAM_PROJECT_CLOSING_DATE - V_INTERVAL_DAYS;

END; 
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
;