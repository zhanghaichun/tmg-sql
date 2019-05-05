CREATE OR REPLACE FUNCTION "public"."loading_411_ca_query_reference_info"()
  RETURNS "pg_catalog"."void" AS $BODY$

DECLARE
  
  /**
   * estate_master 表中的记录，其中包含的都是需要插入到
   * estate_master_411_ca_data 表中的关键字段。
   */
  V_QUERY_REFERENCE_RECORD RECORD;
  V_MASTER_ID INT;
  V_lISTING_DATE DATE;
  
  /**
   * estate_master 表中的 accuracyAddress 字段，这个字段中所存储的地址信息
   * 是经过标准化之后的 address 信息。
   */
  V_ACCURACY_ADDRESS VARCHAR(256);
  V_PROVINCE VARCHAR(12);

  V_WORKFLOW_COUNT INT;
  V_REPEAT_COUNT INT;

  /**
   * 从 estate_master 表中抓取的符合条件的记录的条数。
   */
  V_LIST_ITEM_COUNT INT;
  V_CURRENT_SERVICE_DATE VARCHAR(12);

BEGIN
  
  /**
   * @explain
   * 
   * 该函数用来向 estate_master_411_ca_data 表中导入 address 和 postal code 数据。
   * 同时要在服务器上写一个 shell 脚本， 每天定时从 estate_master 表中获取最新的
   * 任务列表信息。
   *
   * estate_master_411_ca_data 表是一个任务列表，用来抓取 411.ca 网站上的联系人数据。
   * 其中 address 和 postal code 两个字段当做输入，输出的即使联系人的信息。
   *
   * finishFlag: 表示当前记录是否已经获取完联系人信息
   * occFlag: 表示当前这条记录是否被抓取程序占用。
   */
  
  V_CURRENT_SERVICE_DATE := TO_CHAR(CURRENT_DATE - 3, 'YYYY-MM-DD');
  --V_CURRENT_SERVICE_DATE := '2019-01-26';

  /**
   *查询符合条件的记录数
   */
  SELECT COUNT(1) INTO V_LIST_ITEM_COUNT 
    FROM estate_master em 
    WHERE (em."listingDate" = TO_DATE(V_CURRENT_SERVICE_DATE, 'YYYY-MM-DD')) 
    AND (em."preMoverFirstName" IS NULL OR em."preMoverFirstName" = '') 
    AND  (em."preMoverLastName" IS NULL OR em."preMoverLastName" = '') 
    AND  (em."preMoverPhoneNumber" IS NULL OR em."preMoverPhoneNumber" = '')
    AND em."accuracyAddress" IS NOT NULL
    AND em."activeFlag" = 'Y';

  IF (V_LIST_ITEM_COUNT > 0) THEN
    /**
     * 当能够查询出符合条件的记录时，执行该语句块
     */

    /**
     * 删除 estate_master_411_ca_data 表中可能和当前 listing date
     * 重复的数据。
     */
    FOR V_QUERY_REFERENCE_RECORD IN 
      SELECT em.id AS "masterId", em."listingDate", em."streetNumber" || ' ' || em."streetName" as "accuracyAddress", p."code" 
      FROM estate_master em left join province p on em."provinceId"=p.id
      WHERE 
			(em."listingDate" = TO_DATE(V_CURRENT_SERVICE_DATE, 'YYYY-MM-DD'))
      AND em."streetNumber" IS NOT NULL
			AND em."streetName" IS NOT NULL
      AND em."activeFlag" = 'Y'
      ORDER BY em."listingDate"
    LOOP
      
      V_REPEAT_COUNT := 0;

      /**
       * 对四个关键字段进行赋值， 使用 :=
       */
      V_MASTER_ID := V_QUERY_REFERENCE_RECORD."masterId";
      V_lISTING_DATE := V_QUERY_REFERENCE_RECORD."listingDate";
      V_ACCURACY_ADDRESS := V_QUERY_REFERENCE_RECORD."accuracyAddress";
      V_PROVINCE := V_QUERY_REFERENCE_RECORD."code";
      
      /**
       * 确保不要插入重复的数据
       */
      SELECT COUNT(1) INTO V_REPEAT_COUNT 
      FROM estate_master_411_ca_data
      WHERE 1 = 1
        AND (
              (address = V_ACCURACY_ADDRESS AND "province" = V_PROVINCE)
              OR
              "masterId" = V_MASTER_ID
            );

      IF (V_REPEAT_COUNT = 0) THEN

        /**
         * 向 estate_master_411_ca_data 表中插入数据。
         */
        INSERT INTO estate_master_411_ca_data("masterId", "listingDate", address, "province")
        VALUES(V_MASTER_ID, V_lISTING_DATE, V_ACCURACY_ADDRESS, V_PROVINCE);
      END IF;
      
    END LOOP;

    /**
     * 查询在工作流程表中是否有当前 listingDate 的记录，
     * 如果有记录， 那么不再重新插入。
     */
    SELECT COUNT(1) INTO V_WORKFLOW_COUNT 
    FROM estate_411_contact_step_workflow
    WHERE "versionDate" = V_CURRENT_SERVICE_DATE;

    IF (V_WORKFLOW_COUNT = 0) THEN

      /**
       * 向工作流程表中插入记录
       */
      INSERT INTO estate_411_contact_step_workflow("stepId", "versionDate", "updateTime")
      VALUES(1, V_CURRENT_SERVICE_DATE, NOW());

    END IF;
  END IF;

END 
$BODY$
  LANGUAGE 'plpgsql' VOLATILE COST 100
;

ALTER FUNCTION "public"."loading_411_ca_query_reference_info"() OWNER TO "dealtap";