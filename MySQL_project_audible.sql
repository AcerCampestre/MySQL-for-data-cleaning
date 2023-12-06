-- CLEANING DATA USING SQL
-- The last query of this file shows final table with data prepared to analysis/visualisation

-- Source of the dataset: https://www.kaggle.com/datasets/snehangsude/audible-dataset/

CREATE TABLE dataset (
	name varchar(255),
    author varchar(255),
    narrator varchar(255),
    release_date varchar(20),
    `language` varchar(20),
    stars varchar(255),
    priceUSD varchar(255)
);
ALTER TABLE dataset
ADD `time` varchar(30);

ALTER TABLE dataset RENAME COLUMN release_date TO releasedate;
ALTER TABLE dataset RENAME COLUMN author TO uncleanedAuthor;

-- Adding ID column to the table
ALTER TABLE dataset ADD id INT UNSIGNED NOT NULL AUTO_INCREMENT,
ADD INDEX (id);

-- Setting ID column as a first column
ALTER TABLE dataset
	CHANGE id id INT(11) NOT NULL FIRST;

-- Removing 'Writtenby:' in author column
ALTER TABLE dataset
ADD COLUMN author VARCHAR(200);

SET SQL_SAFE_UPDATES = 0;

UPDATE dataset t
INNER JOIN (SELECT id, substring(uncleanedAuthor, 11) AS author
FROM dataset) AS t1 
SET t.author=t1.author 
WHERE t.id=t1.id;

-- Cleaning narrator column
ALTER TABLE dataset
ADD COLUMN NarratedBy VARCHAR(200);

UPDATE dataset t
INNER JOIN (SELECT id, SUBSTRING_INDEX(narrator,':',-1) AS NarratedBy 
FROM dataset) AS t1 
SET t.NarratedBy=t1.NarratedBy 
WHERE t.id=t1.id;

-- Separting distintct narrators from NarratedBy column into individual columns 
-- First one
ALTER TABLE dataset
ADD COLUMN FirstNarrator VARCHAR(200);

UPDATE dataset t
INNER JOIN (SELECT id, substring_index(substring_index(NarratedBy, ',', 1), ',', -1) AS FirstNarrator 
FROM dataset) AS t1 
SET t.FirstNarrator=t1.FirstNarrator 
WHERE t.id=t1.id;

-- Second narrator
ALTER TABLE dataset
ADD COLUMN SecondNarrator VARCHAR(200);

UPDATE dataset t
INNER JOIN (SELECT id, substring_index(substring_index(NarratedBy, ',', 2), ',', -1) AS SecondNarrator 
FROM dataset) AS t1 
SET t.SecondNarrator=t1.SecondNarrator 
WHERE t.id=t1.id;

-- Third narrator
ALTER TABLE dataset
ADD COLUMN ThirdNarrator VARCHAR(200);

UPDATE dataset t
INNER JOIN (SELECT id, substring_index(substring_index(NarratedBy, ',', 3), ',', -1) AS ThirdNarrator 
FROM dataset) AS t1 
SET t.ThirdNarrator=t1.ThirdNarrator 
WHERE t.id=t1.id;

-- Inserting NULL if there is no second narrator
UPDATE dataset
SET SecondNarrator =
(SELECT 
CASE WHEN FirstNarrator = SecondNarrator THEN null
ELSE SecondNarrator
END AS SecondNarrator
);

-- Inserting NULL if there is no third narrator
UPDATE dataset
SET ThirdNarrator =
(SELECT 
CASE WHEN SecondNarrator =  ThirdNarrator THEN null
WHEN SecondNarrator IS NULL THEN NULL
ELSE ThirdNarrator
END AS ThirdNarrator
);

-- releasedate column
-- Converting release date to date format
SELECT STR_TO_DATE(releasedate,'%d-%m-%Y') as Date
FROM dataset;

-- Let's add this to table
ALTER TABLE dataset
ADD COLUMN DateReleased varchar(20);

UPDATE dataset t
INNER JOIN (SELECT id, STR_TO_DATE(releasedate,'%d-%m-%Y') as DateReleased
FROM dataset) AS t1 
SET t.DateReleased=t1.DateReleased 
WHERE t.id=t1.id;

-- stars column
-- getting rating from stars columns
ALTER TABLE dataset
ADD COLUMN rating VARCHAR(5);

UPDATE dataset t
INNER JOIN (SELECT id, SUBSTRING_INDEX(stars,' ', 1) AS rating 
FROM dataset) AS t1 
SET t.rating=t1.rating 
WHERE t.id=t1.id;

-- getting number of votes from stars columns
ALTER TABLE dataset
ADD COLUMN votes VARCHAR(20);

-- extracting value between s and space as votes
UPDATE dataset t
INNER JOIN (SELECT id, substring_index(substring_index(stars, 's', -2), ' ', 1) AS votes 
FROM dataset) AS t1 
SET t.votes=t1.votes 
WHERE t.id=t1.id;

-- removing '.00' from priceUSD column 
SELECT TRIM(TRAILING '.00' FROM priceUSD) AS priceUSD
FROM dataset;

-- Or maybe the better and quicker way is to simply change the data type
ALTER TABLE dataset
MODIFY priceUSD INT;

-- Check the data type
SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'dataset' AND COLUMN_NAME = 'priceUSD';
  
-- time column 
-- separating hours and minutes from time column
ALTER TABLE dataset
ADD COLUMN hours INT,
ADD COLUMN minutes int;

-- hours
UPDATE dataset t
INNER JOIN (SELECT id, substring_index(substring_index(time, ' h', 1 ), ' ', 1) AS hours 
FROM dataset) AS t1 
SET t.hours=t1.hours 
WHERE t.id=t1.id;

-- minutes
UPDATE dataset t
INNER JOIN (SELECT id, substring_index(substring_index(time, ' ', -2), ' ', 1) AS minutes 
FROM dataset) AS t1 
SET t.minutes=t1.minutes 
WHERE t.id=t1.id;

-- Combining hours and minutes into one column called length [minutes]
ALTER TABLE dataset 
ADD COLUMN length INT;
UPDATE dataset
SET length= minutes + hours*60;

-- changing data type of rating and votes column as they are varchars instead of float/integer
ALTER TABLE dataset
MODIFY rating FLOAT;
-- Gives an error at row 35 as there is 'Not' string. When changing the data type of votes column it 
-- would give the same error as there is also a phrase 'Not'

-- rating column
UPDATE dataset
SET rating =
(SELECT 
CASE WHEN rating =  'Not' THEN null
ELSE rating
END
);

-- votes column
UPDATE dataset
SET votes =
(SELECT 
CASE WHEN votes =  'Not' THEN null
ELSE votes
END
);

-- converting to proper data types
ALTER TABLE dataset
MODIFY rating FLOAT,
MODIFY votes INT;

ALTER TABLE dataset
MODIFY DateReleased DATE;

-- TABLE WITH FINAL, CLEANED DATA
CREATE TABLE final_table AS SELECT id, name, author, FirstNarrator, SecondNarrator, ThirdNarrator, DateReleased, priceUSD, rating, votes, length, language FROM dataset;

SELECT * FROM final_table;
