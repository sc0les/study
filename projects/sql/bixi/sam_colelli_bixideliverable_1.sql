-- Question 1

-- 1.1: Total number of trips for the year of 2016
-- Answer: 3,917,401
SELECT DISTINCT COUNT(id)
FROM trips
WHERE start_date BETWEEN '2016-01-01' AND '2016-12-31';

-- 1.2: Total number of trips for the year of 2017
-- Answer: 4,666,765
SELECT DISTINCT COUNT(id)
FROM trips
WHERE start_date BETWEEN '2017-01-01' AND '2017-12-31';

-- 1.3: Total number of trips for the year 2016, broken down by month
SELECT MONTH(start_date) as month, COUNT(id)
FROM trips
WHERE start_date BETWEEN '2016-01-01' AND '2016-12-31'
GROUP BY 1
ORDER BY month ASC;

-- 1.4: Total number of trips for the year 2017, broken down by month
SELECT MONTH(start_date) as month, COUNT(id)
FROM trips
WHERE start_date BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY 1
ORDER BY month ASC;

-- 1.5: Average number of trips per day for each year-month combination in dataset
SELECT EXTRACT(YEAR_MONTH FROM start_date) as yearmonth, AVG(num_trips) as daily_avg_trips
FROM (
	SELECT start_date, COUNT(id) as num_trips
    FROM trips
    GROUP BY 1
    ) as trip_table
GROUP BY 1;

-- 1.6: Save above query as a table
DROP TABLE IF EXISTS `working_table1`;
CREATE TABLE `working_table1` AS
SELECT EXTRACT(YEAR_MONTH FROM start_date) as yearmonth, AVG(num_trips) as daily_avg_trips
FROM (
	SELECT start_date, COUNT(id) as num_trips
    FROM trips
    GROUP BY 1
    ) as trip_table
GROUP BY 1;
-- ALSO SAVED AS VIEW --------------------
DROP VIEW IF EXISTS `working_table1`;
CREATE VIEW `working_table1` AS
SELECT EXTRACT(YEAR_MONTH FROM start_date) as yearmonth, AVG(num_trips) as daily_avg_trips
FROM (
	SELECT start_date, COUNT(id) as num_trips
    FROM trips
    GROUP BY 1
    ) as trip_table
GROUP BY 1;

-- Question 2

-- 2.1: Total number of trips in the year 2017 broken-down by membership status (member/non_member)
SELECT is_member, COUNT(id) as num_trips
FROM trips
WHERE start_date BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY 1;

-- 2.2: Fraction of total trips that were done by members for the year of 2017 broken-down by month
-- Since is_member was a boolean, we can simply do a sum. If it wasn't we'd have to do CASE WHEN
SELECT MONTH(start_date) as trip_month, SUM(is_member) / COUNT(id) AS pct_members
FROM trips
WHERE start_date BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY trip_month;

-- Question 3

-- 3.1: Which time of the year the demand for Bixi bikes is at its peak?
-- Didn't do a MAX() since other months were close and its important to see the trend. The summer months are peak demand, especially June.
SELECT MONTH(end_date) as trip_month, COUNT(id) as count
FROM trips
GROUP BY 1
ORDER BY count DESC;


-- If you were to offer non-members a special promotion in an attempt to convert them to members, when would you do it?
-- You'd offer it in the warming summer months, but most likely in May or June in order to maximize your exposure throughout summer, since promo campaigns can be multiple months long
-- Since members clearly drive off-peak month usage, it would be important to convert members prior to those months occuring
SELECT MONTH(start_date) as trip_month, SUM(is_member) / COUNT(id) AS pct_members, COUNT(id) AS total_trips
FROM trips
WHERE start_date BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY trip_month;

-- Question 4

-- What are the names of the 5 most popular stations (No subquery)
-- 11.8 sec run time
SELECT name, COUNT(trips.id) as trip_station_count
FROM stations
LEFT JOIN trips ON trips.start_station_code = stations.code
GROUP BY 1
ORDER BY trip_station_count DESC
LIMIT 5;

-- Same as above, with subquery
-- 0.87 sec run time
SELECT name, code, count
FROM (
	SELECT start_station_code, COUNT(id) as count
    FROM trips
    GROUP BY 1
    ORDER BY count DESC
    LIMIT 5
    ) as tt
LEFT JOIN stations ON stations.code = tt.start_station_code;

-- Question 5

