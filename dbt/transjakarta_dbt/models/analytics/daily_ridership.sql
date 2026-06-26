-- Ridership harian: jumlah transaksi & revenue per hari
-- Buat lihat tren penumpang weekday vs weekend

SELECT
    DATE(tapInTime) AS tanggal,
    FORMAT_DATE('%A', DATE(tapInTime)) AS hari,
    CASE
        WHEN FORMAT_DATE('%A', DATE(tapInTime)) IN ('Saturday', 'Sunday')
        THEN 'Weekend' ELSE 'Weekday'
    END AS tipe_hari,
    COUNT(*) AS total_transaksi,
    COUNT(DISTINCT payCardID) AS unique_penumpang,
    SUM(payAmount) AS total_revenue,
    COUNTIF(is_complete_trip = FALSE) AS trip_tidak_tap_out
FROM {{ ref('fact_transactions') }}
GROUP BY tanggal, hari, tipe_hari
ORDER BY tanggal