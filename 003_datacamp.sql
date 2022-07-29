
-- SELF-JOIN, CONDITION AND ----------------------------------------------------------------------------------------------------------------------------------

SELECT p1.country_code, p1.size AS size2010, p2.size AS size2015, ((p2.size - p1.size) / p1.size * 100.0) AS growth_perc

FROM populations AS p1
INNER JOIN populations AS p2
ON p1.country_code = p2.country_code AND p1.year = p2.year - 5;





-- SUBQUERY INSIDE WHERE -------------------------------------------------------------------------------------------------------------------------------------

SELECT name FROM cities AS c1

WHERE country_code IN (
    SELECT e.code FROM economies AS e
    UNION
    SELECT c2.code FROM currencies AS c2
    EXCEPT
    SELECT p.country_code FROM populations AS p
);





-- SUBQUERY INSIDE SELECT -----------------------------------------------------------------------------------------------------------------------------------

SELECT 
    countries.name AS country,
    (SELECT COUNT(*) FROM cities WHERE countries.code = cities.country_code) AS cities_num

FROM countries
ORDER BY cities_num DESC, country
LIMIT 9;





-- SUBQUERY INSIDE FROM ------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT monarchs.continent, subquery.max_perc

FROM 
    monarchs, 
    (
        SELECT continent, MAX(women_parli_perc) AS max_perc
        FROM states
        GROUP BY continent
    ) AS subquery

WHERE monarchs.continent = subquery.continent
ORDER BY continent;





-- SUBQUERY INSIDE ALL -------NEED WHERE FILTER IN ALL QUERIES---------------------------------------------------------------------------------------------

SELECT 
	s.stage,
	ROUND(s.avg_goals,2) AS avg_goal,
	(SELECT AVG(home_goal + away_goal) FROM match WHERE season = '2012/2013') AS overall_avg

FROM (
        SELECT stage, AVG(home_goal + away_goal) AS avg_goals
        FROM match
        WHERE season = '2012/2013'
        GROUP BY stage
) AS s

WHERE s.avg_goals > (SELECT AVG(home_goal + away_goal) FROM match WHERE season = '2012/2013');





-- CASE WHEN WITH AGGREGATE FUNCTION / COUNT TOTAL --------------------------------------------------------------------------------------------------------

SELECT 
	c.name AS country,
	COUNT(CASE WHEN m.season = '2012/2013' THEN m.id END) AS matches_2012_2013,
	COUNT(CASE WHEN m.season = '2013/2014' THEN m.id END) AS matches_2013_2014,
	COUNT(CASE WHEN m.season = '2014/2015' THEN m.id END) AS matches_2014_2015

FROM country AS c
LEFT JOIN match AS m
ON c.id = m.country_id
GROUP BY country;





-- CASE WHEN WITH AGGREGATE FUNCTION / PERCENTAGE --------------------------------------------------------------------------------------------------------

SELECT 
	c.name AS country,
    AVG(
        CASE 
            WHEN m.season= '2013/2014' AND m.home_goal = m.away_goal THEN 1
			WHEN m.season= '2013/2014' AND m.home_goal != m.away_goal THEN 0
		END
    ) AS ties_2013_2014,
FROM country AS c
LEFT JOIN matches AS m
ON c.id = m.country_id
GROUP BY country;










-- PARTITION BY MULTIPLE COLUMNS ------------------------------------------------------------------------------------------------------------------------

