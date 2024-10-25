select count(1) from user_info where "C5" = '';


select count(1) from user_info where "C5" <> '';


-- Delete rows
delete from user_info where "C5" = '';


-- Step 1: Insert 11-digit rows
WITH numbers AS (
    SELECT generate_series(0, 9) AS last_digit
),
ten_digit_c5 AS (
    SELECT *
    FROM user_info
    WHERE length("C5") = 10
)
INSERT INTO user_info("C0", "C1", "C2", "C3", "C4", "C5", "C6", "C7")
SELECT
    "C0" || '-' || last_digit,  -- Append last_digit to C0
    "C1",
    "C2",
    "C3",
    "C4",
    "C5" || last_digit,         -- Append last_digit to C5
    "C6",
    "C7"
FROM ten_digit_c5, numbers;


-- Step 2: Delete the original 10-digit rows
DELETE FROM user_info
WHERE length("C5") = 10;

-- Query: Select rows by the patterns 
select count(1) from user_info where "C5" like '01_________';


-- Query: Delete the patterns 
DELETE FROM user_info
WHERE "C5" NOT LIKE '01_________';



