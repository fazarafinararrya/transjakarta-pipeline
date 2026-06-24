-- Staging layer: cleaning & type casting dari raw data
-- Semua kolom di raw masih STRING, di sini kita convert ke tipe yang benar

WITH source AS (
    SELECT * FROM `transjakarta-pipeline.transjakarta.staging_transjakarta_raw`
)

SELECT
    -- ID & info kartu
    transID,
    payCardID,
    payCardBank,
    payCardName,
    payCardSex,
    SAFE_CAST(payCardBirthDate AS INT64) AS birth_year,

    -- Corridor (rute)
    corridorID,
    corridorName,
    SAFE_CAST(direction AS INT64) AS direction,

    -- Tap In
    tapInStops,
    tapInStopsName,
    SAFE_CAST(tapInStopsLat AS FLOAT64) AS tapInStopsLat,
    SAFE_CAST(tapInStopsLon AS FLOAT64) AS tapInStopsLon,
    SAFE_CAST(stopStartSeq AS INT64) AS stopStartSeq,
    COALESCE(
        SAFE.PARSE_TIMESTAMP('%m/%d/%Y %H:%M', tapInTime),
        SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', tapInTime)
    ) AS tapInTime,

    -- Tap Out
    tapOutStops,
    tapOutStopsName,
    SAFE_CAST(tapOutStopsLat AS FLOAT64) AS tapOutStopsLat,
    SAFE_CAST(tapOutStopsLon AS FLOAT64) AS tapOutStopsLon,
    SAFE_CAST(stopEndSeq AS INT64) AS stopEndSeq,
    COALESCE(
        SAFE.PARSE_TIMESTAMP('%m/%d/%Y %H:%M', tapOutTime),
        SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', tapOutTime)
    ) AS tapOutTime,

    -- Pembayaran
    SAFE_CAST(payAmount AS FLOAT64) AS payAmount

FROM source