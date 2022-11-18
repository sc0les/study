-- Refining the definition of an 'Unsuccessful' campaign by seeing if outcomes outside of 'failed' and 'successful' hit their goal.
-- 'PercentSuccess' represents the percentage of campaigns that technically hit their goal, but are not classified as 'successful'.
SELECT campaign.outcome, avg(length), count(success.id), count(campaign.id), (count(success.id)/count(campaign.id)) as PercentSuccess
FROM (
	SELECT outcome, id, timestampdiff(DAY,launched,deadline) as length
	FROM new_schema.campaign
    WHERE pledged >= goal
    ) as success
RIGHT OUTER JOIN new_schema.campaign ON success.id = new_schema.campaign.id
WHERE new_schema.campaign.outcome IN ('suspended', 'canceled', 'undefined', 'live')
GROUP BY 1


-- Finding the average, minimum, and maximum for successful and unsuccessful campaigns.

-- Avg, Min, Max for Money Raised Grouped By Outcome
SELECT outcome, count(id) as Campaigns, avg(pledged) as Average, min(pledged) as Minimum, max(pledged) as Maximum
FROM new_schema.campaign
GROUP BY 1

-- Avg, Min, Max for Goal Grouped By Outcome
SELECT outcome, count(id) as Campaigns, avg(goal) as Average, min(goal) as Minimum, max(goal) as Maximum
FROM new_schema.campaign
GROUP BY 1

-- The large range and distribution of pledged dollars shows that average, without removing outliers, does not best represent future expected outcomes.

-- Median for Money Raised, Grouped by Outcome, 4 Buckets
SELECT outcome, count(outcome) as Campaigns, Quartile, max(pledged) as MaxPledged
FROM (
	SELECT outcome, pledged, NTILE(4) OVER(PARTITION BY outcome ORDER BY pledged) as Quartile
	FROM new_schema.campaign
    ) as quartable
WHERE quartile <= 4
GROUP BY outcome, quartile

-- Median for Money Raised, Grouped by Outcome, 10 Buckets
SELECT outcome, count(outcome) as Campaigns, Quartile, max(pledged) as MaxPledged
FROM (
	SELECT outcome, pledged, NTILE(10) OVER(PARTITION BY outcome ORDER BY pledged) as Quartile
	FROM new_schema.campaign
    WHERE pledged > 0
    ) as quartable
WHERE quartile <= 10
GROUP BY outcome, quartile

-- Median for Goal, Grouped By Outcome, 4 Buckets
SELECT outcome, count(outcome) as Campaigns, Quartile, max(goal) as MaxGoal
FROM (
	SELECT outcome, goal, NTILE(4) OVER(PARTITION BY outcome ORDER BY goal) as Quartile
	FROM new_schema.campaign
    ) as quartable
WHERE quartile <= 4
GROUP BY outcome, quartile

-- Median for Goal, Grouped By Outcome, 10 Buckets
SELECT outcome, count(outcome) as Campaigns, Quartile, max(goal) as MaxGoal
FROM (
	SELECT outcome, goal, NTILE(10) OVER(PARTITION BY outcome ORDER BY goal) as Quartile
	FROM new_schema.campaign
    WHERE goal > 0
    ) as quartable
WHERE quartile <= 10
GROUP BY outcome, quartile

-- Below is top/bottom categories and subcatgories

-- Backers for Category
SELECT *
FROM (
	SELECT
		RANK() OVER(ORDER BY max(backers) DESC) as backers_rank,
		category_name,
		max(backers) as median_backers
	FROM (
		SELECT
			category.name as category_name,
			category.id as category_id,
			sub_category.name as sub_category_name,
			sub_category_id,
			backers,
			outcome,
			NTILE(4) OVER(PARTITION BY category_id ORDER BY backers) as backers_quartile
		FROM new_schema.campaign
		JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
		JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
		WHERE outcome = 'successful'
		) as backers_quartable
	WHERE backers_quartile = 2
    GROUP BY 2
    ) as temp_table
WHERE backers_rank <= 3 OR backers_rank >= 13


