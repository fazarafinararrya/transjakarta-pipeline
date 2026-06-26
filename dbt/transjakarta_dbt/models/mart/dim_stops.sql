-- Dimension: master halte + koordinat

WITH all_stops AS (
    SELECT tapInStops AS stop_id, tapInStopsName AS stop_name,
           tapInStopsLat AS lat, tapInStopsLon AS lon
    FROM {{ ref('fact_transactions') }}
    WHERE tapInStops IS NOT NULL
    UNION ALL
    SELECT tapOutStops AS stop_id, tapOutStopsName AS stop_name,
           tapOutStopsLat AS lat, tapOutStopsLon AS lon
    FROM {{ ref('fact_transactions') }}
    WHERE tapOutStops IS NOT NULL
)

SELECT
    stop_id,
    MAX(stop_name) AS stop_name,
    ROUND(AVG(lat), 6) AS lat,
    ROUND(AVG(lon), 6) AS lon
FROM all_stops
WHERE stop_id IS NOT NULL
GROUP BY stop_id