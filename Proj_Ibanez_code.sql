 SELECT *
 FROM subscriptions
 LIMIT 100; 
 
 /*From looking at the first 100 lines, there appears to be be 2 segments; 30 and 87*/
 
 SELECT MIN(subscription_start), MAX(subscription_end)
 FROM subscriptions;
 
 /*We have data for four months: December 2016 - March 2017 */

 SELECT MIN(subscription_end)
 FROM subscriptions;

 /* We can only calculate the churn rate for January onwards since the first cancelation date is in January*/

 WITH months AS
 (
 	SELECT
   '2017-01-01' AS first_day,
   '2017-01-31' AS last_day
  UNION
  SELECT
   '2017-02-01' AS first_day,
   '2017-02-28' AS last_day
  UNION
  SELECT
   '2017-03-01' AS first_day,
   '2017-03-31' AS last_day
 ),
 
cross_join AS
(
	SELECT subscriptions.*, months.*
  	FROM subscriptions
  	CROSS JOIN months
),

status AS
(
	SELECT cross_join.id, cross_join.first_day AS 'month',
	CASE
		WHEN
		(
			(cross_join.segment = 87) AND (cross_join.subscription_start < cross_join.first_day)
		)
		AND (cross_join.subscription_end >= cross_join.first_day)
		OR (cross_join.subscription_end IS NULL)
		THEN 1
		ELSE 0
	END 
	AS is_active_87,

	CASE
		WHEN
		(
			(cross_join.segment = 87) AND
			(
				(cross_join.subscription_end >= cross_join.first_day AND cross_join.subscription_end < cross_join.last_day)
			)
		)
		THEN 1
		ELSE 0
	END
	AS is_canceled_87,

	CASE
		WHEN
		(
			(cross_join.segment = 30) AND (cross_join.subscription_start < cross_join.first_day)
		)
		AND (cross_join.subscription_end >= cross_join.first_day)
		OR (cross_join.subscription_end IS NULL)
		THEN 1
		ELSE 0
	END 
	AS is_active_30,

	CASE
		WHEN
		(
			(cross_join.segment = 30) AND
			(
				(cross_join.subscription_end >= cross_join.first_day AND cross_join.subscription_end < cross_join.last_day)
			)
		)
		THEN 1
		ELSE 0
	END
	AS is_canceled_30

	FROM cross_join
),

status_aggregate AS
(
SELECT status.month, SUM(status.is_active_87) AS sum_active_87, SUM(status.is_active_30) AS sum_active_30,
	SUM(status.is_canceled_87) AS sum_canceled_87, SUM(status.is_canceled_30) AS sum_canceled_30
FROM status
GROUP BY 1
),

churn_rates AS 
(
 SELECT status_aggregate.month, 
 	(
 		1.0 * (status_aggregate.sum_canceled_87) / (status_aggregate.sum_active_87)
 	) AS churn_87,
 	(
 		1.0 * (status_aggregate.sum_canceled_30) / (status_aggregate.sum_active_87)
 	) AS churn_30
 FROM status_aggregate
 GROUP BY 1
)

SELECT *
FROM churn_rates
;

/* The churn rates are lower for the 30 segment */ 

/* If we were to have a large number of segments, we would need to soft code the segments numbers. 
	This way we can write the code once, and change the parmeters so that we can calculate the 
	churn rate for each segment. We could create a table with all the churn rates we want to crate and reference the 
	rows of the table in our code and have it run n-times (where n is the number of rows) referencing each row 
	each time it runs (similar to a FOR loop)*/

