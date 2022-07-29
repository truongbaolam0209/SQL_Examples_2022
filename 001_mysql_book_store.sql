


-- MYSQL ROLLUP ------------------------------------------------------------------------------------------------------------
-- https://www.mysqltutorial.org/mysql-rollup/

/*
CREATE TABLE sales
SELECT
	productLine,
    YEAR(orderDate) orderYear,
    SUM(quantityOrdered * priceEach) orderValue
    
FROM orderDetails

INNER JOIN orders 
USING (orderNumber)

INNER JOIN products 
USING (productCode)

GROUP BY productLine, YEAR(orderDate);
*/

/*
SELECT productline, SUM(orderValue) AS totalOrderValue
FROM sales
GROUP BY productline 
UNION ALL
SELECT NULL, SUM(orderValue) totalOrderValue
FROM sales
*/


SELECT 
    IF(GROUPING(orderYear), 'All Years', orderYear) AS orderYear,
    IF(GROUPING(productLine), 'All Product Lines', productLine) AS productLine,
    SUM(orderValue) AS totalOrderValue,
    GROUPING(productLine), GROUPING(orderYear)
FROM sales
GROUP BY productline, orderYear WITH ROLLUP