

update master_search
set "recActiveFlag" = 'N'
where "recActiveFlag" = 'Y'
    and city in ('116TH STREET', '139ST', '15703 69 STRRET', 'AB', 'AB CALGARY', 'AZ', '237 THOMASBERRY', '423 KING STREET', '60 WATERTON BUILDING',
                        '125 SHOREVIEW PLACE', '1856 SAINT-FRANCOIS-XAVIER', '2040 BELGRAVE', '4950 DE LASAVANE', 'BC');

update master_search
set "recActiveFlag" = 'N'
where "recActiveFlag" = 'Y'
    and length(city) <= 2;


-- @deprecated query provinces 
select province, array_length( array(select array_agg(distinct city)), 2) from master_search
where "recActiveFlag" = 'Y'
group by province
HAVING array_length( array(select array_agg(distinct city)), 2) > 1;

-- query cities (old)
SELECT 
    city AS "itemName",
    city AS "itemKey"
FROM master_search
WHERE "recActiveFlag" = 'Y'
    AND province = #{province}
    AND COALESCE(city, '') != ''
GROUP BY city
ORDER BY city;

-- query provinces (old)
SELECT
    province AS "itemKey",
    province AS "itemName"
FROM master_search m
WHERE 1 = 1
    AND m."recActiveFlag" = 'Y'
    AND COALESCE(m.province, '') != ''
GROUP BY province
ORDER BY province;

-- query provinces (new)
SELECT
    "province"
FROM
    (
        SELECT
            "province",
            city
        FROM
            master_search
        GROUP BY
            "province",
            city
        HAVING
            COUNT (1) >= 5
    ) T
GROUP BY
    "province"
HAVING
    COUNT (1) > 1;

-- psql count explaination.
For example, count( * ) yields the total number of input rows; count(f1) yields the number of
input rows in which f1 is non-null, since count ignores nulls; and count(distinct f1) yields
the number of distinct non-null values of f1 


select * from estate_province_city_region
where region is not null;

select * from master_search m
left join estate_province_city_region e on m.province = e.province
where 1 = 1
and ( 
    (e.province = #{province})
    OR
    (e.province = #{province} and e.city = #{city})
    OR
    (e.region = #{municipal})
    OR
    (e.region = #{municipal} and e.city = #{city})
);

-- Province 
select province as "itemKey", province as "itemName" from estate_province_city_region
group by province; -- count represents records amount.

select city as "itemKey", city as "itemName" from estate_province_city_region
where province = 'NUNAVUT';

-- Municipal
select region as "itemKey", region as "itemName" from estate_province_city_region
group by region; -- count represents records amount.

select city as "itemKey", city as "itemName" from estate_province_city_region
where region = 'GTA';
