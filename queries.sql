-- Tyler Petrow
-- D326 - Advanced Data Management
--Part B. Provide original code for function(s) in text format that perform the transformation(s) you identified in part A4
--create function to transform id into category name
CREATE OR REPLACE FUNCTION category_conversion(categoryNum INTEGER)
RETURNS VARCHAR(25)
LANGUAGE plpgsql
AS
$$
DECLARE category_name VARCHAR(25);
BEGIN
SELECT name
FROM category
WHERE category_id = categoryNum
INTO category_name;
RETURN category_name;
END;
$$
--test category_conversion function
SELECT category_conversion(14); --returns Sci-Fi
            
--Part C. Provide original SQL code in a text format that creates the detailed and summary tables to hold your report table sections
CREATE TABLE inventory_detail (
      film_id INTEGER,
      film_title VARCHAR(255),
      category_id INTEGER,
      inventory_count INTEGER,
      PRIMARY KEY(film_id, category_id),
      FOREIGN KEY(film_id) REFERENCES film(film_id)
);
            
CREATE TABLE inventory_summary (
      category_name VARCHAR(25),
      inventory_count INTEGER,
      title_count INTEGER
);
            
--Part D. Provide an original SQL query in a text format that will extract the raw data needed for the detailed section of your report from the source database.        
INSERT INTO inventory_detail (film_id, film_title, category_id, inventory_count)
SELECT f.film_id, f.title AS film_title, fc.category_id,
            COUNT(i.inventory_id) AS inventory_count
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
LEFT JOIN inventory i ON f.film_id = i.film_id
GROUP BY f.film_id, fc.category_id
ORDER BY fc.category_id DESC;

--Part E. Provide original SQL code in a text format that creates a trigger on the detailed table of the report that will continually update the summary table as data is added to the detailed table.
CREATE OR REPLACE FUNCTION trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
DELETE FROM inventory_summary;
INSERT INTO inventory_summary (category_name, inventory_count, title_count)
SELECT category_conversion(category_id) AS category_name,
      SUM(inventory_count) AS inventory_count,
      COUNT(DISTINCT film_id) AS title_count
FROM inventory_detail
GROUP BY category_name
ORDER BY inventory_count DESC;
RETURN NEW;
END;
$$
                
CREATE TRIGGER new_summary
      AFTER INSERT
      ON inventory_detail
      FOR EACH STATEMENT
      EXECUTE PROCEDURE trigger_function();
      
--Part F. Provide an original stored procedure in a text format that can be used to refresh the data in both the detailed table and summary table. The procedure should clear the contents of the detailed table and summary table and perform the raw data extraction from part D.
CREATE OR REPLACE PROCEDURE refresh_tables()
LANGUAGE plpgsql
AS
$$
BEGIN
DELETE FROM inventory_detail;
INSERT INTO inventory_detail (film_id, film_title, category_id, inventory_count)
SELECT f.film_id, f.title AS film_title, fc.category_id,
COUNT(i.inventory_id) AS inventory_count
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
LEFT JOIN inventory i ON f.film_id = i.film_id
GROUP BY f.film_id, fc.category_id
ORDER BY fc.category_id DESC;
--inventory_summary table will automatically update due to insert activating the trigger
END;
$$
                  
CALL refresh_tables();

--Statements used repeatedly for testing
DROP TABLE inventory_summary;
DROP TABLE inventory_detail;

DELETE FROM inventory_summary;
DELETE FROM inventory_detail;

SELECT * FROM inventory_summary;                
SELECT * FROM inventory_detail;