-- Pledged for Category
SELECT *
FROM (
	SELECT
		RANK() OVER(ORDER BY max(pledged) DESC) as pledged_rank,
		category_name,
		count(category_id) as Campaigns,
		max(pledged) as median_pledged
	FROM (
		SELECT
			category.name as category_name,
			category.id as category_id,
			sub_category.name as sub_category_name,
			sub_category_id,
			pledged,
			outcome,
			NTILE(4) OVER(PARTITION BY category_id ORDER BY pledged) as Quartile
		FROM new_schema.campaign
		JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
		JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
		WHERE outcome = 'successful'
		) as quartable
	WHERE quartile = 2
    GROUP BY 2
    ) as temp_table
WHERE pledged_rank <= 3 OR pledged_rank >= 13


-- Backers for Subcategory
SELECT *
FROM (
	SELECT
		RANK() OVER(ORDER BY max(backers) DESC) as backers_rank,
		sub_category_name,
		count(sub_category_id) as Campaigns,
		max(backers) as median_backers
	FROM (
		SELECT
			category.name as category_name,
			category.id as category_id,
			sub_category.name as sub_category_name,
			sub_category_id,
			backers,
			outcome,
			NTILE(4) OVER(PARTITION BY sub_category_id ORDER BY backers) as backers_quartile
		FROM new_schema.campaign
		JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
		JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
		WHERE outcome = 'successful'
		) as backers_quartable
	WHERE backers_quartile = 2
    GROUP BY 2
    ) as temp_table
WHERE backers_rank <= 3 OR backers_rank >= 139


-- Pledged for Subcategory
SELECT *
FROM (
	SELECT
		RANK() OVER(ORDER BY max(pledged) DESC) as pledged_rank,
		sub_category_name,
		count(sub_category_id) as Campaigns,
		max(pledged) as median_pledged
	FROM (
		SELECT
			category.name as category_name,
			category.id as category_id,
			sub_category.name as sub_category_name,
			sub_category_id,
			pledged,
			outcome,
			NTILE(4) OVER(PARTITION BY sub_category_id ORDER BY pledged) as pledged_quartile
		FROM new_schema.campaign
		JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
		JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
		WHERE outcome = 'successful'
		) as pledged_quartable
	WHERE pledged_quartile = 2
    GROUP BY 2
    ) as temp_table
WHERE pledged_rank <= 3 OR pledged_rank >= 139

-- Top subcategories within 'Games'

SELECT *
FROM (
	SELECT
		RANK() OVER(ORDER BY max(backers) DESC) as backers_rank,
		sub_category_name,
        category_name,
		count(sub_category_id) as Campaigns,
		max(backers) as median_backers,
        avg(backers) as average_backers
	FROM (
		SELECT
			category.name as category_name,
			category.id as category_id,
			sub_category.name as sub_category_name,
			sub_category_id,
			backers,
			outcome,
			NTILE(4) OVER(PARTITION BY sub_category_id ORDER BY backers) as backers_quartile
		FROM new_schema.campaign
		JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
		JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
		WHERE outcome = 'successful'
		) as backers_quartable
	WHERE backers_quartile = 2
    GROUP BY 2,3
    ) as temp_table
WHERE category_name = 'Games'


-- top countries

-- First, we'll look at the total number of backers and amount of money raised by country
SELECT 
	RANK() OVER(ORDER by sum(pledged) DESC) as sum_pledged_rank,
    new_schema.country.name,
    count(new_schema.campaign.id),
    sum(backers),
    sum(pledged)
FROM new_schema.campaign
JOIN new_schema.country ON new_schema.campaign.country_id = new_schema.country.id
GROUP BY 2

-- Now, we'll look at the same stats, but only for successful campaigns
SELECT 
	RANK() OVER(ORDER by sum(pledged) DESC) as sum_pledged_rank,
    new_schema.country.name,
    count(new_schema.campaign.id),
    sum(backers),
    sum(pledged)
FROM new_schema.campaign
JOIN new_schema.country ON new_schema.campaign.country_id = new_schema.country.id
WHERE new_schema.campaign.outcome = 'successful'
GROUP BY 2

-- While it's good to know the total stats by country, we want to see the expectations of a given successful campaign by country
SELECT 
	RANK() OVER(ORDER by avg(pledged) DESC) as sum_pledged_rank,
    new_schema.country.name,
    count(new_schema.campaign.id),
    avg(backers),
    avg(pledged)
