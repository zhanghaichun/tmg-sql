DROP FUNCTION IF EXISTS fn_import_direct_mail_segment_data();
CREATE OR REPLACE FUNCTION "fn_import_direct_mail_segment_data"()
  RETURNS "pg_catalog"."void" AS $BODY$

DECLARE


BEGIN 


	INSERT INTO "public"."master_search" (
		"masterId",
		"address",
		"unit",
		"streetNumber",
		"streetName",
		"city",
		"province",
		"provinceId",
		"postalCode",
		"projectClosingDate",
		"latitude",
		"longitude",
		"contactName",
		"contactPhone",
		"occupancyType",
		"propertyType",
		"sellingPrice",
		"rentAmount",
		"postMover",
		"livingArea",
		"bedrooms",
		"bathrooms",
		"yearBuilt",
		"garage",
		"cableAvailable"
	)
	SELECT
		e."id",
		UPPER(e.address),
		e.unit,
		UPPER(e."streetNumber"),
		UPPER(e."streetName"),
		UPPER(e.city),
		UPPER(e.province),
		e."provinceId",
		e."postalCode",
		e."projectClosingDate"::Date,
		SUBSTRING(e.latitude from '[-0-9]+\.\d{1,6}') AS latitude,
		SUBSTRING(e.longitude from '[-0-9]+\.\d{1,6}') AS longitude,
		(
			CASE
			WHEN e."projectClosingDate" > CURRENT_DATE THEN
				(
					e."preMoverFirstName" || ' ' || e."preMoverLastName"
				)
			ELSE
				(
					e."postMoverFirstName" || ' ' || e."postMoverLastName"
				)
			END
		) AS "contactName",
		(
			CASE
			WHEN e."projectClosingDate" > CURRENT_DATE THEN
				e."preMoverPhoneNumber"
			ELSE
				e."postMoverPhoneNumber"
			END
		) AS "contactPhone",
		(
			CASE
			WHEN (e."tradeTypeId" = 1) THEN
				'Homeowner'
			WHEN (e."tradeTypeId" = 2) THEN
				'Renter'
			ELSE
				''
			END
		) AS "occupancyType",
		(
			CASE
			WHEN btype.genera = 'Apartment' THEN
				'Multi-dwelling'
			WHEN btype.genera = 'House' THEN
				'House'
			WHEN btype.genera = 'Commercial' THEN
				'Farm/Commercial'
			ELSE
				''
			END
		) AS "propertyType",
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
		) AS "sellingPrice",
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
		) AS "rentAmount",
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
				) > 0
				AND now() :: TIMESTAMP > e."projectClosingDate" :: TIMESTAMP
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
						'1 - 2 months'
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
						'2 - 3 months'
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
						'3 - 6 months'
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
						'6 - 9 months'
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
						'9 - 12 months'
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
						) >= 12
					) THEN
						'1+ year'
					ELSE
						''
					END
				)
			ELSE
				''
			END
		) AS "timeInNewResidence",
		(
			CASE
			WHEN (
				eit."approxSquareFootage" ~ '-'
			) THEN
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
				''
			END
		) AS "livingArea",
		(
			CASE
			WHEN (
				COALESCE (eit."bedrooms", '') = ''
			) THEN
				''
			WHEN (eit.bedrooms :: NUMERIC >= 4) THEN
				'4+'
			ELSE
				COALESCE (eit.bedrooms, '')
			END
		) AS "Bedrooms",
		(
			CASE
			WHEN (
				COALESCE (eit."bathrooms", '') = ''
			) THEN
				''
			WHEN (eit.bathrooms :: NUMERIC >= 4) THEN
				'4+'
			ELSE
				COALESCE (eit.bathrooms, '')
			END
		) AS "Bathrooms",
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
			ELSE
				''
			END
		) AS "yearBuilt",
		(
			CASE
			WHEN (
				COALESCE (eit."garageSpaces", '') = ''
			) THEN
				'N'
			ELSE
				'Y'
			END
		) AS "Garage",
		(
			CASE
			WHEN (
				COALESCE (eit."cableTVIncluded", '') = ''
			) THEN
				'N'
			ELSE
				'Y'
			END
		) AS "cableAvailable"
	FROM
		estate_master e,
		estate_master_item eit,
		building_type btype
	WHERE
		e."id" = eit."masterId"
		AND e."buildingTypeId" = btype."id"
		AND e."activeFlag" = 'Y'
		AND e."recActiveFlag" = 'Y'
		AND COALESCE(e."latitude", '') != ''
		AND COALESCE(e."longitude", '') != ''
		AND e."latitude" != '0.0'
		AND e."longitude" != '0.0'
	ORDER BY e.id
	LIMIT 10000;

	AND ( COALESCE(e."latitude", '') != '' OR COALESCE(e."longitude", '') != ''
		OR e."latitude" != '0.0' OR e."longitude" != '0.0')

END; 
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
;