-- How is the number of starts and ends distributed for the station Mackay / de Maisonneuve throughout the day?
-- To be honest, I'm not totally sure if UNION was the right move here. I could have done a cross join, but UNION was a lot cleaner looking. 
-- More ending trips in the morning, starting trips in the evening. Can reasonably hypothesize that this is a work commute hub.
SELECT COUNT(id) AS count, 
	CASE
		WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "start_morning"
		WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "start_afternoon"
		WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "start_evening"
		ELSE "start_night"
	END AS "time_of_day"
FROM trips
RIGHT JOIN stations ON stations.code = trips.start_station_code
WHERE start_station_code = 6100
GROUP BY 2

UNION

SELECT COUNT(id) AS count, 
	CASE
		WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN "end_morning"
		WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN "end_afternoon"
		WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN "end_evening"
		ELSE "end_night"
	END AS "time_of_day"
FROM trips
RIGHT JOIN stations ON stations.code = trips.start_station_code
WHERE end_station_code = 6100
GROUP BY 2
ORDER BY count DESC;


-- Question 6
-- For this question, specifically 6.2 through 6.4, I've provided 2 answers. The first is the simplier, cleaner version. The second is the more efficient version.
-- I was hitting a lot of timeout errors with the clean version for some reason, so I put in some subqueries to lessen the load.

-- 6.1: Write a query that counts the number of starting trips per station
SELECT start_station_code, COUNT(id)
FROM trips
GROUP BY 1;

-- 6.2: Write a query that counts, for each station, the number of round trips

SELECT start_station_code, COUNT(id)
FROM trips
WHERE start_station_code = end_station_code
GROUP BY 1;

-- OR ---------------------

SELECT start_station_code, SUM(count) as num_rt
FROM (
	SELECT start_station_code, end_station_code, COUNT(id) as count
	FROM trips
	GROUP BY 1,2
	) as tt
WHERE start_station_code = end_station_code
GROUP BY 1;


-- 6.3: Combine the above queries and calculate the fraction of round trips to the total number of starting trips for each station
SELECT start_station_code, num_rt/(SELECT COUNT(id) FROM trips WHERE trips.start_station_code = rt_table.start_station_code) as pct_rt
FROM (
	SELECT start_station_code, COUNT(id) AS num_rt
    FROM trips
    WHERE start_station_code = end_station_code
    GROUP BY 1
    ) as rt_table
GROUP BY 1;

-- OR ------------------------------

SELECT start_station_code, num_rt / (SELECT COUNT(id) FROM trips WHERE trips.start_station_code = rt.start_station_code) as pct
FROM (
	SELECT start_station_code, SUM(count) as num_rt
	FROM (
		SELECT start_station_code, end_station_code, COUNT(id) as count
		FROM trips
		GROUP BY 1,2
		) as tt
	WHERE start_station_code = end_station_code
	GROUP BY 1
    ) as rt
GROUP BY 1
ORDER BY pct DESC;

-- 6.4: Filter down to stations with at least 500 trips originating from them and having at least 10% of their trips as round trips
SELECT *
FROM (
	SELECT start_station_code, num_rt/(SELECT COUNT(id) FROM trips WHERE trips.start_station_code = rt_table.start_station_code) as pct_rt
	FROM (
		SELECT start_station_code, COUNT(id) AS num_rt
		FROM trips
		WHERE start_station_code = end_station_code
		GROUP BY 1
		) as rt_table
	WHERE num_rt > 500
	GROUP BY 1
    ) as pct_rt_table
WHERE pct_rt > .10;

-- OR -------------------

SELECT *
FROM (
	SELECT start_station_code, num_rt / (SELECT COUNT(id) FROM trips WHERE trips.start_station_code = rt.start_station_code) as pct
	FROM (
		SELECT start_station_code, SUM(count) as num_rt
		FROM (
			SELECT start_station_code, end_station_code, COUNT(id) as count
			FROM trips
			GROUP BY 1,2
			) as num_rt_table
		WHERE start_station_code = end_station_code
		GROUP BY 1
		) as station_rt_table
	WHERE num_rt > 500
	GROUP BY 1
    ) as pct_rt_table
WHERE pct > .1
ORDER BY pct DESC;

-- 6.5: Where would you expect to find stations with a high fraction of round trips?
-- Figured this was a critical thinking question, since there were only 9 stations that fit the above criteria.
-- The most likely locations with high round trip volume is most likely office complexes or professional hubs, and college campuses


