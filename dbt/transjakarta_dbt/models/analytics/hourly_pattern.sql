-- Pola per jam: cari jam sibuk (peak hours)

SELECT
    EXTRACT(HOUR FROM tapInTime) AS jam,
    COUNT(*) AS total_transaksi,
    COUNT(DISTINCT payCardID) AS unique_penumpang
FROM {{ ref('fact_transactions') }}
GROUP BY jam
ORDER BY jam