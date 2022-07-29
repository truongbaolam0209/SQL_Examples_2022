
WITH 
summary_table_1 AS (
	SELECT * 
    FROM cd.members
    INNER JOIN cd.bookings
    ON cd.members.memid = cd.bookings.memid
	INNER JOIN cd.facilities
	ON cd.facilities.facid = cd.bookings.facid
),
subquery_table_1 AS (
	SELECT 
		firstname || ' ' || surname AS member_name,
		CASE
			WHEN name LIKE ('Massage Room%') THEN 'Massage Room'
			ELSE 'Tennise Court'
		END AS cate_name,
        EXTRACT(MONTH FROM starttime) as month_name,
		slots * membercost AS costs

	FROM summary_table_1
    
	WHERE (name LIKE 'Tennis Court%' OR name LIKE 'Massage Room%') 
		AND EXTRACT(MONTH FROM starttime) = 9 
		AND EXTRACT(YEAR FROM starttime) = 2012 
		AND (surname != 'GUEST' AND firstname != 'GUEST')
)


SELECT member_name, cate_name, month_name, SUM(costs) AS total_cost

FROM subquery_table_1

GROUP BY member_name, cate_name, month_name

ORDER BY member_name


--------------------------------------------------------------------------------------------------------------------

WITH summary_table_2 AS (
	SELECT 
		cdf.name, 
		SUM(slots * CASE WHEN memid = 0 THEN cdf.guestcost ELSE cdf.membercost END) AS revenue
		
	FROM cd.bookings AS cdb
	INNER JOIN cd.facilities AS cdf
	ON cdb.facid = cdf.facid
	GROUP BY cdf.name
	ORDER BY revenue
)

SELECT * FROM summary_table_2

WHERE revenue < 1000





