DROP FUNCTION IF EXISTS fn_ncoa_avoid_holiday_and_weekend();
CREATE OR REPLACE FUNCTION "fn_ncoa_avoid_holiday_and_weekend"(v_closing_date DATE)
  RETURNS DATE AS $BODY$

DECLARE
    
    v_posints NUMERIC; -- 当前数据得分
    v_random INT; -- 介于-5 到 5 之间的随机数
    v_random_by_points INT; -- 根据分数生产 介于 -5 到 -1 之间的随机数
    v_days INT; -- 浮动天数
    v_random_3 INT; -- 三分之一概率 随机数
    -- v_closing_date DATE; --当前数据的 projected closing date

    v_current_day INT; --当前月的第几天
    v_current_week_day INT; -- 当前是星期几
    v_in_holiday DATE; --查询节日表，检查当前closing date 是否为节日
    v_in_province VARCHAR; --查询节日表，检查这个节日是否再有效的省内

BEGIN
    
    v_random_3 := (random()*(1-3)+3)::INT;

    select "holidayDate",provinces 
        INTO v_in_holiday,v_in_province 
    from canada_holiday 
    WHERE "holidayDate" = to_char(v_closing_date,'YYYY-MM-DD')::DATE;

    IF v_in_holiday IS NOT NULL THEN
        IF v_in_province IS NULL THEN
            v_closing_date := v_closing_date + (v_random_3 || ' day')::INTERVAL;
        ELSEIF string_to_array(v_in_province,',') @> string_to_array(v_master_data."provinceId"::VARCHAR, ',') THEN
            v_closing_date := v_closing_date + (v_random_3 || ' day')::INTERVAL;
        END IF;
    END IF;

    v_current_week_day := EXTRACT(DOW FROM v_closing_date);
    IF v_current_week_day = 6 OR v_current_week_day = 0 THEN
        v_closing_date := v_closing_date + (v_random_3 || ' day')::INTERVAL;
    END IF;

    v_current_week_day := EXTRACT(DOW FROM v_closing_date);
    IF v_current_week_day = 0 THEN
        v_closing_date := v_closing_date + (v_random_3 || ' day')::INTERVAL;
    END IF;

    RETURN v_closing_date::DATE;

END; 
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
;