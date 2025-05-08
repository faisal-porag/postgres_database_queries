
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


-- ************************************************************





