--¿Cómo cambian los valores (data_value) de cada indicator a lo largo de los años (year)?
SELECT 
year,
response,
ROUND(AVG(Data_Value)::NUMERIC,2) AS avg_Data_Value
FROM prevalence
GROUP BY year, response
ORDER BY year ASC;

--¿Qué locationdesc tienen los valores más altos y bajos para cada indicator?
WITH ranked_data AS (
    SELECT
        Year,
        Response,
        LocationDesc,
        Data_Value,
        ROW_NUMBER() OVER (PARTITION BY Year, Response ORDER BY Data_Value DESC) AS rn_max,
        ROW_NUMBER() OVER (PARTITION BY Year, Response ORDER BY Data_Value ASC) AS rn_min
    FROM prevalence
)
SELECT
    Year,
    Response,
    MAX(CASE WHEN rn_max = 1 THEN LocationDesc END) AS Location_Highest,
    MAX(CASE WHEN rn_max = 1 THEN Data_Value END) AS Value_Highest,
    MAX(CASE WHEN rn_min = 1 THEN LocationDesc END) AS Location_Lowest,
    MAX(CASE WHEN rn_min = 1 THEN Data_Value END) AS Value_Lowest
FROM ranked_data
GROUP BY Year, Response
ORDER BY Year, Response;


--¿Qué indicadores tienen los intervalos de confianza (high_confidence_limit - low_confidence_limit) más amplios, y en qué ubicaciones?

WITH s1 AS (SELECT 
LocationDesc,
response,
ROUND(AVG(High_Confidence_Limit)::NUMERIC,2) AS avg_High_Confidence_Limit,
ROUND(AVG(Low_Confidence_Limit)::NUMERIC,2) AS avg_Low_Confidence_Limit
FROM prevalence
GROUP BY LocationDesc, response
)
SELECT 
LocationDesc,
response,
avg_High_Confidence_Limit,
avg_Low_Confidence_Limit,
ROUND((avg_High_Confidence_Limit - avg_Low_Confidence_Limit),2) AS avg_confidence_interval
FROM s1
ORDER BY avg_confidence_interval DESC;

--¿Hay locationdesc con valores extremadamente altos o bajos de data_value comparados con la media nacional?

WITH global_stats AS(SELECT 
response,
AVG(Data_Value) AS avg_global,
STDDEV(Data_Value) AS std_global
FROM Prevalence
GROUP BY response
),

Local_stats AS (SELECT
LocationDesc,
response,
ROUND(AVG(Data_Value)::numeric,2) AS avg_local
FROM prevalence 
GROUP BY LocationDesc, response
)

SELECT 
ls.LocationDesc,
gs.response,
avg_local,
ROUND(((avg_local - avg_global) / std_global)::numeric,2) AS z_score,
CASE
	WHEN (avg_local - avg_global) / std_global > 2 THEN 'Alto Extremo'
    WHEN (avg_local - avg_global) / std_global < -2 THEN 'Bajo Extremo'
    ELSE 'Normal' END AS clasification 
FROM global_stats gs 
INNER JOIN Local_stats ls 
	ON gs.response = ls.response
ORDER BY ABS((avg_local - avg_global) / std_global ) DESC;

-- ¿Qué estados han tenido el mayor aumento o disminución de data_value en los últimos 5 años para cada indicador?

SELECT 
year,
LocationDesc,
response,
ROUND(AVG(Data_Value)::NUMERIC,2) AS avg_value
FROM prevalence
GROUP BY year, LocationDesc, response
ORDER BY year ASC, LocationDesc DESC;
-- ¿Existe correlación entre los valores de diferentes indicator en las mismas ubicaciones y años?
-- Para responder esta pregunta se realizo la tabla de correlación en python (Ver notebook)
SELECT
    LocationDesc,
    Year,
    MAX(CASE WHEN response = 'Self-care Disability' THEN Data_Value END) AS self_care,
    MAX(CASE WHEN response = 'Any Disability' THEN Data_Value END) AS any_disability,
    MAX(CASE WHEN response = 'Hearing Disability' THEN Data_Value END) AS hearing,
    MAX(CASE WHEN response = 'Vision Disability' THEN Data_Value END) AS vision,
    MAX(CASE WHEN response = 'Cognitive Disability' THEN Data_Value END) AS cognitive,
    MAX(CASE WHEN response = 'No Disability' THEN Data_Value END) AS no_disability,
    MAX(CASE WHEN response = 'Mobility Disability' THEN Data_Value END) AS mobility,
    MAX(CASE WHEN response = 'Independent Living Disability' THEN Data_Value END) AS independent_living
FROM prevalence
GROUP BY LocationDesc, Year
ORDER BY LocationDesc, Year;



