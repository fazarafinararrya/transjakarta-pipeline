-- Rute tersibuk berdasarkan jumlah transaksi

SELECT
    corridorID,
    corridorName,
    COUNT(*) AS total_transaksi,
    COUNT(DISTINCT payCardID) AS unique_penumpang,
    SUM(payAmount) AS total_revenue,
    ROUND(AVG(
        TIMESTAMP_DIFF(tapOutTime, tapInTime, MINUTE)
    ), 1) AS rata_durasi_menit
FROM {{ ref('fact_transactions') }}
WHERE corridorID != 'UNKNOWN'
GROUP BY corridorID, corridorName
ORDER BY total_transaksi DESC