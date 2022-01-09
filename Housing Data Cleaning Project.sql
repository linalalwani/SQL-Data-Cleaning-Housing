/*
Housing Data Cleaning

Created by Lina Lalwani

Date: 1/8/2021

Description: Thorough cleaning of raw data into new format

*/

SELECT 
    SaleDate
FROM
    housing.rawdata;

-- CLEANING DATE FORMATTING

SELECT 
    SaleDate,
    DATE_FORMAT(STR_TO_DATE(SaleDate, '%M %d, %Y'),
            '%Y-%m-%d')
FROM
    housing.rawdata;

-- Created new column and inputted string here
-- Note: date format must follow 'YYYY-MM-DD' exactly to fit Date format
ALTER TABLE housing.rawdata
ADD SaleDateConverted Date;

UPDATE housing.rawdata 
SET 
    SaleDateConverted = DATE_FORMAT(STR_TO_DATE(SaleDate, '%M %d, %Y'),
            '%Y-%m-%d');



-- POPULATE NULL PROPERTY ADDRESS DATA USING DATA FROM ANOTHER COLUMN
-- For mysql, isnull is ifnull

SELECT 
    a.ParcelID,
    b.ParcelID,
    a.PropertyAddress,
    b.PropertyAddress,
    IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM
    housing.rawdata AS a
        JOIN
    housing.rawdata AS b ON a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID
WHERE
    a.PropertyAddress IS NULL;


-- Need to use alias for join in the update clause

UPDATE housing.rawdata AS a
        JOIN
    housing.rawdata AS b ON a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID 
SET 
    a.PropertyAddress = b.PropertyAddress
WHERE
    a.PropertyAddress IS NULL;

-- double check, make sure number is zero!
SELECT 
    COUNT(PropertyAddress)
FROM
    housing.rawdata
WHERE
    PropertyAddress IS NULL;


-- BREAKING DOWN PREPERTY ADDRESS

SELECT 
    PropertyAddress, LOCATE(',', PropertyAddress)
FROM
    housing.rawdata;


-- To get the street address
SELECT 
    SUBSTRING(PropertyAddress,
        1,
        LOCATE(',', PropertyAddress)) AS street_address
FROM
    housing.rawdata;


-- To get address minus the comma
SELECT 
    SUBSTRING(PropertyAddress,
        1,
        LOCATE(',', PropertyAddress) - 1) AS street_address
FROM
    housing.rawdata;

-- Now, get city from comma onwards
-- The first one will clean any spaces as it will just grab the string value

SELECT 
    SUBSTRING(PropertyAddress,
        LOCATE(',', PropertyAddress) + 2,
        CHAR_LENGTH(PropertyAddress)) AS city
FROM
    housing.rawdata;

-- SELECT substring(PropertyAddress, LOCATE(",", PropertyAddress)+2, LOCATE(",", PropertyAddress) ) as street_address
-- FROM housing.rawdata;



-- Update table with Property street address and city columns

ALTER TABLE housing.rawdata
ADD PropertyStreetAddress text;

UPDATE housing.rawdata 
SET 
    StreetAddress = substring(PropertyAddress, 1, LOCATE(",", PropertyAddress)-1 );
    
SELECT PropertyStreetAddress from housing.rawdata;


-- Now adding City Column 

ALTER TABLE housing.rawdata
ADD PropertyCity text;

UPDATE housing.rawdata 
SET 
    PropertyCity = SUBSTRING(PropertyAddress,
        LOCATE(',', PropertyAddress) + 2,
        CHAR_LENGTH(PropertyAddress));
    
SELECT 
    PropertyCity
FROM
    housing.rawdata;

-- Now, cleaning owner address

SELECT 
    OwnerAddress
FROM
    housing.rawdata;


-- Get State
SELECT 
    SUBSTRING_INDEX(OwnerAddress, ',', - 1)
FROM
    housing.rawdata;

-- Get Street Address
SELECT 
    SUBSTRING_INDEX(OwnerAddress, ',', 1)
FROM
    housing.rawdata;

-- Trickiest One, Call Substring Index TWICE to Grab City

SELECT 
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2),
            ',',
            - 1) AS City
FROM
    housing.rawdata;


-- Now, update the info for Owner Address

-- Update table with street address and city columns

ALTER TABLE housing.rawdata
ADD OwnerStreetAddress text;

UPDATE housing.rawdata 
SET 
    OwnerStreetAddress = SUBSTRING(PropertyAddress,
        1,
        LOCATE(',', PropertyAddress) - 1);
    
SELECT 
    OwnerStreetAddress
FROM
    housing.rawdata;


-- Now adding City Column 

ALTER TABLE housing.rawdata
ADD OwnerCity text;

UPDATE housing.rawdata 
SET 
    OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2),
            ',',
            - 1);
    
SELECT 
    OwnerCity
FROM
    housing.rawdata;

-- Finally Add State Column

ALTER TABLE housing.rawdata
ADD OwnerState text;

UPDATE housing.rawdata 
SET 
    OwnerState = SUBSTRING_INDEX(OwnerAddress, ',', - 1);


-- CHANGE Y AND N TO YES AND NO IN SOLD AS VACANT FIELD

SELECT DISTINCT
    (SoldAsVacant), COUNT(SoldAsVacant)
FROM
    housing.rawdata
GROUP BY SoldAsVacant
ORDER BY 2;


SELECT DISTINCT
    (SoldAsVacant),
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END
FROM
    housing.rawdata;


-- Update column

UPDATE housing.rawdata 
SET 
    SoldAsVacant = CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END;


-- Double check to make sure it went through
SELECT DISTINCT
    (SoldAsVacant), COUNT(SoldAsVacant)
FROM
    housing.rawdata
GROUP BY SoldAsVacant
ORDER BY 2;


-- REMOVE DUPLICATES
-- Noting this should not be common practice to remove from actual data

With RowNumCTE 
AS (
Select *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
ORDER BY UniqueID) AS row_num
From housing.rawdata
)
Select *
FROM RowNumCTE
WHERE row_num > 1;

With RowNumCTE 
AS (
Select *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
ORDER BY UniqueID) AS row_num
From housing.rawdata
)
DELETE housing.rawdata
FROM RowNumCTE
JOIN housing.rawdata USING(UniqueID)
WHERE row_num > 1;


-- REMOVE COLUMNS
-- Creating another clean dataset to complete this process

CREATE TABLE housing.cleandata SELECT * FROM
    housing.rawdata;

SELECT 
    *
FROM
    housing.cleandata;

ALTER TABLE housing.cleandata
DROP COLUMN OwnerAddress, DROP COLUMN TaxDistrict, DROP COLUMN PropertyAddress;





