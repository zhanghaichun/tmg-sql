DROP FUNCTION IF EXISTS fn_import_direct_mail_segment_data();
CREATE OR REPLACE FUNCTION "fn_import_direct_mail_segment_data"()
  RETURNS "pg_catalog"."void" AS $BODY$

DECLARE


BEGIN 


	TRUNCATE TABLE master_search RESTART IDENTITY;

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
		"preMover",
		"moverType",
		"livingArea",
		"bedrooms",
		"bathrooms",
		"yearBuilt",
		"garage",
		"cableAvailable"
	) 

	SELECT
		e."id",
		UPPER (e.address),
		e.unit,
		UPPER (e."streetNumber"),
		UPPER (e."streetName"),
		UPPER (e.city),
		UPPER (e.province),
		e."provinceId",
		e."postalCode",
		e."projectClosingDate" :: DATE,
		SUBSTRING (
			e.latitude
			FROM
				'[-0-9]+\.\d{1,6}'
		) AS latitude,
		SUBSTRING (
			e.longitude
			FROM
				'[-0-9]+\.\d{1,6}'
		) AS longitude,
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
				'Other'
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
		) AS "postMover",
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
						'< 1 month'
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
						'1 - 2 months'
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
						'2 - 3 months'
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
						'3 - 6 months'
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
						) < 9
					) THEN
						'6 - 9 months'
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
						) < 12
					) THEN
						'9 - 12 months'
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
						) >= 12
					) THEN
						'1+ year'
					END
				)
			ELSE
				''
			END
		) AS "preMover",
		(
			CASE
			WHEN e."projectClosingDate" <= CURRENT_DATE THEN
				'PostMover'
			WHEN e."projectClosingDate" > CURRENT_DATE THEN
				'PreMover'
			END
		) AS "MoverType",
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
				COALESCE (eit."bedrooms", '') = ''
			) THEN
				'Data Not Available'
			WHEN (eit.bedrooms :: NUMERIC > 4) THEN
				'4+'
			ELSE
				CAST( CAST(eit.bedrooms :: NUMERIC AS INT) AS CHAR )
			END
		) AS "Bedrooms",
		(
			CASE
			WHEN (
				COALESCE (eit."bathrooms", '') = ''
			) THEN
				'Data Not Available'
			WHEN (eit.bathrooms :: NUMERIC > 4) THEN
				'4+'
			ELSE
				CAST( CAST(eit.bathrooms :: NUMERIC AS INT) AS CHAR ) 
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
				'Data Not Available'
			END
		) AS "yearBuilt",
		(
			CASE
			WHEN (
				COALESCE (eit."garageSpaces", '') = ''
			) THEN
				'Data Not Available'
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
				WHEN ( COALESCE (eit."cableTVIncluded", '') = '' ) THEN
					'Data Not Available'
				ELSE
					eit."cableTVIncluded"
			END
		) AS "cableAvailable"
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
	AND e."projectClosingDate" IS NOT NULL
	AND COALESCE (e."latitude", '') != ''
	AND COALESCE (e."longitude", '') != ''
	AND e."latitude" != '0.0'
	AND e."longitude" != '0.0'
	ORDER BY
		e. ID

END; 
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
;