SELECT 
	date, hometeam_id, season, EXTRACT(MONTH FROM date) as month, home_goal, away_goal,
    AVG(home_goal) OVER(PARTITION BY season) AS season_homeavg,
    AVG(away_goal) OVER(PARTITION BY season) AS season_awayavg,
    AVG(home_goal) OVER(PARTITION BY season, EXTRACT(MONTH FROM date)) AS season_mo_home,
    AVG(away_goal) OVER(PARTITION BY season, EXTRACT(MONTH FROM date)) AS season_mo_away,
    SUM(home_goal) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_1,
    SUM(home_goal) OVER(ORDER BY date ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS running_total_2
FROM localtest.dtc_match
WHERE hometeam_id = 1773
ORDER BY season, month DESC;






WITH 
Athletics_Gold AS (
    SELECT DISTINCT Gender, Year, Event, Country
    FROM localtest.dtc_summer_medals
    WHERE Year >= 1900 AND Medal = 'Gold'
)

SELECT
    Gender, Year, Event, Country AS Champion,
    LAG(Country) OVER (PARTITION BY Gender, Event ORDER BY Year ASC) AS Last_Champion
FROM Athletics_Gold
ORDER BY Event ASC, Gender ASC, Year ASC;








WITH 
Athlete_Medals AS (
    SELECT Country, Athlete, COUNT(*) AS Medals
    FROM localtest.dtc_summer_medals
    WHERE Year >= 1900
    GROUP BY Country, Athlete
    HAVING COUNT(*) > 1)

SELECT
    Country, Athlete, Medals,
    DENSE_RANK() OVER (PARTITION BY Country ORDER BY Medals DESC) AS Rank_N_Dense,
    RANK() OVER (PARTITION BY Country ORDER BY Medals DESC) AS Rank_N,
    ROW_NUMBER() OVER (PARTITION BY Country ORDER BY Medals DESC) AS Rank_N_Row
FROM Athlete_Medals
ORDER BY Country ASC, RANK_N ASC;








-- WINDOW FUNCTION --------------------------------------------------------------------------------------------------------------------------------------
-- RANK HOW BADLY MANCHESTER LOSS

SELECT 
	m.date,
    t1.team_long_name AS home_team,
    t2.team_long_name AS away_team,
    m.home_goal, m.away_goal,
    RANK() OVER(ORDER BY ABS(home_goal - away_goal) DESC) as match_rank

FROM localtest.dtc_match AS m

LEFT JOIN localtest.dtc_team AS t1 
ON m.hometeam_id = t1.team_api_id

LEFT JOIN localtest.dtc_team AS t2 
ON m.awayteam_id = t2.team_api_id

WHERE (t1.team_long_name = 'Manchester United' AND home_goal < away_goal) OR (t2.team_long_name = 'Manchester United' AND home_goal > away_goal)











-- WINDOW FUNCTION --------------------------------------------------------------------------------------------------------------------------------------
-- SORT/RANK ATHLETE BY TOTAL NUMBER OF MEDALS

WITH 
Athlete_Medals AS (
    SELECT Athlete, COUNT(*) AS Medals
    FROM localtest.dtc_summer_medals
    GROUP BY Athlete
)

SELECT Athlete, Medals, ROW_NUMBER() OVER (ORDER BY Medals DESC) AS Row_N
FROM Athlete_Medals
ORDER BY Medals DESC;










-- PAGING & SORT --------------------------------------------------------------------------------------------------------------------------------------

WITH 
Athlete_Medals AS (
    SELECT Athlete, COUNT(*) AS Medals
    FROM localtest.dtc_summer_medals
    GROUP BY Athlete
    HAVING COUNT(*) > 1
),
Thirds AS (
    SELECT Athlete, Medals, NTILE(5) OVER (ORDER BY Medals DESC) AS Page
    FROM Athlete_Medals
)

SELECT Page, AVG(Medals) AS Avg_Medals
FROM Thirds
GROUP BY Page
ORDER BY Page DESC;




----------------------------------------------------------------------------------------

WITH 
Country_Medals AS (
    SELECT Year, Country, COUNT(*) AS Medals
    FROM localtest.dtc_summer_medals
    WHERE Year >= 1900
    GROUP BY Year, Country
)

SELECT
    Country, Year, Medals,
    MAX(Medals) OVER (PARTITION BY Country ORDER BY Year ASC) AS Max_Medals
FROM Country_Medals
ORDER BY Country ASC, Year ASC;





-------------------------------------------------------------------------------------------

WITH 
Country_Medals AS (
    SELECT Year, Country, COUNT(*) AS Medals
    FROM localtest.dtc_summer_medals
    GROUP BY Year, Country)

SELECT
    Year, Country, Medals,
    SUM(Medals) OVER (PARTITION BY Country ORDER BY Year ASC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Medals_MA_ROWS,
    SUM(Medals) OVER (PARTITION BY Country ORDER BY Year ASC RANGE BETWEEN 2 PRECEDING AND CURRENT ROW) AS Medals_MA_RANGE
FROM Country_Medals
ORDER BY Country ASC, Year ASC;












-- ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????
WITH 
Country_Medals AS (
    SELECT Year, Country, COUNT(*) AS Medals
    FROM localtest.dtc_summer_medals
    GROUP BY Year, Country)

SELECT
    Year, Country, Medals,
    SUM(Medals) OVER (ORDER BY Year ASC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Medals_MA_ROWS,
    SUM(Medals) OVER (ORDER BY Year ASC RANGE BETWEEN 2 PRECEDING AND CURRENT ROW) AS Medals_MA_RANGE
FROM Country_Medals









-- PIVOT ------??????????????????????????????????????????????????????????????????????????????

CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT * 
FROM CROSSTAB($$
    SELECT Gender, Year, Country
    FROM localtest.dtc_summer_medals
    WHERE Event = 'Pole Vault'
    ORDER By Gender ASC, Year ASC;

$$) AS ct (
    Gender VARCHAR,
    '2008' VARCHAR,
    '2012' VARCHAR
)
ORDER BY Gender ASC;




-- PIVOT ------??????????????????????????????????????????????????????????????????????????????
WITH 
Subquery AS (
	SELECT DISTINCT Gender, Year, Country
    FROM localtest.dtc_summer_medals
    WHERE Event = 'Pole Vault'
    ORDER By Gender ASC, Year ASC
) 

SELECT DISTINCT 
	Gender,
	CASE WHEN Year = 1896 THEN Country ELSE NULL END AS "1896", 
	CASE WHEN Year = 1900 THEN Country ELSE NULL END AS "1900"
FROM Subquery






-- ROLLUP ---------------------------------------------------------------------------------------------------------------------------------------------------
-- Count the gold medals per country and gender

SELECT Country, Gender, COUNT(*) AS Gold_Awards
FROM localtest.dtc_summer_medals
WHERE Year = 2004 AND Medal = 'Gold' AND Country IN ('DEN', 'NOR', 'SWE')
GROUP BY Country, ROLLUP(Gender)
ORDER BY Country ASC, Gender ASC;