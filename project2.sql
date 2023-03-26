/*

Cleaning Data in SQL Queries

*/



--Quickly view the dataset
Select *
From PortfolioProject.dbo.NashvilleHousing











--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

Select saleDateConverted, CONVERT(Date,SaleDate) --originally the SaleDate is in date-time format, we are converting it into data format only
From PortfolioProject.dbo.NashvilleHousing

--Select SaleDate, CONVERT(Date,SaleDate)
--From PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)










--------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select *
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
order by ParcelID
--explore the whole set

--notice that some property does not have a PropertyAddress, we want to find the existing one and populate them to the corresponding ParcelID
--Here we join this table to itself
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) --isnull function: here if a.address is null, return the b.address to populate
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID --make sure have the same parcelID
	AND a.[UniqueID ] <> b.[UniqueID ] --different row has diff uniqueID so we make sure they are not from the same row
Where a.PropertyAddress is null


--we have explored and checked in the above, now we make the actual update to the table
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null










--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as StreetAddress --basically this line returns the first part as address only from the PropertyAddress(Address, City, State) format
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as CityAddress
--SUBSTRING(string to extract from, start position--the first position in string is 1, length--number of characters to extract) function extracts some characters from a string
--CHARINDEX(substring to search for, string to be searched, position where search will start) function searches for a substring in a string, and returns the position
From PortfolioProject.dbo.NashvilleHousing





--create a new column to store the street address part and add them
ALTER TABLE NashvilleHousing
Add PropertyStreetAddress Nvarchar(255);

Update NashvilleHousing
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )





--create a new column to store the city location part and add them
ALTER TABLE NashvilleHousing
Add PropertyCity Nvarchar(255);

Update NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))




--now we can view our updated table
Select *
From PortfolioProject.dbo.NashvilleHousing




--handle the OwnerAddress
Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing


Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From PortfolioProject.dbo.NashvilleHousing
--basically it first replace the commmas ',' into periods '.' using the REPLACE(string, old_string, new_string) function
--so that the periods can be used as recognizable delimeters for PARSENAME functions
--then use PARSENAME function to return each part of the address into 3 SELECT columns

--PARSENAME ('object_name' , object_piece )
-- object_piece
-- Is the object part to return. object_piece is of type int, and can have these values:
-- 1 = Object name
-- 2 = Schema name
-- 3 = Database name
-- 4 = Server name

--this is easier to use than SUBSTRING but logically requires more intuition



--again, create new columns and add each part of the address
ALTER TABLE NashvilleHousing
Add OwnerStreetAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


--view the updated table
Select *
From PortfolioProject.dbo.NashvilleHousing










--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field
-- (to make the data consistent)


--first see there are some responses in "Y" and "N" instead of "Yes" and "No"
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2


--quickly view and make sure this works properly
Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes' --in the case when SoldAsVacant = 'Y' Then change it to 'Yes' instead
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant --otherwise leave it as it is
	   END
From PortfolioProject.dbo.NashvilleHousing


--now we do the actual update
Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
;






-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

--we create CTE and check for duplicates using partition by
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
					)
    AS row_num

From PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress


--then we delete these duplicates
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
					)
    AS row_num

From PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
Delete
From RowNumCTE
Where row_num > 1
--now if we run the above code chunck to check the duplicates are gone



Select *
From PortfolioProject.dbo.NashvilleHousing










---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


Select *
From PortfolioProject.dbo.NashvilleHousing


--drop the unwanted columns
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


Select *
From PortfolioProject.dbo.NashvilleHousing


--Now we have cleaned the data to make it more usable / user friendly!














-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO




