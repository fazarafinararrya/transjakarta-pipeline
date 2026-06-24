-- Lookup table: mapping corridorID <-> corridorName
-- Dibuat dari baris yang KEDUANYA terisi (referensi terpercaya)

WITH complete_pairs AS (
    SELECT DISTINCT
        corridorID,
        corridorName
    FROM {{ ref('stg_transjakarta') }}
    WHERE corridorID IS NOT NULL
      AND corridorName IS NOT NULL
)

-- Ambil 1 nama per ID (kalau ada duplikat, pilih yang pertama)
SELECT
    corridorID,
    MAX(corridorName) AS corridorName
FROM complete_pairs
GROUP BY corridorID