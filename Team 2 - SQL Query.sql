-- TEAM TWO - PRODUCT AND VALUE ANALYSIS

USE cleaned_team_oreo;

-- Importing the dataset
SELECT * FROM cleaned_team_oreo LIMIT 2000;

-- Getting a list of the dataset dtype
DESCRIBE cleaned_team_oreo;

-- UPDATING THE COLUMNS DATA TYPE
-- For the IDs and Text columns
ALTER TABLE cleaned_team_oreo
MODIFY COLUMN Transaction_ID VARCHAR(20),
MODIFY COLUMN Order_ID VARCHAR(20),
MODIFY COLUMN Day_of_Week VARCHAR(10),
MODIFY COLUMN Customer_ID VARCHAR(20),
MODIFY COLUMN Customer_Segment VARCHAR(20),
MODIFY COLUMN Order_Channel VARCHAR(20),
MODIFY COLUMN Menu_Item VARCHAR(50),
MODIFY COLUMN Category VARCHAR(20),
MODIFY COLUMN Waste_Reason VARCHAR(100),
MODIFY COLUMN Complaint_Received VARCHAR(5),
MODIFY COLUMN Payment_Method VARCHAR(20),
MODIFY COLUMN Staff_ID VARCHAR(20);

-- For the Date and Time columns
SELECT
    Order_Date,
    Order_Time
FROM cleaned_team_oreo
LIMIT 10;

SET SQL_SAFE_UPDATES = 0;

ALTER TABLE cleaned_team_oreo
ADD COLUMN Order_Date_New DATE;

UPDATE cleaned_team_oreo
SET Order_Date_New = STR_TO_DATE(Order_Date, '%m/%d/%Y');

SELECT
	Order_Date,
	Order_Date_New
FROM cleaned_team_oreo;

SELECT COUNT(*) AS Invalid_Dates
FROM cleaned_team_oreo
WHERE Order_Date IS NOT NULL
  AND Order_Date_New IS NULL;
 
-- Dropping the og Order_Date column
ALTER TABLE cleaned_team_oreo
DROP COLUMN Order_Date;

-- Changing the Order_Date_New column to Order_Date
ALTER TABLE cleaned_team_oreo
CHANGE COLUMN Order_Date_New Order_Date DATE;

ALTER TABLE cleaned_team_oreo
ADD COLUMN Order_Time_New TIME;

-- Updating the Order_Time column
UPDATE cleaned_team_oreo
SET Order_Time_New = STR_TO_DATE(Order_Time, '%H:%i');

SELECT
    Order_Time,
    Order_Time_New
FROM cleaned_team_oreo
LIMIT 10;

SELECT COUNT(*) AS Invalid_Times
FROM cleaned_team_oreo
WHERE Order_Time IS NOT NULL
  AND Order_Time_New IS NULL;
  
-- Dropping and Replacing the og Order_Time
ALTER TABLE cleaned_team_oreo
DROP COLUMN Order_Time;

ALTER TABLE cleaned_team_oreo
CHANGE COLUMN Order_Time_New Order_Time TIME;

-- Updating the Financials columns
ALTER TABLE cleaned_team_oreo
MODIFY COLUMN Unit_Price_GBP DECIMAL(10,2),
MODIFY COLUMN Gross_Sales_GBP DECIMAL(10,2),
MODIFY COLUMN Discount_Percent DECIMAL(5,2),
MODIFY COLUMN Discount_Value_GBP DECIMAL(10,2),
MODIFY COLUMN Net_Sales_GBP DECIMAL(20,2),
MODIFY COLUMN Food_Cost_GBP DECIMAL(10,2),
MODIFY COLUMN Gross_Profit_GBP DECIMAL(20,2),
MODIFY COLUMN Waste_Cost_GBP DECIMAL(10,2);


-- Filling the NULL/missing values in the Customer_Rating column with its median/average
WITH ranked_ratings AS (
    SELECT
        CAST(TRIM(Customer_Rating) AS DECIMAL(2,1)) AS Rating,
        ROW_NUMBER() OVER (
            ORDER BY CAST(TRIM(Customer_Rating) AS DECIMAL(2,1))
        ) AS rn,
        COUNT(*) OVER () AS total_count
    FROM cleaned_team_oreo
    WHERE TRIM(Customer_Rating) <> ''
      AND Customer_Rating IS NOT NULL
)
SELECT AVG(Rating) AS Median_Rating
FROM ranked_ratings
WHERE rn IN (
    FLOOR((total_count + 1) / 2),
    CEIL((total_count + 1) / 2)
);

UPDATE cleaned_team_oreo
SET Customer_Rating = '4.0'
WHERE Customer_Rating IS NULL
   OR TRIM(Customer_Rating) = '';

-- Updating the Customer_Ratings column
SELECT
    Customer_Rating,
    COUNT(*) AS Frequency
FROM cleaned_team_oreo
GROUP BY Customer_Rating
ORDER BY Customer_Rating;

SELECT
    Customer_Rating
FROM cleaned_team_oreo
WHERE Customer_Rating IS NOT NULL
  AND TRIM(Customer_Rating) <> ''
  AND Customer_Rating NOT REGEXP '^[0-9]+(\.[0-9]+)?$';
  
ALTER TABLE cleaned_team_oreo
ADD COLUMN Customer_Rating_New DECIMAL(2,1);

