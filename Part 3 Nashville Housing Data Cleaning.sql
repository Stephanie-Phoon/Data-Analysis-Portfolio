/* 
Data Cleaning with Nashville Housing Data 
*/

SELECT * 
FROM NashvilleHousingDataFormatted;

-- Step 1: Standardise Data Format 

-- note the the SaleDate type is TEXT 

SELECT SaleDate, date(SaleDate)
FROM NashvilleHousingDataFormatted

-- Add a column and update the table 
ALTER TABLE NashvilleHousingDataFormatted
ADD COLUMN SaleDateConverted date;
UPDATE NashvilleHousingDataFormatted
SET SaleDateConverted = date(SaleDate) 



-- Step 2 : Populate Property Address 
-- Note that  PropertyAddress got NULL values;

SELECT * 
FROM NashvilleHousingDataFormatted
WHERE PropertyAddress is NULL 

-- Note that ParcelID is related to PropertyAddress, we might impute by joining 
SELECT * 
FROM NashvilleHousingDataFormatted
ORDER by ParcelID

SELECT a.ParcelID, 
	   a.PropertyAddress, 
	   b.ParcelID, 
	   b.PropertyAddress, 
	   COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousingDataFormatted a
JOIN NashvilleHousingDataFormatted b 
	 on a.ParcelID = b.ParcelID
	 and a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL

-- Update the existing data 
UPDATE NashvilleHousingDataFormatted
SET PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousingDataFormatted a
JOIN NashvilleHousingDataFormatted b 
	 on a.ParcelID = b.ParcelID
	 and a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL




-- Step 3: Breaking out Address into Individual Column (Address, City) 
SELECT PropertyAddress
FROM NashvilleHousingDataFormatted


SELECT 
    substr(PropertyAddress, 1, instr(PropertyAddress, ',') - 1) AS Address,
	substr(PropertyAddress, instr(PropertyAddress, ',') + 1) AS City 
FROM 
    NashvilleHousingDataFormatted;

	
ALTER table NashvilleHousingDataFormatted
ADD PropertySplitAddress Nvarchar(255);
UPDATE NashvilleHousingDataFormatted
SET PropertySplitAddress = substr(PropertyAddress, 1, instr(PropertyAddress, ',') - 1)

ALTER table NashvilleHousingDataFormatted
ADD PropertySplitCity Nvarchar(255);
UPDATE NashvilleHousingDataFormatted
SET PropertySplitCity = substr(PropertyAddress, instr(PropertyAddress, ',') + 1)

SELECT * 
FROM NashvilleHousingDataFormatted





-- Step 5: OwnerAddress with Address, City, and State 

SELECT OwnerAddress
FROM NashvilleHousingDataFormatted

SELECT 
    TRIM(SUBSTR(OwnerAddress, 1, INSTR(OwnerAddress, ',') - 1)) AS Address,
    TRIM(SUBSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress, ',') + 1), 1, INSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress, ',') + 1), ',') - 1)) AS City,
    TRIM(SUBSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress, ',') + 1), INSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress, ',') + 1), ',') + 1)) AS State
FROM 
    NashvilleHousingDataFormatted;

ALTER table NashvilleHousingDataFormatted
ADD OwnerSplitAddress Nvarchar(255);
UPDATE NashvilleHousingDataFormatted
SET OwnerSplitAddress = TRIM(SUBSTR(OwnerAddress, 1, INSTR(OwnerAddress, ',') - 1))

ALTER table NashvilleHousingDataFormatted
ADD OwnerSplitCity2 Nvarchar(255);
UPDATE NashvilleHousingDataFormatted
SET OwnerSplitCity2 =  TRIM(SUBSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress, ',') + 1), 1, INSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress, ',') + 1), ',') - 1))

ALTER table NashvilleHousingDataFormatted
ADD OwnerSplitState Nvarchar(255);
UPDATE NashvilleHousingDataFormatted
SET OwnerSplitState = TRIM(SUBSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress, ',') + 1), INSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress, ',') + 1), ',') + 1))

SELECT * 
FROM NashvilleHousingDataFormatted


-- Step 6: Change Y and N to Yes and No in 'SoldAsVacant' field

SELECT DISTINCT(SoldAsVacant), count(SoldAsVacant)
FROM NashvilleHousingDataFormatted
GROUP by SoldAsVacant
ORDER by 2

SELECT SoldAsVacant, 
	CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant 
	END
FROM NashvilleHousingDataFormatted

UPDATE NashvilleHousingDataFormatted
SET SoldAsVacant = CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant 
	END
	

-- Step 7: Remove Duplicates 
-- use row_number to identify any duplicate value by examining the row_num
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                         PropertyAddress,
                         SalePrice,
                         SaleDate,
                         LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM NashvilleHousingDataFormatted
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- Delete the duplicate values 
DELETE FROM NashvilleHousingDataFormatted
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT UniqueID,
               ROW_NUMBER() OVER (
                   PARTITION BY ParcelID,
                                PropertyAddress,
                                SalePrice,
                                SaleDate,
                                LegalReference
                   ORDER BY UniqueID
               ) AS row_num
        FROM NashvilleHousingDataFormatted
    ) AS RowNumCTE
    WHERE row_num > 1
);



-- Step 8: Delete Unused Column 
 
 /*
As SQLite does not support Drop Column, we need to typically create a new table with the desired structure, 
 copy the data from the old table to the new one, and then rename the new table to the original table name.
 */
 
SELECT * 
FROM NashvilleHousingDataFormatted

-- Step 1: Create a new table without the columns to be dropped
CREATE TABLE NashvilleHousingData AS
SELECT
    UniqueID,
    ParcelID,
    LandUse,
	PropertySplitAddress,
	PropertySplitCity,
	SaleDateConverted,
	SalePrice,
	LegalReference,
	SoldAsVacant,
	OwnerName,
	OwnerSplitAddress,
	OwnerSplitCity2,
	OwnerSplitState
	Acreage,
	LandValue,
	BuildingValue,
	TotalValue,
	YearBuilt,
	Bedrooms, 
	FullBath,
	HalfBath

FROM NashvilleHousingDataFormatted;

-- Step 2: Drop the original table
DROP TABLE NashvilleHousingDataFormatted;

-- Step 3: Rename the new table to the original table name
ALTER TABLE NashvilleHousingData RENAME TO NashvilleHousingDataFormatted;



/* 
This is another version of code using Microsoft SQL Server and there are some different queries compared to SQLite, just for your reference;)
*/ 
-- Credited by Alex The Analyst 

-- Standardize Date Format

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select *
From NashvilleHousing
--Where PropertyAddress is null
order by ParcelID


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null




--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


Select PropertyAddress
From NashvilleHousing


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address

From NashvilleHousing


ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))




Select *
From NashvilleHousing



Select OwnerAddress
From NashvilleHousing


Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From NashvilleHousing



ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)



Select *
From NashvilleHousing




--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleHousing
Group by SoldAsVacant
order by 2




Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From NashvilleHousing


Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END






-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From NashvilleHousing
--order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress



Select *
From NashvilleHousing




---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns



Select *
From NashvilleHousing


ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
