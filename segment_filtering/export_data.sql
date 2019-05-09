SELECT
    e."id" as "Record ID",
    SUBSTRING ( e.latitude FROM '[-0-9]+\.\d{1,6}' ) AS "Lat",
    SUBSTRING ( e.longitude FROM '[-0-9]+\.\d{1,6}' ) AS "Lon",
    (
        CASE
            WHEN COALESCE(eit."bedrooms", '') = '' THEN
                'Data Not Available'
            WHEN (eit.bedrooms :: NUMERIC > 4) THEN
                '4+'
            ELSE
                CAST( CAST(eit.bedrooms :: NUMERIC AS INT) AS CHAR )
        END
    ) AS "Bedrooms",

    (
        CASE
            WHEN COALESCE(eit."bathrooms", '') = '' THEN
                'Data Not Available'
            WHEN (eit.bathrooms :: NUMERIC > 4) THEN
                '4+'
            ELSE
                CAST( CAST(eit.bathrooms :: NUMERIC AS INT) AS CHAR ) 
        END
    ) AS "Bathrooms",

    (
        CASE
            WHEN COALESCE (eit."garageSpaces", '') = '' THEN
                'Data Not Available'
            WHEN COALESCE (eit."garageSpaces", '') = '0' THEN
                'N'
            ELSE
                'Y'
        END
    ) AS "Garage",

    (
        CASE
            WHEN (e."tradeTypeId" = 1) THEN
                'Homeowner'
            WHEN (e."tradeTypeId" = 2) THEN
                'Renter'
            ELSE
                NULL
        END
    ) AS "Occupancy Type",
    
    (
        CASE
            WHEN e."tradeTypeId" = 1 THEN

                CASE
                    WHEN e."listingPrice" <= 500000 THEN
                        '< $500,000'
                    WHEN (
                        e."listingPrice" > 500000
                        AND e."listingPrice" <= 1000000
                    ) THEN
                        '$500,000 - $1,000,000'
                    WHEN (
                        e."listingPrice" > 1000000
                        AND e."listingPrice" <= 1500000
                    ) THEN
                        '$1,000,000 - $1,500,000'
                    WHEN (
                        e."listingPrice" > 1500000
                        AND e."listingPrice" <= 2000000
                    ) THEN
                        '$1,500,000 - $2,000,000'
                    WHEN (
                        e."listingPrice" > 2000000
                        AND e."listingPrice" <= 3000000
                    ) THEN
                        '$2,000,000 - $3,000,000'
                    WHEN e."listingPrice" >= 3000000 THEN
                        '$3,000,000+'
                    ELSE
                        NULL
                END

            ELSE
                NULL
        END
    ) AS "Household Value (Project Selling Price)",

    (
        CASE
            WHEN e."tradeTypeId" = 2 THEN

                CASE
                    WHEN e."listingPrice" <= 1000 THEN
                        '< $1,000/mth'
                    WHEN (
                        e."listingPrice" > 1000
                        AND e."listingPrice" <= 2000
                    ) THEN
                        '$1,000 - $2,000/mth'
                    WHEN (
                        e."listingPrice" > 2000
                        AND e."listingPrice" <= 3000
                    ) THEN
                        '$2,000 - $3,000/mth'
                    WHEN (
                        e."listingPrice" > 3000
                        AND e."listingPrice" <= 4000
                    ) THEN
                        '$3,000 - $4,000/mth'
                    WHEN (
                        e."listingPrice" <= 5000
                    ) THEN
                        '$4,000 - $5,000/mth'
                    WHEN e."listingPrice" > 5000 THEN
                        '$5,000+/mth'
                    ELSE
                        NULL
                END

            ELSE
                NULL
        END
    ) AS "Renting Price",
    (
        CASE
            WHEN (
                eit."approxSquareFootage" IS NOT NULL
                AND eit."approxSquareFootage" ~ '^[0-9]+$'
            ) THEN

                CASE
                    WHEN eit."approxSquareFootage" :: INT < 800 THEN
                        '< 800 sqft'
                    WHEN eit."approxSquareFootage" :: INT < 1200 THEN
                        '800 - 1,200 sqft'
                    WHEN eit."approxSquareFootage" :: INT < 2000 THEN
                        '1,200 - 2,000 sqft'
                    WHEN eit."approxSquareFootage" :: INT < 3000 THEN
                        '2,000 - 3,000 sqft'
                    WHEN  eit."approxSquareFootage" :: INT < 4000 THEN
                        '3,000 - 4,000 sqft'
                    ELSE
                        '4,000+ sqft'
                END

            WHEN eit."approxSquareFootage" ~ '-' THEN
                
                CASE
                    WHEN (
                        split_part(
                            eit."approxSquareFootage",
                            '-',
                            2
                        ) :: NUMERIC < 800
                    ) THEN
                        '< 800 sqft'
                    WHEN (
                        split_part(
                            eit."approxSquareFootage",
                            '-',
                            2
                        ) :: NUMERIC < 1200
                    ) THEN
                        '800 - 1,200 sqft'
                    WHEN (
                        split_part(
                            eit."approxSquareFootage",
                            '-',
                            2
                        ) :: NUMERIC < 2000
                    ) THEN
                        '1,200 - 2,000 sqft'
                    WHEN (
                        split_part(
                            eit."approxSquareFootage",
                            '-',
                            2
                        ) :: NUMERIC < 3000
                    ) THEN
                        '2,000 - 3,000 sqft'
                    WHEN (
                        split_part(
                            eit."approxSquareFootage",
                            '-',
                            2
                        ) :: NUMERIC < 4000
                    ) THEN
                        '3,000 - 4,000 sqft'
                    ELSE
                        '4,000+ sqft'
                END
                
            ELSE
                'Data Not Available'
        END
    ) AS "livingArea",
    
    (
        CASE
            WHEN  e."projectClosingDate" > CURRENT_DATE THEN

                CASE

                    WHEN DATE_PART('DAY', e."projectClosingDate" :: TIMESTAMP - NOW() ) < 30 THEN
                        '< 1 month'
                    WHEN DATE_PART('DAY', e."projectClosingDate" :: TIMESTAMP - NOW() ) < 60 THEN
                        '1 - 2 months'
                    WHEN DATE_PART('DAY', e."projectClosingDate" :: TIMESTAMP - NOW() ) < 90 THEN
                        '2 - 3 months'
                    WHEN DATE_PART('DAY', e."projectClosingDate" :: TIMESTAMP - NOW() ) < 180 THEN
                        '3 - 6 months'
                    WHEN DATE_PART('DAY', e."projectClosingDate" :: TIMESTAMP - NOW() ) < 270 THEN
                        '6 - 9 months'
                    WHEN DATE_PART('DAY', e."projectClosingDate" :: TIMESTAMP - NOW() ) < 365 THEN
                        '9 - 12 months'
                    ELSE
                        '1+ year'
                
                END

            ELSE
                NULL
        END
    ) AS "PreMover (Project Move Date)",

    (
        CASE
            WHEN e."projectClosingDate" <= CURRENT_DATE THEN

                CASE

                    WHEN DATE_PART('DAY', NOW() - e."projectClosingDate" :: TIMESTAMP ) < 30 THEN
                        '< 1 month'
                    WHEN DATE_PART('DAY', NOW() - e."projectClosingDate" :: TIMESTAMP ) < 60 THEN
                        '1 - 2 months'
                    WHEN DATE_PART('DAY', NOW() - e."projectClosingDate" :: TIMESTAMP ) < 90 THEN
                        '2 - 3 months'
                    WHEN DATE_PART('DAY', NOW() - e."projectClosingDate" :: TIMESTAMP ) < 180 THEN
                        '3 - 6 months'
                    WHEN DATE_PART('DAY', NOW() - e."projectClosingDate" :: TIMESTAMP ) < 270 THEN
                        '6 - 9 months'
                    WHEN DATE_PART('DAY', NOW() - e."projectClosingDate" :: TIMESTAMP ) < 365 THEN
                        '9 - 12 months'
                    ELSE
                        '1+ year'
            
                END

            ELSE
                NULL
        END
    ) AS "Post Mover (Time In new Residence)",
    (
        CASE

            WHEN btype.genera = 'Apartment' THEN
                'Multi-dwelling'
            WHEN btype.genera = 'House' THEN
                'House'
            WHEN btype.genera = 'Commercial' THEN
                'Farm/Commercial'
            ELSE
                'Other'
        END
    ) AS "Property Type",
    (
        CASE
            WHEN eit."approxAge" IN ('0-5', '6-10', 'New') THEN
                'Post 2010'
            WHEN COALESCE (eit."approxAge", '') != '' THEN
                'Pre 2010'
            ELSE
                'Data Not Available'
        END
    ) AS "Year Built",

    (
        CASE
            WHEN COALESCE (eit."cableTVIncluded", '') = '' THEN
                'Data Not Available'
            ELSE
                eit."cableTVIncluded"
        END
    ) AS "Cable Available"

FROM estate_master e
    LEFT JOIN estate_master_item eit ON eit."masterId" = e.id
    LEFT JOIN building_type btype ON btype.id = e."buildingTypeId"
WHERE 1 = 1
    AND e."activeFlag" = 'Y'
    AND e."recActiveFlag" = 'Y'
    AND e."tradeTypeId" IN (1,2)
    AND COALESCE(e."projectClosingDate"::CHAR, '') != ''
    AND COALESCE (e."latitude", '') != ''
    AND COALESCE (e."longitude", '') != ''
    AND e."latitude" != '0.0'
    AND e."longitude" != '0.0'
LIMIT 1000;