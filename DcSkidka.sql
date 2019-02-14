SELECT   DISTINCT(dim_DC.DC_CODE)
        , DC_skidka
        , dc_type_name
FROM dim_DC WITH(NOLOCK)
LEFT JOIN fact_Skidka_DC AS sks WITH(NOLOCK) ON sks.DC = dim_DC.DC_CODE
WHERE
[m]=201902
AND Deleted = 'Активен'
AND IsActive = 'Карта активирована'

Union all
SELECT   DISTINCT(dim_DC.DC_CODE)
        , '10' as DC_skidka
        , dc_type_name
FROM dim_DC WITH(NOLOCK)
LEFT JOIN fact_Skidka_DC AS sks WITH(NOLOCK) ON sks.DC = dim_DC.DC_CODE
WHERE
dc_type_name='Сотрудник'
AND Deleted = 'Активен'
AND IsActive = 'Карта активирована'
