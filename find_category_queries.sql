-- ************************ Sample Category Table Schema ************************************

CREATE TABLE IF NOT EXISTS product."Category"
(
    "Id"                 BIGSERIAL NOT NULL PRIMARY KEY,
    "ParentId"           INTEGER,
    "Icon"               VARCHAR(255),
    "NameEn"             VARCHAR(255) NOT NULL,
    "StatusId"           INTEGER
);

-- ************************ Find Category Level (Last Child to Parent By Given Category Id) ************************************

WITH RECURSIVE category_hierarchy AS (
            SELECT "Id", "ParentId", 1 AS level, "NameEn"
            FROM product."Category"
            WHERE "Id" = 4698

            UNION ALL

            SELECT c."Id", c."ParentId", ch.level + 1, c."NameEn"
            FROM product."Category" c
            JOIN category_hierarchy ch ON c."Id" = ch."ParentId"
        )
SELECT * FROM category_hierarchy
		ORDER BY level DESC;



-- ************************ Find Category Level (Parent to Last Child By Given Category Id) ************************************

WITH RECURSIVE parent_chain AS (
			-- Find all ancestors up to the root
			SELECT "Id", "ParentId", "NameEn"
			FROM product."Category"
			WHERE "Id" = 4698

			UNION ALL

			SELECT p."Id", p."ParentId", p."NameEn"
			FROM product."Category" p
			JOIN parent_chain pc ON p."Id" = pc."ParentId"
		),
		root AS (
			-- Identify the root (top-most parent)
			SELECT "Id", "NameEn"
			FROM parent_chain
			WHERE "ParentId" IS NULL
		),
		full_hierarchy AS (
			-- Start from the root with level 1
			SELECT
				c."Id",
				c."ParentId",
				1 AS level,
				c."NameEn"
			FROM product."Category" c
			WHERE c."Id" = (SELECT "Id" FROM root)

			UNION ALL

			-- Recursively add children with incremented level
			SELECT
				c."Id",
				c."ParentId",
				fh.level + 1,
				c."NameEn"
			FROM product."Category" c
			JOIN full_hierarchy fh ON c."ParentId" = fh."Id"
			WHERE c."Id" IN (
				-- Only include categories in the path to our original category
				SELECT "Id" FROM parent_chain
			)
		)
		SELECT * FROM full_hierarchy
		ORDER BY level ASC;


-- ************************ Find Given Category Has Any Child or Not ************************************

SELECT EXISTS(
	SELECT 1 FROM product."Category"
	WHERE "ParentId" = 4697
);

-- ************************ Find all descendants By Given Category Id (children, grandchildren, etc.) ************************************

WITH RECURSIVE descendants AS (
	SELECT "Id", "NameEn", "ParentId" FROM product."Category" WHERE "ParentId" = 4697

	UNION ALL

	SELECT c."Id", c."NameEn", c."ParentId"
	FROM product."Category" c
	JOIN descendants d ON c."ParentId" = d."Id"
)
SELECT * FROM descendants;

-- ************************************************************
-- 🌳 PostgreSQL Category Tree Query
-- ✅ Full Category Tree (All Levels)

WITH RECURSIVE category_tree AS (

    -- Root Categories
    SELECT 
        c."Id",
        c."ParentId",
        c."NameEn",
        1 AS level,
        c."NameEn"::TEXT AS full_path
    FROM product."Category" c
    WHERE c."ParentId" IS NULL

    UNION ALL

    -- Child Categories
    SELECT 
        child."Id",
        child."ParentId",
        child."NameEn",
        parent.level + 1,
        parent.full_path || ' > ' || child."NameEn"
    FROM product."Category" child
    INNER JOIN category_tree parent 
        ON child."ParentId" = parent."Id"
)

SELECT *
FROM category_tree
ORDER BY full_path;

-- ************************************************************

-- ✅ Much Better Production Version (True Recursive Nested JSON)

-- This builds real deep nesting (multi-level) — not just one level.

WITH RECURSIVE tree AS (

    -- Root Categories
    SELECT
        c."Id",
        c."ParentId",
        c."NameEn",
        1 AS level
    FROM product."Category" c
    WHERE c."ParentId" IS NULL

    UNION ALL

    SELECT
        child."Id",
        child."ParentId",
        child."NameEn",
        parent.level + 1
    FROM product."Category" child
    JOIN tree parent
        ON child."ParentId" = parent."Id"
),

json_tree AS (

    SELECT
        t."Id",
        t."ParentId",
        jsonb_build_object(
            'id', t."Id",
            'name', t."NameEn"
        ) AS node
    FROM tree t
)

SELECT jsonb_pretty(
    jsonb_agg(
        build_tree.node
    )
)
FROM (

    SELECT
        jt."Id",
        jt."ParentId",
        jsonb_build_object(
            'id', jt."Id",
            'name', jt.node->>'name',
            'children',
            COALESCE(
                (
                    SELECT jsonb_agg(child_tree.node)
                    FROM json_tree child_tree
                    WHERE child_tree."ParentId" = jt."Id"
                ),
                '[]'::jsonb
            )
        ) AS node
    FROM json_tree jt
    WHERE jt."ParentId" IS NULL

) build_tree;


-- ************************************************************




