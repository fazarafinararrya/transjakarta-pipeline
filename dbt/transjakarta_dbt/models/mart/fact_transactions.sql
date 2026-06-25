-- Fact table: cleaning bertingkat
-- TAHAP 1: isi stops | TAHAP 2: enrich corridor | TAHAP 3: imputasi payAmount

WITH base AS (
    SELECT * FROM {{ ref('stg_transjakarta') }}
),

corridor_by_name AS (
    SELECT corridorName, MAX(corridorID) AS corridorID
    FROM {{ ref('lookup_corridor') }}
    GROUP BY corridorName
),

stops_by_name AS (
    SELECT stop_name, MAX(stop_id) AS stop_id
    FROM {{ ref('lookup_stops') }}
    GROUP BY stop_name
),

-- TAHAP 1: isi stops dulu
filled_stops AS (
    SELECT
        b.* EXCEPT(tapInStops, tapInStopsName, tapInStopsLat, tapInStopsLon,
                   tapOutStops, tapOutStopsName, tapOutStopsLat, tapOutStopsLon),
        COALESCE(b.tapInStops, sin_name.stop_id) AS tapInStops,
        COALESCE(b.tapInStopsName, sin_id.stop_name) AS tapInStopsName,
        COALESCE(b.tapInStopsLat, sin_id.lat) AS tapInStopsLat,
        COALESCE(b.tapInStopsLon, sin_id.lon) AS tapInStopsLon,
        COALESCE(b.tapOutStops, sout_name.stop_id) AS tapOutStops,
        COALESCE(b.tapOutStopsName, sout_id.stop_name) AS tapOutStopsName,
        COALESCE(b.tapOutStopsLat, sout_id.lat) AS tapOutStopsLat,
        COALESCE(b.tapOutStopsLon, sout_id.lon) AS tapOutStopsLon
    FROM base b
    LEFT JOIN {{ ref('lookup_stops') }} sin_id ON b.tapInStops = sin_id.stop_id
    LEFT JOIN stops_by_name sin_name ON b.tapInStopsName = sin_name.stop_name
    LEFT JOIN {{ ref('lookup_stops') }} sout_id ON b.tapOutStops = sout_id.stop_id
    LEFT JOIN stops_by_name sout_name ON b.tapOutStopsName = sout_name.stop_name
),

-- ENRICH corridor dari pasangan halte
corridor_by_pair AS (
    SELECT tapInStops, tapOutStops, guessed_id, guessed_name
    FROM (
        SELECT tapInStops, tapOutStops,
            corridorID AS guessed_id, corridorName AS guessed_name,
            ROW_NUMBER() OVER (PARTITION BY tapInStops, tapOutStops ORDER BY COUNT(*) DESC) AS rn
        FROM {{ ref('stg_transjakarta') }}
        WHERE corridorID IS NOT NULL AND corridorName IS NOT NULL
          AND tapInStops IS NOT NULL AND tapOutStops IS NOT NULL
        GROUP BY tapInStops, tapOutStops, corridorID, corridorName
    ) WHERE rn = 1
),

-- ENRICH corridor dari halte masuk aja
corridor_by_single AS (
    SELECT tapInStops, guessed_id, guessed_name
    FROM (
        SELECT tapInStops,
            corridorID AS guessed_id, corridorName AS guessed_name,
            ROW_NUMBER() OVER (PARTITION BY tapInStops ORDER BY COUNT(*) DESC) AS rn
        FROM {{ ref('stg_transjakarta') }}
        WHERE corridorID IS NOT NULL AND corridorName IS NOT NULL
          AND tapInStops IS NOT NULL
        GROUP BY tapInStops, corridorID, corridorName
    ) WHERE rn = 1
),

-- TARIF DOMINAN per corridor (buat imputasi payAmount)
tarif_dominan AS (
    SELECT corridorName, payAmount AS tarif
    FROM (
        SELECT corridorName, payAmount,
            ROW_NUMBER() OVER (PARTITION BY corridorName ORDER BY COUNT(*) DESC) AS rn
        FROM {{ ref('stg_transjakarta') }}
        WHERE payAmount IS NOT NULL AND corridorName IS NOT NULL
        GROUP BY corridorName, payAmount
    ) WHERE rn = 1
),

-- Tahap enrich corridor (buat dipakai imputasi tarif juga)
enriched AS (
    SELECT
        fs.*,
        COALESCE(fs.corridorID, cbn.corridorID, cbp.guessed_id, cbsingle.guessed_id, 'UNKNOWN') AS final_corridorID,
        COALESCE(fs.corridorName, lc.corridorName, cbp.guessed_name, cbsingle.guessed_name, 'Unknown Corridor') AS final_corridorName
    FROM filled_stops fs
    LEFT JOIN {{ ref('lookup_corridor') }} lc ON fs.corridorID = lc.corridorID
    LEFT JOIN corridor_by_name cbn ON fs.corridorName = cbn.corridorName
    LEFT JOIN corridor_by_pair cbp
        ON fs.tapInStops = cbp.tapInStops AND fs.tapOutStops = cbp.tapOutStops
    LEFT JOIN corridor_by_single cbsingle
        ON fs.tapInStops = cbsingle.tapInStops
)

SELECT
    e.transID,
    e.payCardID,
    e.payCardBank,
    e.payCardName,
    e.payCardSex,
    e.birth_year,

    e.final_corridorID AS corridorID,
    e.final_corridorName AS corridorName,
    e.direction,

    e.tapInStops,
    e.tapInStopsName,
    e.tapInStopsLat,
    e.tapInStopsLon,
    e.stopStartSeq,
    e.tapInTime,

    e.tapOutStops,
    e.tapOutStopsName,
    e.tapOutStopsLat,
    e.tapOutStopsLon,
    e.stopEndSeq,
    e.tapOutTime,

    CASE WHEN e.tapOutTime IS NOT NULL THEN TRUE ELSE FALSE END AS is_complete_trip,

    -- IMPUTASI payAmount bertingkat
    CASE
        WHEN e.payAmount IS NOT NULL THEN e.payAmount
        WHEN e.final_corridorID LIKE 'JAK%' THEN 0          -- Mikrotrans gratis
        WHEN e.final_corridorName LIKE '%Rusun%' THEN 0     -- Rute Rusun gratis
        ELSE COALESCE(td.tarif, 3500)                        -- tarif dominan, atau default 3500
    END AS payAmount

FROM enriched e
LEFT JOIN tarif_dominan td ON e.final_corridorName = td.corridorName