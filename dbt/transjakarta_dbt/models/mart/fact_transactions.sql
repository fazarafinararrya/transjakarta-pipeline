-- Fact table: cleaning bertingkat
-- TAHAP 1: isi stops dulu | TAHAP 2: baru enrich corridor pakai stops yang udah keisi

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

-- TAHAP 1: isi stops dulu (ID dari name, name dari ID)
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

-- ENRICH LV1: corridor dari pasangan halte
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

-- ENRICH LV2: corridor dari halte masuk aja
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
)

-- TAHAP 2: enrich corridor pakai stops yang UDAH keisi (dari filled_stops)
SELECT
    fs.transID,
    fs.payCardID,
    fs.payCardBank,
    fs.payCardName,
    fs.payCardSex,
    fs.birth_year,

    COALESCE(fs.corridorID, cbn.corridorID, cbp.guessed_id, cbsingle.guessed_id, 'UNKNOWN') AS corridorID,
    COALESCE(fs.corridorName, lc.corridorName, cbp.guessed_name, cbsingle.guessed_name, 'Unknown Corridor') AS corridorName,
    fs.direction,

    fs.tapInStops,
    fs.tapInStopsName,
    fs.tapInStopsLat,
    fs.tapInStopsLon,
    fs.stopStartSeq,
    fs.tapInTime,

    fs.tapOutStops,
    fs.tapOutStopsName,
    fs.tapOutStopsLat,
    fs.tapOutStopsLon,
    fs.stopEndSeq,
    fs.tapOutTime,

    CASE WHEN fs.tapOutTime IS NOT NULL THEN TRUE ELSE FALSE END AS is_complete_trip,

    fs.payAmount

FROM filled_stops fs

LEFT JOIN {{ ref('lookup_corridor') }} lc ON fs.corridorID = lc.corridorID
LEFT JOIN corridor_by_name cbn ON fs.corridorName = cbn.corridorName
LEFT JOIN corridor_by_pair cbp
    ON fs.tapInStops = cbp.tapInStops AND fs.tapOutStops = cbp.tapOutStops
LEFT JOIN corridor_by_single cbsingle
    ON fs.tapInStops = cbsingle.tapInStops