UPDATE cleaned_team_oreo
SET Customer_Rating_New =
    CASE
        WHEN TRIM(Customer_Rating) = '' THEN NULL
        WHEN Customer_Rating REGEXP '^[0-9]+(\.[0-9]+)?$'
            THEN CAST(Customer_Rating AS DECIMAL(2,1))
        ELSE NULL
    END;
    
SELECT
    Customer_Rating,
    Customer_Rating_New
FROM cleaned_team_oreo
LIMIT 20;

-- Checking for failed Conversions
SELECT COUNT(*) AS Conversion_Failures
FROM cleaned_team_oreo
WHERE Customer_Rating IS NOT NULL
  AND TRIM(Customer_Rating) <> ''
  AND Customer_Rating_New IS NULL;
  
-- Checking for Customer Ratings less than 1 or greater than 5
SELECT
    Customer_Rating,
    Customer_Rating_New
FROM cleaned_team_oreo
WHERE Customer_Rating_New < 1
   OR Customer_Rating_New > 5;
   
-- Now Updating the Customer_Rating column
ALTER TABLE cleaned_team_oreo
DROP COLUMN Customer_Rating;

ALTER TABLE cleaned_team_oreo
CHANGE COLUMN Customer_Rating_New Customer_Rating DECIMAL(2,1);

DESCRIBE cleaned_team_oreo;


-- NOW TO ANSWER THE BUSINESS QUESTIONS

-- 1.  Top Revenue Products - Taiwo Elizabeth Omobolanle
-- Calculating the Total Revenue.
SELECT SUM(Net_Sales_GBP) AS Total_Revenue_GBP
FROM cleaned_team_oreo;

-- Ranking Menu item by Units sold and Revenue.
SELECT 
	Menu_Item, SUM(Quantity) AS Units_Sold,
    SUM(Net_Sales_GBP) AS Revenue_GBP 
FROM cleaned_team_oreo
GROUP BY Menu_Item;

-- Products with high volume of Units sold.
SELECT 
	Menu_Item, 
	SUM(Quantity) AS Units_Sold
FROM cleaned_team_oreo
GROUP BY Menu_Item
ORDER BY Units_Sold DESC
LIMIT 7;


-- Products that generates high Revenue.
SELECT

	Menu_Item,
    SUM(Net_Sales_GBP) AS Revenue_GBP
FROM cleaned_team_oreo
GROUP BY Menu_Item
ORDER BY Revenue_GBP DESC
LIMIT 5;

-- Products with high volume of Units sold but generate low Revenue.
SELECT 
	Menu_Item, 
    SUM(Quantity) AS Units_sold, 
    SUM(Net_Sales_GBP) AS Revenue_GBP
FROM cleaned_team_oreo
GROUP BY Menu_Item
HAVING SUM(Net_Sales_GBP)<1500 AND SUM(Quantity)>150;

-- 2. Poor value products with regards to Food cost and its respective Waste cost - Egbo Emmanuel
SELECT
    Menu_Item,
    ROUND(SUM(Food_Cost_GBP), 2) AS Food_Cost_GBP,
    ROUND(SUM(Waste_Cost_GBP), 2) AS Waste_Cost_GBP,
    ROUND(
        (SUM(Waste_Cost_GBP) / NULLIF(SUM(Food_Cost_GBP), 0)) * 100,
        2
    ) AS Waste_Share_of_Food_Cost_Pct,
    ROUND(SUM(Net_Sales_GBP), 2) AS Revenue_GBP,
    ROUND(SUM(Gross_Profit_GBP), 2) AS Gross_Profit_GBP,

    CASE
        WHEN
            (SUM(Waste_Cost_GBP) /
            NULLIF(SUM(Food_Cost_GBP), 0)) * 100 >= 10
        THEN 'High Waste Burden'
        ELSE 'Lower Waste Burden'
    END AS Waste_Flag

FROM cleaned_team_oreo
GROUP BY Menu_Item
ORDER BY Waste_Share_of_Food_Cost_Pct DESC;

-- 3. Products to Investigate - Osifuye	Eniola
SELECT
    Menu_Item,
    COUNT(*) AS Total_Transactions,

    SUM(
        CASE
            WHEN Complaint_Received = 'Yes' THEN 1
            ELSE 0
        END
    ) AS Complaints,
    ROUND(
        SUM(
            CASE
                WHEN Complaint_Received = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS Complaint_Rate_Pct,

    ROUND(AVG(Customer_Rating), 2) AS Average_Rating,
    ROUND(SUM(Waste_Cost_GBP), 2) AS Waste_Cost_GBP,

    CASE
        WHEN
            (
                SUM(
                    CASE
                        WHEN Complaint_Received = 'Yes' THEN 1
                        ELSE 0
                    END
                ) / COUNT(*) * 100
            ) >= 5
            AND AVG(Customer_Rating) >= 4
            AND SUM(Waste_Cost_GBP) = 0
        THEN 'Investigate - High Complaints Despite Good Rating and No Waste'
        WHEN
            (
                SUM(
                    CASE
                        WHEN Complaint_Received = 'Yes' THEN 1
                        ELSE 0
                    END
                ) / COUNT(*) * 100
            ) >= 5
        THEN 'Investigate - High Complaint Rate'
        ELSE 'Lower Complaint Concern'
    END AS Investigation_Flag
FROM cleaned_team_oreo
GROUP BY Menu_Item
ORDER BY Complaint_Rate_Pct DESC;