FROM new_schema.campaign
JOIN new_schema.country ON new_schema.campaign.country_id = new_schema.country.id
WHERE new_schema.campaign.outcome = 'successful'
GROUP BY 2

-- top countries by median pledged
SELECT *
FROM (
	SELECT
		RANK() OVER(ORDER BY max(pledged) DESC) as pledged_rank,
		country_name,
		max(pledged) as median_pledged
	FROM (
		SELECT
			country.name as country_name,
			country.id as country_id,
            backers,
			pledged,
			outcome,
			NTILE(4) OVER(PARTITION BY country_id ORDER BY pledged) as Quartile
		FROM new_schema.campaign
		JOIN new_schema.country ON new_schema.campaign.country_id = country.id
        JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
		JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
		WHERE outcome = 'successful'
        AND new_schema.sub_category.name = 'Tabletop Games'
		) as quartable
	WHERE quartile = 2
    GROUP BY 2
    ) as temp_table

-- top countries for successful tabletop campaigns by median backers
SELECT *
FROM (
	SELECT
		RANK() OVER(ORDER BY max(backers) DESC) as backers_rank,
		country_name,
		max(backers) as median_backers
	FROM (
		SELECT
			country.name as country_name,
			country.id as country_id,
            backers,
			pledged,
			outcome,
			NTILE(4) OVER(PARTITION BY country_id ORDER BY backers) as Quartile
		FROM new_schema.campaign
		JOIN new_schema.country ON new_schema.campaign.country_id = country.id
        JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
		JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
		WHERE outcome = 'successful'
        AND new_schema.sub_category.name = 'Tabletop Games'
		) as quartable
	WHERE quartile = 2
    GROUP BY 2
    ) as temp_table

-- count of successful tabletop games by country
SELECT
	new_schema.country.name,
    count(new_schema.campaign.id)
FROM new_schema.campaign
JOIN new_schema.country ON new_schema.campaign.country_id = country.id
JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
WHERE outcome = 'successful'
AND new_schema.sub_category.name = 'Tabletop Games'
GROUP BY 1



-- most successful tabletop game
SELECT *
FROM (
	SELECT
		RANK() OVER(ORDER BY pledged DESC) as pledged_rank,
		campaign.id,
		category.name as category_name,
		category.id as category_id,
		sub_category.name as sub_category_name,
		sub_category_id,
        timestampdiff(DAY,launched,deadline) as length,
		backers,
		outcome,
		pledged
	FROM new_schema.campaign
	JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
	JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
	WHERE outcome = 'successful'
	AND sub_category_id = 14
	) as top_tt_campaign_table
WHERE pledged_rank = 1


-- longer vs shorter campaigns and sum, average of $ fundraised
SELECT
    timestampdiff(DAY,launched,deadline) as length,
    count(outcome),
    sum(pledged),
    avg(pledged)
FROM new_schema.campaign
WHERE outcome = 'successful'
GROUP BY 1
ORDER BY length ASC

-- median of $ raised by length
SELECT *
FROM (
	SELECT
		length,
		max(pledged) as median_pledged
	FROM (
		SELECT
			pledged,
			outcome,
            timestampdiff(DAY,launched,deadline) as length,
			NTILE(4) OVER(PARTITION BY timestampdiff(DAY,launched,deadline) ORDER BY pledged) as Quartile
		FROM new_schema.campaign
		JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
		JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
		WHERE outcome = 'successful'
		) as quartable
	WHERE quartile = 2
    GROUP BY 1
    ) as temp_table
    
-- length + median ranged by outcome
SELECT
	CAST(launched as DATE) as launch_date,
    outcome,
    count(campaign.id) as campaign_count
FROM new_schema.campaign
JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
WHERE outcome IN ('successful', 'failed')
AND new_schema.sub_category.name = 'Tabletop Games'
GROUP BY 1,2

-- avg pledged amount per backer
SELECT avg(pledged / backers)
FROM new_schema.campaign
JOIN new_schema.sub_category ON new_schema.campaign.sub_category_id = sub_category.id
JOIN new_schema.category ON new_schema.sub_category.category_id = category.id
WHERE pledged > 11868
AND outcome = 'successful'
AND new_schema.sub_category.name = 'Tabletop Games'