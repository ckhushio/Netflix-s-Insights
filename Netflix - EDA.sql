SELECT TOP 1 * FROM subscription_data
SELECT TOP 1 * FROM consumption_data
SELECT TOP 1 * FROM rating_data
SELECT TOP 1 * FROM catalogue_data

--EDA
--Subscription data
/*
  -- Total Users/Total Subscriptions/Total Revenue
  -- % Subscription by plan_type/ AOV by Plan_type
  -- % Subscription by Duration
  -- Month on Month New Subscriptions/Total Revenue
  -- Repeated Customers by Month
  -- When users are purchasing
*/

---- Total Users/Total Subscriptions/Total Revenue
SELECT COUNT(DISTINCT A.user_id) AS Total_Users,
COUNT(A.subscription_key) AS Total_Subscriptions,
SUM(A.amount_paid) AS Total_Revenue
FROM subscription_data AS A

--% Subscription by plan_type/ AOV by Plan_type

SELECT A.plan_type,
cast(round((COUNT(A.subscription_key)*1.00/(SELECT COUNT(*)  FROM subscription_data))*100,2) AS float) AS Subs_Perc,
ROUND(AVG(A.amount_paid),2) AS AOV
FROM subscription_data AS A
WHERE A.plan_type IS NOT NULL
GROUP BY A.plan_type

-- % Subscription by Duration

SELECT DATEDIFF(MONTH,A.subscription_start_date,A.subscription_end_date) AS Month_,
cast(round((COUNT(A.subscription_key)*1.00/(SELECT COUNT(*)  FROM subscription_data))*100,2) AS float) AS Subs_Perc
FROM subscription_data AS A
GROUP BY  DATEDIFF(MONTH,A.subscription_start_date,A.subscription_end_date)
ORDER BY Subs_Perc DESC

 -- Month on Month New Subscriptions/Total Revenue

 SELECT MONTH(A.subscription_created_date) AS Month_,
 COUNT(A.subscription_key) AS Cnt_Subs,
 SUM(A.amount_paid) AS Revenue
 FROM subscription_data AS A
 GROUP BY MONTH(A.subscription_created_date)
 ORDER BY Month_ ASC

  -- When users are purchasing
  SELECT DATENAME(WEEKDAY,A.subscription_created_date) AS WEEKDAY_,
  cast(round((COUNT(A.subscription_key)*1.00/(SELECT COUNT(*)  FROM subscription_data))*100,2) AS float) AS Subs_Perc
  FROM subscription_data AS A
  GROUP BY DATENAME(WEEKDAY,A.subscription_created_date)
  ORDER BY Subs_Perc DESC

  SELECT 
     CASE
	      WHEN DATEPART(HOUR,A.subscription_created_time) < 4 THEN 'Early Morning'
		  WHEN DATEPART(HOUR,A.subscription_created_time) < 8 THEN 'Morning'
		  WHEN DATEPART(HOUR,A.subscription_created_time) < 12 THEN 'Late Morning'
		  WHEN DATEPART(HOUR,A.subscription_created_time) < 16 THEN 'Afternoon'
		  WHEN DATEPART(HOUR,A.subscription_created_time) < 20 THEN 'Evening'
		  ELSE 'Night'
		  END AS Day_Seg,
 cast(round((COUNT(A.subscription_key)*1.00/(SELECT COUNT(*)  FROM subscription_data))*100,2) AS float) AS Subs_Perc
FROM subscription_data AS A
GROUP BY CASE
	      WHEN DATEPART(HOUR,A.subscription_created_time) < 4 THEN 'Early Morning'
		  WHEN DATEPART(HOUR,A.subscription_created_time) < 8 THEN 'Morning'
		  WHEN DATEPART(HOUR,A.subscription_created_time) < 12 THEN 'Late Morning'
		  WHEN DATEPART(HOUR,A.subscription_created_time) < 16 THEN 'Afternoon'
		  WHEN DATEPART(HOUR,A.subscription_created_time) < 20 THEN 'Evening'
		  ELSE 'Night'
		  END
ORDER BY Subs_Perc DESC


-- Repeated Customers by Month
select T3.Month_ ,COUNT(*) AS New_Cust
from(

                 SELECT T1.*,T2.Month_,T2.First_tran_date_USER_MONTH,
				 CASE WHEN First_tran_date_USER = First_tran_date_USER_MONTH THEN 'New'
				      ELSE 'Existing' 
					  END AS User_Type
                 FROM (
                               SELECT A.user_id,MIN(A.subscription_created_date) AS First_tran_date_USER
                               FROM subscription_data AS A
                               GROUP BY A.user_id
                 			  ) AS T1
                 INNER JOIN (
                             SELECT MONTH(A.subscription_created_date) AS Month_,A.user_id,
                             MIN(A.subscription_created_date) AS First_tran_date_USER_MONTH
                             FROM subscription_data AS A
                             GROUP BY MONTH(A.subscription_created_date),A.user_id
                 			) AS T2
                 ON T1.user_id = T2.user_id
                 --ORDER BY T1.user_id,T2.Month_
				 ) AS T3
WHERE T3.User_Type = 'New'
GROUP BY T3.Month_
ORDER BY T3.Month_

---Consumption data
/*
  --Avg User Duration
  --Content with highest Views.
  -- Sessions Distribution by Paltform type.
  -- Content brought the most number of users to the platform.
  -- Competion Rate 

*/
--Avg User Duration
SELECT AVG(A.user_duration) AS Avg_User_Duration
FROM consumption_data AS A

--Content with highest Views.
SELECT TOP 1 A.content_id,COUNT(DISTINCT A.userid) AS Total_Views
FROM consumption_data AS A
GROUP BY A.content_id
ORDER BY Total_Views DESC

-- % Sessions Distribution by Paltform type.
SELECT A.platform,
CAST(round((COUNT(A.usersessionid)*1.00/(SELECT COUNT(*) FROM consumption_data))*100,2) AS float) AS Sessions_Perc
FROM consumption_data AS A
WHERE A.platform IS NOT NULL
GROUP BY A.platform

---- Content brought the most number of users to the platform.
SELECT TOP 1 A.content_id,COUNT(DISTINCT B.user_id) AS Cnt_Users
FROM consumption_data AS A
INNER JOIN subscription_data AS B
ON CAST(A.consumption_date AS date) = B.subscription_start_date
AND A.userid = B.user_id
GROUP BY A.content_id
ORDER BY Cnt_Users DESC

--Completion Rate
SELECT (SUM(A.user_duration)/SUM(A.content_duration))*100 AS Completion_RATE
FROM consumption_data AS A

--Ratings Data

SELECT 
AVG(CASE
    WHEN rating = 'TERRIBLE' THEN 1.00
	WHEN rating = 'BAD' THEN 2.00
	WHEN rating = 'GOOD' THEN 3.00
	ELSE 4.00
	END) AS Avg_Rating
FROM rating_data AS A
WHERE A.rating NOT IN ('NOT_RATED','DISMISSED')

--Catalogue Data
/*
 -- Total Content Duration
 -- % of Content split by Access Level
 -- % of Indian vs Foreign Content
 -- % of Content split by Status
 -- MOM Content added/Relegated to the platform

*/
-- Total Content Duration
SELECT sum(CAST(REPLACE(A.duration,'min','') AS int)) AS Total_Content_Duration
FROM catalogue_data AS A

-- % of Content split by Access Level

SELECT A.accesslevel,
(COUNT(A.content_id)*1.00/(SELECT COUNT(*) FROM catalogue_data WHERE status = 'LIVE'))*100 AS Content_PERC
FROM catalogue_data AS A
WHERE A.status = 'LIVE'
GROUP BY A.accesslevel

-- % of Content split by Status

SELECT A.status,
(COUNT(A.content_id)*1.00/(SELECT COUNT(*) FROM catalogue_data ))*100 AS Content_PERC
FROM catalogue_data AS A
GROUP BY A.status

 -- % of Indian vs Foreign Content
 SELECT 
 CASE WHEN country = 'INDIA' THEN 'Indian' ELSE 'Foreign' END AS Country_Type,
 (COUNT(A.content_id)*1.00/(SELECT COUNT(*) FROM catalogue_data ))*100 AS Content_PERC
 FROM catalogue_data AS A
 GROUP BY CASE WHEN country = 'INDIA' THEN 'Indian' ELSE 'Foreign' END


 -- MOM Content added/Relegated to the platform

 SELECT MONTH(A.date_added) AS Month_,
 COUNT(CASE WHEN status = 'LIVE' THEN 1 ELSE 0 END) AS Content_ADDED,
 SUM(CASE WHEN status = 'relegated' THEN 1 ELSE 0 END) AS Relegated_Content
 FROM catalogue_data AS A
 GROUP BY MONTH(A.date_added)
 ORDER BY Month_ ASC