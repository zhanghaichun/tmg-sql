SELECT
        e."id" as "Record ID",
        SUBSTRING (
            e.latitude
            FROM
                '[-0-9]+\.\d{1,6}'
        ) AS Lat,
        SUBSTRING (
            e.longitude
            FROM
                '[-0-9]+\.\d{1,6}'
        ) AS Lon,
        
        (
            CASE
            
            WHEN (eit.bedrooms :: NUMERIC > 4) THEN
                '4+'
            ELSE
                CAST( CAST(eit.bedrooms :: NUMERIC AS INT) AS CHAR )
            END
        ) AS "Bedrooms",

        (
            CASE
            WHEN (eit.bathrooms :: NUMERIC > 4) THEN
                '4+'
            ELSE
                CAST( CAST(eit.bathrooms :: NUMERIC AS INT) AS CHAR ) 
            END
        ) AS "Bathrooms",

        (
            CASE
            WHEN (
                COALESCE (eit."garageSpaces", '') = '0'
            ) THEN
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
                ''
            END
        ) AS "Occupancy Type",
        
        (
            CASE
            WHEN e."tradeTypeId" = 1 THEN
                (
                    CASE
                    WHEN (
                        e."listingPrice" :: NUMERIC <= 500000
                    ) THEN
                        '< $500,000'
                    WHEN (
                        e."listingPrice" :: NUMERIC > 500000
                        AND e."listingPrice" :: NUMERIC <= 1000000
                    ) THEN
                        '$500,000 - $1,000,000'
                    WHEN (
                        e."listingPrice" :: NUMERIC > 1000000
                        AND e."listingPrice" :: NUMERIC <= 1500000
                    ) THEN
                        '$1,000,000 - $1,500,000'
                    WHEN (
                        e."listingPrice" :: NUMERIC > 1500000
                        AND e."listingPrice" :: NUMERIC <= 2000000
                    ) THEN
                        '$1,500,000 - $2,000,000'
                    WHEN (
                        e."listingPrice" :: NUMERIC > 2000000
                        AND e."listingPrice" :: NUMERIC <= 3000000
                    ) THEN
                        '$2,000,000 - $3,000,000'
                    WHEN (
                        e."listingPrice" :: NUMERIC >= 3000000
                    ) THEN
                        '$3,000,000+'
                    ELSE
                        ''
                    END
                )
            ELSE
                ''
            END
        ) AS "Household Value (Project Selling Price)",

        (
            CASE
            WHEN e."tradeTypeId" = 2 THEN
                (
                    CASE
                    WHEN (
                        e."listingPrice" :: NUMERIC <= 1000
                    ) THEN
                        '< $1,000/mth'
                    WHEN (
                        e."listingPrice" :: NUMERIC > 1000
                        AND e."listingPrice" :: NUMERIC <= 2000
                    ) THEN
                        '$1,000 - $2,000/mth'
                    WHEN (
                        e."listingPrice" :: NUMERIC > 2000
                        AND e."listingPrice" :: NUMERIC <= 3000
                    ) THEN
                        '$2,000 - $3,000/mth'
                    WHEN (
                        e."listingPrice" :: NUMERIC > 3000
                        AND e."listingPrice" :: NUMERIC <= 4000
                    ) THEN
                        '$3,000 - $4,000/mth'
                    WHEN (
                        e."listingPrice" :: NUMERIC <= 5000
                    ) THEN
                        '$4,000 - $5,000/mth'
                    WHEN (
                        e."listingPrice" :: NUMERIC > 5000
                    ) THEN
                        '$5,000+/mth'
                    ELSE
                        ''
                    END
                )
            ELSE
                ''
            END
        ) AS "Renting Price",
        (
            CASE
            WHEN eit."approxSquareFootage" IS NOT NULL
            AND eit."approxSquareFootage" ~ '^[0-9]+$' THEN
                CASE
            WHEN (
                eit."approxSquareFootage" :: INT < 800
            ) THEN
                '< 800 sqft'
            WHEN (
                eit."approxSquareFootage" :: INT < 1200
            ) THEN
                '800 - 1,200 sqft'
            WHEN (
                eit."approxSquareFootage" :: INT < 2000
            ) THEN
                '1,200 - 2,000 sqft'
            WHEN (
                eit."approxSquareFootage" :: INT < 3000
            ) THEN
                '2,000 - 3,000 sqft'
            WHEN (
                eit."approxSquareFootage" :: INT < 4000
            ) THEN
                '3,000 - 4,000 sqft'
            ELSE
                '4,000+ sqft'
            END
            WHEN eit."approxSquareFootage" ~ '-' THEN
                (
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
                )
            ELSE
                'Data Not Available'
            END
        ) AS "livingArea",
        
        (
            CASE
            WHEN (
                e."projectClosingDate" > CURRENT_DATE
            ) THEN
                (
                    CASE
                    WHEN (
                        EXTRACT (
                            YEAR
                            FROM
                                age(
                                    e."projectClosingDate" :: TIMESTAMP,
                                    now() :: TIMESTAMP
                                )
                        ) * 12 + EXTRACT (
                            MONTH
                            FROM
                                age(
                                    e."projectClosingDate" :: TIMESTAMP,
                                    now() :: TIMESTAMP
                                )
                        ) < 1
                    ) THEN
                        '< 30 days'
                    WHEN (
                        EXTRACT (
                            YEAR
                            FROM
                                age(
                                    e."projectClosingDate" :: TIMESTAMP,
                                    now() :: TIMESTAMP
                                )
                        ) * 12 + EXTRACT (
                            MONTH
                            FROM
                                age(
                                    e."projectClosingDate" :: TIMESTAMP,
                                    now() :: TIMESTAMP
                                )
                        ) < 2
                    ) THEN
                        '< 60 days'
                    WHEN (
                        EXTRACT (
                            YEAR
                            FROM
                                age(
                                    e."projectClosingDate" :: TIMESTAMP,
                                    now() :: TIMESTAMP
                                )
                        ) * 12 + EXTRACT (
                            MONTH
                            FROM
                                age(
                                    e."projectClosingDate" :: TIMESTAMP,
                                    now() :: TIMESTAMP
                                )
                        ) < 3
                    ) THEN
                        '< 90 days'
                    WHEN (
                        EXTRACT (
                            YEAR
                            FROM
                                age(
                                    e."projectClosingDate" :: TIMESTAMP,
                                    now() :: TIMESTAMP
                                )
                        ) * 12 + EXTRACT (
                            MONTH
                            FROM
                                age(
                                    e."projectClosingDate" :: TIMESTAMP,
                                    now() :: TIMESTAMP
                                )
                        ) < 6
                    ) THEN
                        '< 180 days'
                    
                    
                    END
                )
            ELSE
                ''
            END
        ) AS "PreMover (Project Move Date)",

        (
            CASE
            WHEN (
                e."projectClosingDate" <= CURRENT_DATE
            ) THEN
                (
                    CASE
                    WHEN (
                        EXTRACT (
                            YEAR
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) * 12 + EXTRACT (
                            MONTH
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) < 1
                    ) THEN
                        '< 1 month'
                    WHEN (
                        EXTRACT (
                            YEAR
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) * 12 + EXTRACT (
                            MONTH
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) < 2
                    ) THEN
                        '< 2 months'
                    WHEN (
                        EXTRACT (
                            YEAR
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) * 12 + EXTRACT (
                            MONTH
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) < 3
                    ) THEN
                        '< 3 months'
                    WHEN (
                        EXTRACT (
                            YEAR
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) * 12 + EXTRACT (
                            MONTH
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) < 6
                    ) THEN
                        '< 6 months'
                    WHEN (
                        EXTRACT (
                            YEAR
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) * 12 + EXTRACT (
                            MONTH
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) < 9
                    ) THEN
                        '< 9 months'
                    WHEN (
                        EXTRACT (
                            YEAR
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) * 12 + EXTRACT (
                            MONTH
                            FROM
                                age(
                                    now() :: TIMESTAMP,
                                    e."projectClosingDate" :: TIMESTAMP
                                )
                        ) < 12
                    ) THEN
                        '< 1 yr'
                    
                    ELSE
                        ''
                    END
                )
            ELSE
                ''
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
            WHEN (
                eit."approxAge" = '0-5'
                OR eit."approxAge" = '6-10'
                OR eit."approxAge" = 'New'
            ) THEN
                'Post 2010'
            WHEN (
                COALESCE (eit."approxAge", '') != ''
            ) THEN
                'Pre 2010'
            END
        ) AS "Year Built",
        eit."cableTVIncluded" AS "Cable Available"
    FROM
        estate_master e,
        estate_master_item eit,
        building_type btype --realtor_history rh
    WHERE
        e."id" = eit."masterId" --AND e."pMlsNumber" = rh."pMlsNumber"
    AND e."buildingTypeId" = btype."id"
    AND e."activeFlag" = 'Y'
    AND e."recActiveFlag" = 'Y'
    AND (
        e."tradeTypeId" = 1
        OR e."tradeTypeId" = 2
    )
    AND COALESCE(e."projectClosingDate"::CHAR, '') != ''
    AND ( 
                (eit."approxSquareFootage" IS NOT NULL and eit."approxSquareFootage" ~ '^[0-9]+$') 
                OR
                eit."approxSquareFootage" ~ '-'
            )
    AND COALESCE (eit."cableTVIncluded", '') != ''
    and COALESCE (eit."approxAge", '') != ''
    and ( 
            date_part('day', e."projectClosingDate"::TIMESTAMP - now()::TIMESTAMP)  <= 180
            and
            date_part('day', now()::TIMESTAMP - e."projectClosingDate"::TIMESTAMP) <= 365
        )
    AND COALESCE (eit."garageSpaces", '') != ''
    AND COALESCE (eit."bathrooms", '') != ''
    AND COALESCE (eit."bedrooms", '') != ''
    AND COALESCE (e."latitude", '') != ''
    AND COALESCE (e."longitude", '') != ''
    AND e."latitude" != '0.0'
    AND e."longitude" != '0.0'
    ORDER BY
        e. ID
limit 1000;

-- select TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISS');