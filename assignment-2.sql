/* ASSIGNMENT 2 */
--Please write responses between the QUERY # and END QUERY blocks
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product


But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with
nulls, and 'unit' for the second column with nulls. 

**HINT**: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same. */
--QUERY 1
SELECT
product_name,
product_size,
product_qty_type
from product;
SELECT
product_name
,coalesce (product_size,"") as product_size
,coalesce (product_qty_type, 'unit') as product_qty_type
from product;

--END QUERY


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). 
Filter the visits to dates before April 29, 2022. */
--QUERY 2
select customer_id, market_date, 
dense_rank() OVER (PARTITION BY customer_id ORDER BY market_date) as visit_number
from customer_purchases	
where market_date < '2022-04-29';



--END QUERY


/* 2. Reverse the numbering of the query so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit.
HINT: Do not use the previous visit dates filter. */
--QUERY 3
select 
customer_id, 
market_date, 
dense_rank() OVER (PARTITION BY customer_id ORDER BY market_date DESC) as visit_number
from customer_purchases;


SELECT 
customer_id,
market_date,
visit_number
FROM
(SELECT *,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS visit_number
FROM customer_purchases
) AS visits
WHERE visit_number = 1;



--END QUERY


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. 

You can make this a running count by including an ORDER BY within the PARTITION BY if desired.
Filter the visits to dates before April 29, 2022. */
--QUERY 4
Select
customer_id,
product_id, 
market_date,
count(*) over (partition by customer_id, product_id order by market_date) as purchase_count
from customer_purchases
where market_date < '2022-04-29';

--END QUERY


-- String manipulations

/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
--QUERY 5																
SELECT
    product_name,
    NULLIF
	(TRIM
		(SUBSTR(product_name,INSTR(product_name, '-') + 1)),
        
        TRIM(product_name)
    ) AS Description
FROM product;
      

--END QUERY


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
--QUERY 6
SELECT
product_size
from product
where product_size REGEXP '[0-9]';



--END QUERY


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
--QUERY 7
1. 
CREATE TEMP TABLE daily_sales AS
SELECT
market_date 
,SUM(quantity*cost_per_quantity) as sales
FROM customer_purchases
Group by market_date
2. 
SELECT *
FROM daily_sales
ORDER BY sales DESC;

3. CREATE TEMP TABLE daily_best_sales AS
SELECT
market_date 
,SUM(quantity*cost_per_quantity) as sales
FROM customer_purchases
Group by market_date
order by sales desc;

3. CREATE TEMP TABLE daily_worst_sales AS
SELECT
market_date 
,SUM(quantity*cost_per_quantity) as sales
FROM customer_purchases
Group by market_date
order by sales ASC;

4. Select*
FROM
(SELECT *
FROM daily_best_sales
LIMIT 1)
UNION
select*
FROM
(SELECT *
FROM daily_worst_sales
LIMIT 1);

--END QUERY

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
--QUERY 8

SELECT
    vendor_products.vendor_name,
    vendor_products.product_name,
    SUM(vendor_products.five_per_customer) AS total_sales_potential_5products_per_customer
FROM 
(
    SELECT DISTINCT
        vendor.vendor_name,
        product.product_name,
        vendor_inventory.original_price,
        vendor_inventory.original_price * 5 AS five_per_customer
    FROM vendor_inventory
    JOIN vendor
        ON vendor_inventory.vendor_id = vendor.vendor_id
    JOIN product
        ON vendor_inventory.product_id = product.product_id
) AS vendor_products

CROSS JOIN customer
GROUP BY
    vendor_products.vendor_name,
    vendor_products.product_name;

--END QUERY


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

--QUERY 9
CREATE TABLE product_units AS
SELECT *
FROM product
where product_qty_type = 'unit';

ALTER table product_units 
add COLUMN `snapshot___timestamp` CURRENT_TIMESTAMP;

--END QUERY


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

--QUERY 10
INSERT into product_units
 (product_id, product_name, product_size, product_category_id, product_qty_type, snapshot___timestamp)
values (99, 'sweet corn', '12 dozen', '33', 'unit', CURRENT_TIMESTAMP);


--END QUERY


-- DELETE
/* 1. Delete the older record for whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

--QUERY 11
DELETE FROM product_units
WHERE product_id = 99;



--END QUERY


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

--QUERY 12
1. 
alter table product_units
add current_quantity INT;		

2. 
SELECT
product_id
,quantity
,market_date
,row_number() over (partition by product_id order by market_date desc) as row_num
from vendor_inventory;	


3. 
--i did temp tables first as it iwas easier to visualize the data.

CREATE TEMP TABLE ranked_inventory AS
SELECT
    product_id,
    quantity,
    market_date,
    ROW_NUMBER() OVER (
        PARTITION BY product_id
        ORDER BY market_date DESC
    ) AS row_num
FROM vendor_inventory;

CREATE TEMP TABLE latest__inventory AS
SELECT
    product_id,
    quantity,
    market_date
FROM ranked_inventory
WHERE row_num = 1;

SELECT
    product_units.product_id,
    product_units.product_name,
    COALESCE(latest__inventory.quantity, 0) AS quantity,
    latest__inventory.market_date
FROM product_units

LEFT JOIN latest__inventory
    ON product_units.product_id = latest__inventory.product_id;



4. update the quantity in product units 

UPDATE product_units
SET current_quantity = COALESCE(
    (
SELECT latest__inventory.quantity
FROM latest__inventory
WHERE latest__inventory.product_id = product_units.product_id
    ),0);


--END QUERY



