--1)
ALTER TABLE SALES_DATASET_RFM_PRJ
ALTER COLUMN ordernumber TYPE numeric USING (trim(ordernumber)::numeric),
ALTER COLUMN priceeach TYPE numeric USING (trim(priceeach)::numeric),
ALTER COLUMN quantityordered TYPE numeric USING (trim(quantityordered)::numeric),
ALTER COLUMN orderlinenumber TYPE numeric USING (trim(orderlinenumber)::numeric),
ALTER COLUMN sales TYPE numeric USING (trim(sales)::numeric),
ALTER COLUMN orderdate TYPE date USING (orderdate::date), 
ALTER COLUMN status TYPE text,
ALTER COLUMN productline TYPE text,
ALTER COLUMN msrp TYPE numeric USING (trim(msrp)::numeric),
ALTER COLUMN customername TYPE text,
ALTER COLUMN phone TYPE numeric USING (trim(msrp)::numeric),
ALTER COLUMN productcode TYPE VARCHAR

--2)
select *from SALES_DATASET_RFM_PRJ
WHERE ordernumber IS NULL

select *from SALES_DATASET_RFM_PRJ
WHERE QUANTITYORDERED IS NULL

select *from SALES_DATASET_RFM_PRJ
WHERE PRICEEACH IS NULL

select *from SALES_DATASET_RFM_PRJ
WHERE orderlinenumber IS NULL

select *from SALES_DATASET_RFM_PRJ
WHERE SALES IS NULL

select *from SALES_DATASET_RFM_PRJ
WHERE ORDERDATE IS NULL

--3)
/*Thêm cột CONTACTLASTNAME, CONTACTFIRSTNAME được tách ra từ CONTACTFULLNAME . 
Chuẩn hóa CONTACTLASTNAME, CONTACTFIRSTNAME theo định dạng chữ cái đầu tiên viết hoa, chữ cái tiếp theo viết thường. 
Gợi ý: ( ADD column sau đó UPDATE)*/

SELECT *FROM sales_dataset_rfm_prj

ALTER TABLE sales_dataset_rfm_prj
ADD column contactlastname VARCHAR(20),
ADD column contactfirstname VARCHAR(20);

select email,
position('@' in email)
from customer;

UPDATE sales_dataset_rfm_prj
SET 
    contactlastname = LEFT(contactfullname, POSITION('-' IN contactfullname) - 1),
    contactfirstname = RIGHT(contactfullname, LENGTH(contactfullname) - POSITION('-' IN contactfullname));

UPDATE sales_dataset_rfm_prj
SET
 contactlastname = UPPER(LEFT(contactlastname, 1))  || LOWER(SUBSTRING(contactlastname FROM 2)),
 contactfirstname = UPPER(LEFT(contactfirstname, 1))  || LOWER(SUBSTRING(contactfirstname FROM 2))

--4)
/*Thêm cột QTR_ID, MONTH_ID, YEAR_ID lần lượt là Qúy, tháng, năm được lấy ra từ ORDERDATE */

ALTER TABLE sales_dataset_rfm_prj
ADD column QTR_ID NUMERIC,
ADD column MONTH_ID NUMERIC, 
ADD column YEAR_ID NUMERIC;

UPDATE sales_dataset_rfm_prj 
SET QTR_ID = EXTRACT (month from orderdate)
SELECT orderdate from sales_dataset_rfm_prj;
	
UPDATE sales_dataset_rfm_prj 
SET YEAR_ID = EXTRACT (year from orderdate);

UPDATE sales_dataset_rfm_prj 
SET QTR_ID = 
CASE 
WHEN EXTRACT(MONTH from orderdate) in (1,2,3) then 1
WHEN EXTRACT(MONTH from orderdate) in (4,5,6) then 2
WHEN EXTRACT(MONTH from orderdate) in (7,8,9) then 3
WHEN EXTRACT(MONTH from orderdate) in (10,11,12) then 4
END;

--5)
C1:
--- Using IQR/ BOX PLOT to find outliner 'QUANTITYORDERED'
---B1: Calculate Q1, Q3, IQR
---B2: Calculate min = Q1 - 1.5*IQR; MAX= Q3 +1.5*IQR
WITH CTE1 as 
(SELECT Q1 - 1.5*IQR AS min_value, Q3 + 1.5*IQR AS max_value
from(
SELECT 
percentile_cont(0.25) WITHIN GROUP (ORDER BY QUANTITYORDERED) as Q1,
percentile_cont(0.75) WITHIN GROUP (ORDER BY QUANTITYORDERED) as Q3,
percentile_cont(0.75) WITHIN GROUP (ORDER BY QUANTITYORDERED)- percentile_cont(0.25) WITHIN GROUP (ORDER BY QUANTITYORDERED) AS IQR
from sales_dataset_rfm_prj) as a)

--b3: Identify outliner <min or >max

SELECT *FROM sales_dataset_rfm_prj
WHERE QUANTITYORDERED < (SELECT min_value from CTE1)
OR QUANTITYORDERED > (SELECT max_value from CTE1)

C2:
SELECT avg(QUANTITYORDERED),
stddev(QUANTITYORDERED)
from sales_dataset_rfm_prj;

WITH CTE as
(
SELECT 
QUANTITYORDERED, 
(SELECT avg(QUANTITYORDERED)
from sales_dataset_rfm_prj) as avg,
(select stddev(QUANTITYORDERED)
from sales_dataset_rfm_prj) as stddev
from sales_dataset_rfm_prj)
, TWT_outliner as
(SELECT 
QUANTITYORDERED,
(QUANTITYORDERED - avg)/ stddev as z_score
from cte
where abs((QUANTITYORDERED - avg)/ stddev)>3)

--cách xử lý giá trị ngoại lai: loại bỏ/ thay thế bằng 1 giá trị mới 
UPDATE sales_dataset_rfm_prj
SET QUANTITYORDERED=(SELECT avg(QUANTITYORDERED)
from sales_dataset_rfm_prj)
WHERE QUANTITYORDERED IN (SELECT QUANTITYORDERED from TWT_outliner)


