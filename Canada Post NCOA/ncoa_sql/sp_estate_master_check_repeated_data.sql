CREATE OR REPLACE FUNCTION "public"."sp_estate_master_check_repeated_data"()
  RETURNS "pg_catalog"."void" AS $BODY$
declare
	v_address_data RECORD;
	v_address_data2 RECORD;
	v_address VARCHAR;
	v_index int = 0;
begin
	-- 测试时如需往临时表插入数据 可执行以下语句，来添加测试数据
			/*INSERT INTO tmp_duplicate_tb(
						"masterId",
						"activeFlag"
				)SELECT
						id,
						'Y'
				FROM
						estate_master
				WHERE
					 "activeFlag" = 'Y' LIMIT 100000;*/
		-- 执行完存储过程后可以用以下语句做查询测试
		/*SELECT
				"activeFlag",
				COUNT (1)
			FROM
				tmp_duplicate_tb
			GROUP BY
				"activeFlag"*/
	FOR v_address_data IN SELECT
													COUNT (1),
													LOWER (em."streetName") AS "streetName",
													em."streetNumber",
													em.unit,
													SUBSTRING (em."postalCode", 1, 3) AS "postalCode"
												FROM
													estate_master em,
													tmp_duplicate_tb td
												WHERE
													em."id" = td."masterId"
												AND COALESCE (em.address, '') != ''
												AND em."activeFlag" = 'Y'
												GROUP BY
													LOWER (em."streetName"),
													em."streetNumber",
													em.unit,
													SUBSTRING (em."postalCode", 1, 3)
												HAVING
													COUNT (1) = 2
												ORDER BY
													COUNT (1) DESC


		loop
			

			UPDATE tmp_duplicate_tb
				SET "activeFlag" = 'N'
				FROM
					(SELECT ID,
									"streetName",
									"streetNumber",
									"tradeTypeId",
									"province",
									"city",
									"unit"
									FROM estate_master
					WHERE LOWER("streetName") = v_address_data."streetName"
									and "streetNumber" = v_address_data."streetNumber"
									and "tradeTypeId" = 2
									and "postalCode" LIKE v_address_data."postalCode" || '%'
									and COALESCE("unit",'') = COALESCE(v_address_data."unit",'')) em
				WHERE
					em. ID = tmp_duplicate_tb."masterId";


			/*v_index = v_index + 1;
			IF v_index % 100 = 0 THEN
					raise notice '%', v_index;
			END IF;*/
			
		end loop;

		v_index = 1;

		<<label1>> 
			FOR v_address_data2 IN SELECT
															COUNT (1),
															LOWER (em."streetName") AS "streetName",
															em."streetNumber",
															em.unit,
															em.province,
															em.city,
															MAX (ID) AS "dataID"
														FROM
															estate_master em,
															tmp_duplicate_tb td
														WHERE
															em. ID = td."masterId" 
														AND COALESCE (em.address, '') != ''
														AND em."activeFlag" = 'Y'
														GROUP BY
															LOWER (em."streetName"),
															em."streetNumber",
															em.unit,
															em.province,
															em.city
														HAVING
															COUNT (1) = 2
														ORDER BY
															COUNT (1) DESC
			loop


				UPDATE tmp_duplicate_tb
				SET "activeFlag" = 'N'
				FROM
					(SELECT ID,
									"streetName",
									"streetNumber",
									"tradeTypeId",
									"province",
									"city",
									"unit"
									FROM estate_master
					WHERE LOWER("streetName") = v_address_data2."streetName"
									and "streetNumber" = v_address_data2."streetNumber"
									and "tradeTypeId" = 2
									and "province" = v_address_data2."province"
									and "city" = v_address_data2."city"
									and COALESCE("unit",'') = COALESCE(v_address_data2."unit",'')) em
				WHERE
					em. ID = tmp_duplicate_tb."masterId";

				/*v_index = v_index + 1;
				IF v_index % 100 = 0 THEN
						raise notice '%', v_index;
				END IF;*/
			end loop label1; 
			
end;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE COST 100
;

ALTER FUNCTION "public"."sp_estate_master_check_repeated_data"() OWNER TO "dealtap";