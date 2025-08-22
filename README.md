# Metabase Mini Project — Airline Passenger Satisfaction (Stage 1)
---
[![Python](https://img.shields.io/badge/Python-3.9-blue.svg)]()
[![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-orange.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---
A Metabase dashboard starter using the **Airline Passenger Satisfaction** dataset.

This repo contains:
- `docker-compose.yml` — Metabase + Postgres + pgAdmin stack
- `sql/` — SQL scripts (raw import table and typed table)
- `data/` —  `airline.csv`
- `screens/` — screenshots (optional)

---

## 1) Prereqs
- Docker Desktop installed
- CSV at `./data/airline.csv` (24 columns; header begins with `ID,Gender,Age,...`).


---

## 2) Start the stack
```bash
docker compose up -d
```

Open:
- Metabase → <http://localhost:3000>
- pgAdmin → <http://localhost:5050> (login: `admin@example.com` / `admin`)
- Postgres is reachable as service `metadb` (user: `mbuser`, pass: `mbpass`).

If Metabase shows a connection error for its metadata DB, create it once:
```bash
docker exec -it metadb psql -U mbuser -d postgres -c "CREATE DATABASE metabase OWNER mbuser;"
docker restart metabase
```

---

## 3) Validate CSV inside the container
*(Run inside the Postgres container bash or via `docker exec` one-liners.)*

```bash
# Enter the container shell
docker exec -it metadb bash

# Show header row
head -n 1 /csv/airline.csv

# Show header with column numbers
head -n 1 /csv/airline.csv | tr ',' '\n' | nl

# Count how many columns
awk -F, '{print NF; exit}' /csv/airline.csv
```

You should see **24** columns in this exact order:

```
ID,Gender,Age,Customer Type,Type of Travel,Class,Flight Distance,
Departure Delay,Arrival Delay,Departure and Arrival Time Convenience,
Ease of Online Booking,Check-in Service,Online Boarding,Gate Location,
On-board Service,Seat Comfort,Leg Room Service,Cleanliness,
Food and Drink,In-flight Service,In-flight Wifi Service,In-flight Entertainment,
Baggage Handling,Satisfaction
```

Exit the container shell with `exit`.

---

## 4) Load CSV → raw table, then build typed table

> **Raw table (TEXT)**: we import first into a generic TEXT table for a bulletproof load.
> 
> **Typed table**: we convert to clean types and skip the header row.

Open a psql session:
```bash
docker exec -it metadb psql -U mbuser -d airlines
```

Create a raw table and import (header handled by `HEADER true`):
```sql
DROP TABLE IF EXISTS airline_raw;

CREATE TABLE airline_raw (
  col1  TEXT, col2  TEXT, col3  TEXT, col4  TEXT, col5  TEXT, col6  TEXT,
  col7  TEXT, col8  TEXT, col9  TEXT, col10 TEXT, col11 TEXT, col12 TEXT,
  col13 TEXT, col14 TEXT, col15 TEXT, col16 TEXT, col17 TEXT, col18 TEXT,
  col19 TEXT, col20 TEXT, col21 TEXT, col22 TEXT, col23 TEXT, col24 TEXT
);

\copy airline_raw FROM '/csv/airline.csv' WITH (FORMAT csv, HEADER true);

-- quick check
SELECT COUNT(*) FROM airline_raw;
```

> If you run `\copy` from `psql`, use **double backslash**.  
> If you want to import from the *container* shell, use a single backslash:  
> `\copy airline_raw FROM '/csv/airline.csv' WITH (FORMAT csv, HEADER true);`

---

## 5) Final typed table 

```sql
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
WHERE col1 <> 'ID';   -- << skip the header row (uppercase)
```

**Quick checks**
```sql
SELECT COUNT(*) FROM airline_satisfaction;

SELECT "Satisfaction", COUNT(*)
FROM airline_satisfaction
GROUP BY 1
ORDER BY 2 DESC;

SELECT * FROM airline_satisfaction LIMIT 5;
```

**Adding primary key**
```sql
ALTER TABLE airline_satisfaction ADD PRIMARY KEY ("ID");
```

Exit psql with `\q` (or `\q` if typed directly inside psql).

---

## 6) Connect in Metabase

1. Open <http://localhost:3000>, create the admin user.
2. Add database: **Admin → Databases → Add database**
   - Type: **PostgreSQL**
   - Name: `Airlines`
   - Host: `metadb`
   - Port: `5432`
   - Database name: `airlines`
   - User: `mbuser`
   - Password: `mbpass`
3. Click **Save**, then **Sync database schema now**.
4. **Browse data → airline_satisfaction**.

---

## 7) First questions 

**Overall Satisfaction %**
```sql
SELECT 100.0 * AVG(CASE WHEN "Satisfaction" = 'satisfied' THEN 1 ELSE 0 END) AS satisfaction_pct
FROM airline_satisfaction;
```

**Satisfaction by Travel Type × Class**
```sql
SELECT "Type of Travel" AS travel_type,
       "Class"          AS class,
       100.0 * AVG(CASE WHEN "Satisfaction"='satisfied' THEN 1 ELSE 0 END) AS sat_pct,
       COUNT(*) AS flights
FROM airline_satisfaction
GROUP BY 1,2
ORDER BY sat_pct DESC;
```

**Departure Delay Buckets vs Satisfaction**
```sql
WITH t AS (
  SELECT CASE
           WHEN COALESCE("Departure Delay",0) <= 15  THEN '0–15'
           WHEN "Departure Delay" <= 60              THEN '16–60'
           WHEN "Departure Delay" <= 180             THEN '61–180'
           ELSE '180+'
         END AS dep_bucket,
         CASE WHEN "Satisfaction"='satisfied' THEN 1 ELSE 0 END AS is_sat
  FROM airline_satisfaction
)
SELECT dep_bucket,
       100.0 * AVG(is_sat) AS sat_pct,
       COUNT(*) AS flights
FROM t
GROUP BY dep_bucket
ORDER BY CASE dep_bucket WHEN '0–15' THEN 1 WHEN '16–60' THEN 2 WHEN '61–180' THEN 3 ELSE 4 END;
```

**Service Drivers (compare satisfied vs not)**
```sql
SELECT
  'satisfied' AS group_name,
  AVG("Seat Comfort")              AS seat,
  AVG("In-flight Entertainment")   AS ife,
  AVG("Food and Drink")            AS food,
  AVG("Ease of Online Booking")    AS booking,
  AVG("In-flight Wifi Service")    AS wifi
FROM airline_satisfaction
WHERE "Satisfaction"='satisfied'
UNION ALL
SELECT
  'neutral/dissatisfied',
  AVG("Seat Comfort"),
  AVG("In-flight Entertainment"),
  AVG("Food and Drink"),
  AVG("Ease of Online Booking"),
  AVG("In-flight Wifi Service")
FROM airline_satisfaction
WHERE "Satisfaction"<>'satisfied';
```

**Distance Bands & Satisfaction**
```sql
SELECT CASE
         WHEN "Flight Distance" < 500   THEN '<500'
         WHEN "Flight Distance" < 1500  THEN '500–1499'
         WHEN "Flight Distance" < 3000  THEN '1500–2999'
         ELSE '3000+'
       END AS distance_band,
       COUNT(*) AS flights,
       100.0 * AVG(CASE WHEN "Satisfaction"='satisfied' THEN 1 ELSE 0 END) AS sat_pct
FROM airline_satisfaction
GROUP BY 1
ORDER BY flights DESC;
```

---

## 8) Dashboard 

---

## 9) Troubleshooting
- **Port in use**: change left side of port mapping in `docker-compose.yml`.
- **Metabase won’t start**: ensure `metabase` metadata DB exists (see step 2), then `docker restart metabase` and check `docker logs -f metabase`.
- **CSV import**: ensure the file is at `./data/airline.csv` on host → `/csv/airline.csv` in container.
- **Header row casting errors**: ensure the final typed table uses `WHERE col1 <> 'ID'`.

---

## Credits
- Dataset: Airline Passenger Satisfaction (Maven).
- Tools: Docker, Postgres, Metabase, pgAdmin.

## 👩‍💻 Author

**Mikadataa**  
🔗 [LinkedIn](https://www.linkedin.com/in/smagulova/) | 🐙 [GitHub](https://github.com/Mikadataa)

---

## 📄 License

This project is licensed under the MIT License.
