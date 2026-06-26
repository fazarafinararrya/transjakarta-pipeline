-- Dimension: master corridor/rute + klasifikasi jenis layanan

SELECT DISTINCT
    corridorID,
    corridorName,
    -- Klasifikasi jenis layanan berdasarkan kode/nama
    CASE
        WHEN corridorID LIKE 'JAK%' THEN 'Mikrotrans'
        WHEN corridorID LIKE 'BW%' THEN 'Bus Wisata'
        WHEN corridorName LIKE '%Rusun%' THEN 'Rute Rusun'
        WHEN corridorID = 'UNKNOWN' THEN 'Unknown'
        ELSE 'BRT Reguler'
    END AS jenis_layanan,
    -- Tarif tipikal
    CASE
        WHEN corridorID LIKE 'JAK%' THEN 0
        WHEN corridorID LIKE 'BW%' THEN 0
        WHEN corridorName LIKE '%Rusun%' THEN 0
        ELSE 3500
    END AS tarif_tipikal
FROM {{ ref('fact_transactions') }}
WHERE corridorID IS NOT NULL