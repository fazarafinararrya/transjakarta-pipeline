-- Lookup table: mapping stops (ID <-> Name <-> Lat/Lon)
-- Gabungan dari tapIn dan tapOut karena halte yang sama bisa muncul di keduanya

WITH tap_in AS (
    SELECT tapInStops AS stop_id, tapInStopsName AS stop_name,
           tapInStopsLat AS lat, tapInStopsLon AS lon
    FROM {{ ref('stg_transjakarta') }}
    WHERE tapInStops IS NOT NULL AND tapInStopsName IS NOT NULL
),

tap_out AS (
    SELECT tapOutStops AS stop_id, tapOutStopsName AS stop_name,
           tapOutStopsLat AS lat, tapOutStopsLon AS lon
    FROM {{ ref('stg_transjakarta') }}
    WHERE tapOutStops IS NOT NULL AND tapOutStopsName IS NOT NULL
),

combined AS (
    SELECT * FROM tap_in
    UNION ALL
    SELECT * FROM tap_out
)

SELECT
    stop_id,
    MAX(stop_name) AS stop_name,
    MAX(lat) AS lat,
    MAX(lon) AS lon
FROM combined
WHERE stop_id IS NOT NULL
GROUP BY stop_id