-- Dimension: master penumpang + kelompok umur

SELECT DISTINCT
    payCardID,
    payCardBank,
    payCardName,
    payCardSex AS gender,
    birth_year,
    -- Hitung umur (data dari 2023)
    2023 - birth_year AS umur,
    -- Kelompok umur
    CASE
        WHEN 2023 - birth_year < 18 THEN 'Anak/Remaja'
        WHEN 2023 - birth_year BETWEEN 18 AND 30 THEN 'Dewasa Muda'
        WHEN 2023 - birth_year BETWEEN 31 AND 50 THEN 'Dewasa'
        WHEN 2023 - birth_year > 50 THEN 'Lansia'
        ELSE 'Tidak Diketahui'
    END AS kelompok_umur
FROM {{ ref('fact_transactions') }}
WHERE payCardID IS NOT NULL