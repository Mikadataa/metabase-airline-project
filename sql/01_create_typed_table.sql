-- 01_create_typed_table.sql
-- Final typed table with header skipped (ID is the CSV header).
DROP TABLE IF EXISTS airline_satisfaction;

CREATE TABLE airline_satisfaction AS
SELECT
  NULLIF(col1,'')::bigint AS "ID",
  col2                    AS "Gender",
  NULLIF(col3,'')::int    AS "Age",
  col4                    AS "Customer Type",
  col5                    AS "Type of Travel",
  col6                    AS "Class",
  NULLIF(col7,'')::int    AS "Flight Distance",
  NULLIF(col8,'')::int    AS "Departure Delay",
  NULLIF(col9,'')::int    AS "Arrival Delay",
  NULLIF(col10,'')::int   AS "Departure and Arrival Time Convenience",
  NULLIF(col11,'')::int   AS "Ease of Online Booking",
  NULLIF(col12,'')::int   AS "Check-in Service",
  NULLIF(col13,'')::int   AS "Online Boarding",
  NULLIF(col14,'')::int   AS "Gate Location",
  NULLIF(col15,'')::int   AS "On-board Service",
  NULLIF(col16,'')::int   AS "Seat Comfort",
  NULLIF(col17,'')::int   AS "Leg Room Service",
  NULLIF(col18,'')::int   AS "Cleanliness",
  NULLIF(col19,'')::int   AS "Food and Drink",
  NULLIF(col20,'')::int   AS "In-flight Service",
  NULLIF(col21,'')::int   AS "In-flight Wifi Service",
  NULLIF(col22,'')::int   AS "In-flight Entertainment",
  NULLIF(col23,'')::int   AS "Baggage Handling",
  col24                   AS "Satisfaction"
FROM airline_raw
WHERE col1 <> 'ID';

-- Quick checks
-- SELECT COUNT(*) FROM airline_satisfaction;
-- SELECT "Satisfaction", COUNT(*) FROM airline_satisfaction GROUP BY 1 ORDER BY 2 DESC;
-- SELECT * FROM airline_satisfaction LIMIT 5;

-- Primary key
-- ALTER TABLE airline_satisfaction ADD PRIMARY KEY ("ID");
