-- Sample JSON column data 
{
   "customerId":1215476,
   "firstName":"Rezwan Ahmed",
   "lastName":"",
   "email":"rez1bd9@gmail.com",
   "phone":"+8801681024534",
   "analytics":{
      "ip":"172.31.23.122",
      "userAgent":"Dart/3.9 (dart:io)",
      "referrer":null,
      "acceptLanguage":null,
      "timestamp":"2026-03-17T17:15:13.042Z"
   },
   "emiData":{
      "isEmi":true,
      "emiTenure":6
   }
}


CREATE TABLE "Transactions" (
  id BIGSERIAL PRIMARY KEY,
  source VARCHAR(50),

  -- Raw request stored as JSON (kept as original)
  "Customer" JSON,

  -- Optimized searchable column
  "Customer_jsonb" JSONB,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO "Transactions" (source, "Customer", "Customer_jsonb")
VALUES (
    'mobile_app',

    '{
        "customerId":1215476,
        "firstName":"Rezwan Ahmed",
        "email":"rez1bd9@gmail.com",
        "emiData":{"isEmi":true,"emiTenure":6}
     }',

    '{
        "customerId":1215476,
        "firstName":"Rezwan Ahmed",
        "email":"rez1bd9@gmail.com",
        "emiData":{"isEmi":true,"emiTenure":6}
     }'
);

INSERT INTO "Transactions" (source, "Customer", "Customer_jsonb")
VALUES (
    'ios_app',

    '[
        {
            "customerId":1215476,
            "firstName":"Rezwan",
            "emiData":{"isEmi":true}
        },
        {
            "customerId":888,
            "firstName":"Karim",
            "emiData":{"isEmi":false}
        }
     ]',

    '[
        {
            "customerId":1215476,
            "firstName":"Rezwan",
            "emiData":{"isEmi":true}
        },
        {
            "customerId":888,
            "firstName":"Karim",
            "emiData":{"isEmi":false}
        }
     ]'
);



-- If your column type is JSON / JSONB, you can filter using PostgreSQL JSON operators.
--
-- Let’s assume:
--
-- Table name → Transactions
-- JSON column → Customer


SELECT * FROM public."Transactions"
where "Customer" -> 'emiData' is not null and "IsPaid" = true
ORDER BY "Id" DESC LIMIT 100;


-- Filter by simple field (customerId)
SELECT *
FROM "Transactions"
WHERE ("Customer" ->> 'customerId')::int = 1215476;


-- Filter by nested field (analytics.ip)
SELECT *
FROM "Transactions"
WHERE "Customer" -> 'analytics' ->> 'ip' = '172.31.23.122';


-- Filter by nested boolean (emiData.isEmi)
SELECT *
FROM "Transactions"
WHERE ("Customer" -> 'emiData' ->> 'isEmi')::boolean = true;


-- Filter by multiple conditions (example)
SELECT *
FROM "Transactions"
WHERE ("Customer" ->> 'customerId')::int = 1215476
AND "Customer" -> 'emiData' ->> 'isEmi' = 'true'
AND "Customer" -> 'analytics' ->> 'ip' = '172.31.23.122';

-- **********************************************************************
-- Best & Fast Way (Using JSONB Containment 🔥)
-- If your column is jsonb, this is very powerful and clean:
SELECT *
FROM "Transactions"
WHERE "Customer" @> '{"emiData":{"isEmi":true}}';

SELECT *
FROM "Transactions"
WHERE "Customer" @> '{"customerId":1215476}';

-- **********************************************************************

-- Pro Level Query (Handle BOTH Object + Array in One Query)
SELECT *
FROM "Transactions" t
WHERE
(
    jsonb_typeof("Customer_jsonb") = 'object'
    AND "Customer_jsonb" -> 'emiData' ->> 'isEmi' = 'true'
)
OR
(
    jsonb_typeof("Customer_jsonb") = 'array'
    AND EXISTS (
        SELECT 1
        FROM jsonb_array_elements("Customer_jsonb") elem
        WHERE elem -> 'emiData' ->> 'isEmi' = 'true'
    )
);


-- Using JSONB containment @>
-- ********** If JSON is an object: **********
SELECT *
FROM "Transactions"
WHERE "Customer_jsonb" @> '{"customerId":1215476}';


-- EVEN SMARTER Query (Senior Backend Trick 😄)
SELECT t.*
FROM "Transactions" t
WHERE EXISTS (
    SELECT 1
    FROM jsonb_array_elements(
        CASE
            WHEN jsonb_typeof(t."Customer_jsonb") = 'array'
                THEN t."Customer_jsonb"
            ELSE jsonb_build_array(t."Customer_jsonb")
        END
    ) elem
    WHERE (elem ->> 'customerId')::bigint = 1215476
);






-- ************************************************************************
-- Create Index for Performance (Production Must)
CREATE INDEX idx_transactions_customer_jsonb
ON "Transactions"
USING GIN ("Customer_jsonb");

