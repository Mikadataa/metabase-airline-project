-- 00_create_raw_table.sql
-- Creates a generic TEXT table suitable for bulletproof CSV import.
DROP TABLE IF EXISTS airline_raw;

CREATE TABLE airline_raw (
  col1  TEXT, col2  TEXT, col3  TEXT, col4  TEXT, col5  TEXT, col6  TEXT,
  col7  TEXT, col8  TEXT, col9  TEXT, col10 TEXT, col11 TEXT, col12 TEXT,
  col13 TEXT, col14 TEXT, col15 TEXT, col16 TEXT, col17 TEXT, col18 TEXT,
  col19 TEXT, col20 TEXT, col21 TEXT, col22 TEXT, col23 TEXT, col24 TEXT
);

-- Run from psql (inside container) with a single backslash:
-- \copy airline_raw FROM '/csv/airline.csv' WITH (FORMAT csv, HEADER true);
