/* SPIN IT UP */
CREATE DATABASE IF NOT EXISTS TastyTrade;
USE TastyTrade;

/* table for LongTermStorage of the unfettered import data (aside from AccountID and ImportDate) - unchanged and appaended to - */
DROP TABLE IF EXISTS TastyTrade.tasty_lts;
CREATE TABLE IF NOT EXISTS TastyTrade.tasty_lts (
	`AccountID` VARCHAR(8),
	`ImportDate` DATETIME,   
	`Date` VARCHAR (24) NOT NULL, 
	`Type` VARCHAR(16) NOT NULL, 
	`Action` VARCHAR(16), 
	`Symbol` VARCHAR(32), 
	`Instrument Type` VARCHAR(16), 
	`Description` VARCHAR(64) NOT NULL, 
	`Value` VARCHAR(38), 
	`Quantity` VARCHAR(38), 
	`Average Price` VARCHAR(38), 
	`Commissions` VARCHAR(38), 
	`Fees` VARCHAR(38), 
	`Multiplier` VARCHAR(38), 
	`Underlying Symbol` VARCHAR(8), 
	`Expiration Date` VARCHAR(10), 
	`Strike Price` VARCHAR(38), 
	`Call or Put` VARCHAR(4)
);

/* table to hold the updated fields. 
-- add a unique ID
-- add AccountID the importing account ID from the CSV import file name
-- add the ImportDate
-- Date - get a proper DATETIME 
-- InstrumentType, AveragePrice, UnderlyingSymbol, StrikePrice, CallPut - remove whitespace in column name
-- ExpirationDate - remove whitespace in column name and get a proper DATE
*/
DROP TABLE IF EXISTS TastyTrade.tasty_data;
CREATE TABLE IF NOT EXISTS TastyTrade.tasty_data (
	`id` binary(16) default (uuid_to_bin(uuid())) not null primary key,  
	`AccountID` VARCHAR(8),  
	`ImportDate` DATETIME,   
	`Date` DATETIME NOT NULL, 
	`Type` VARCHAR(16) NOT NULL, 
	`Action` VARCHAR(16), 
	`Symbol` VARCHAR(32), 
	`InstrumentType` VARCHAR(16), 
	`Description` VARCHAR(64) NOT NULL, 
	`Value` DECIMAL(38, 2), 
	`Quantity` DECIMAL(38, 0), 
	`AveragePrice` DECIMAL(38, 2), 
	`Commissions` DECIMAL(38, 2), 
	`Fees` DECIMAL(38, 2), 
	`Multiplier` DECIMAL(38, 2), 
	`UnderlyingSymbol` VARCHAR(8), 
	`ExpirationDate` DATE,   
	`StrikePrice` DECIMAL(38, 2), 
	`CallPut` VARCHAR(4)
);

/* setup the userInput table */
DROP TABLE IF EXISTS TastyTrade.user_data;
CREATE TABLE IF NOT EXISTS TastyTrade.user_data (
	`id` binary(16) default (uuid_to_bin(uuid())) not null primary key,  
	`convertID` VARCHAR(42) unique,
	`updateDate` DATETIME,
	`commfee` DECIMAL(38, 2),
	`valuecf` DECIMAL(38, 2),
	`dte` DECIMAL(38, 0),
	`symHigh` DECIMAL(38, 2),
	`symLow` DECIMAL(38, 2),
	`symClose` DECIMAL(38, 2), 
	`symVol` DECIMAL(38, 2),   
	`IVR` DECIMAL(38, 2),
	`symOrder` DECIMAL(38, 2),
	`delta` DECIMAL(38, 2),
	`theta` DECIMAL(38, 2),
	`stratID` DECIMAL(38, 0),
	`strategy` VARCHAR(42),
	`status` VARCHAR(42),
	`rollLink` BOOLEAN DEFAULT false,
	`notes` VARCHAR(42)
);

/* setup the variables table  */
DROP TABLE IF EXISTS TastyTrade.user_variables;
CREATE TABLE IF NOT EXISTS TastyTrade.user_variables (
	`type` VARCHAR(42),
    `data` VARCHAR(42)
);

/* import the variables from the CSV in setup. 
needs to be moved to mysql dir for reading ... something about security something or other 
Want to update it? Change the CSV then drop and readd this table.
*/
USE TastyTrade;
SET SESSION sql_mode = '';
LOAD DATA INFILE '/var/lib/mysql-files/variables.csv'
INTO TABLE TastyTrade.user_variables
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

/* setup the strategy table  */
DROP TABLE IF EXISTS TastyTrade.user_strategy;
CREATE TABLE IF NOT EXISTS TastyTrade.user_strategy (
	`strategy` VARCHAR(42) NOT NULL unique,
	`notes` VARCHAR(1337),
	`TTapproach` VARCHAR(11337),
	`TTclose` VARCHAR(1337),
	`TTmanage` VARCHAR(1337),
	`TTurl` VARCHAR(128)
);
/* import the strategy from the CSV in setup. 
needs to be moved to mysql dir for reading ... something about security something or other 
Want to update it? Change the CSV then drop and readd this table.
*/
USE TastyTrade;
SET SESSION sql_mode = '';
LOAD DATA INFILE '/var/lib/mysql-files/strategy.csv'
INTO TABLE TastyTrade.user_strategy
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

/*  ------------------------------------------------ */
/*  ----------------- VIEWS ------------------------ */
/*  ------------------------------------------------ */
/* DB view to find those that need yFinance field updated */
DROP VIEW IF EXISTS `TastyTrade`.`v_yFinanceFinder`;
CREATE ALGORITHM = UNDEFINED DEFINER = `root`@`localhost` SQL SECURITY DEFINER VIEW `TastyTrade`.`v_yFinanceFinder` AS
    SELECT 
        BIN_TO_UUID(`TastyTrade`.`tasty_data`.`id`) AS `CID`,
        `TastyTrade`.`tasty_data`.`Symbol` AS `Symbol`,
        `TastyTrade`.`tasty_data`.`Date` AS `Date`
    FROM
        (`TastyTrade`.`tasty_data`
        LEFT JOIN `TastyTrade`.`user_data` ON ((BIN_TO_UUID(`TastyTrade`.`tasty_data`.`id`) = `TastyTrade`.`user_data`.`convertID`)))
    WHERE
        ((`TastyTrade`.`tasty_data`.`InstrumentType` LIKE 'Equity%')
            AND (`TastyTrade`.`user_data`.`symClose` IS NULL)
            AND (`TastyTrade`.`tasty_data`.`Symbol` IS NOT NULL)
            AND (`TastyTrade`.`tasty_data`.`Type` = 'Trade'))
    ORDER BY `TastyTrade`.`tasty_data`.`Symbol`;


/* join the user_data and the tasty_data and get the working fields */
USE TastyTrade;
DROP VIEW IF EXISTS `TastyTrade`.`v_MergedData`;
CREATE ALGORITHM = UNDEFINED DEFINER = `root`@`localhost` SQL SECURITY DEFINER VIEW `TastyTrade`.`v_MergedData` AS
	SELECT tasty_data.AccountID, tasty_data.Date, tasty_data.Type, tasty_data.InstrumentType, tasty_data.Symbol, tasty_data.Description, tasty_data.Quantity, tasty_data.ExpirationDate, tasty_data.StrikePrice, tasty_data.Action, tasty_data.CallPut, user_data.symOrder, user_data.IVR, user_data.delta, user_data.theta, user_data.status, user_data.stratID, user_data.strategy, user_data.rollLink, user_data.notes
	FROM tasty_data LEFT JOIN user_data ON BIN_TO_UUID(tasty_data.id) = user_data.convertID 
	ORDER BY tasty_data.Date


/*  ------------------------------------------------ */
/*  -------------- STORED PROCEDURES  -------------- */
/*  ------------------------------------------------ */
--
/* create the tmp_import table */
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_tmpImport`()
BEGIN
/* temporary table to hold the import for a second so we can change a few columns around */
DROP TABLE IF EXISTS tmp_import;
CREATE TABLE IF NOT EXISTS tmp_import (
	`Date` VARCHAR (24) NOT NULL, 
	`Type` VARCHAR(16) NOT NULL, 
	`Action` VARCHAR(16), 
	`Symbol` VARCHAR(32), 
	`Instrument Type` VARCHAR(16), 
	`Description` VARCHAR(64) NOT NULL, 
	`Value` VARCHAR(38), 
	`Quantity` VARCHAR(38), 
	`Average Price` VARCHAR(38), 
	`Commissions` VARCHAR(38), 
	`Fees` VARCHAR(38), 
	`Multiplier` VARCHAR(38), 
	`Underlying Symbol` VARCHAR(8), 
	`Expiration Date` VARCHAR(10), 
	`Strike Price` VARCHAR(38), 
	`Call or Put` VARCHAR(4)
);
END

--
/* extract the Tasty accountID from the import filename */
--
USE TastyTrade;
DROP PROCEDURE IF EXISTS `TastyTrade`.`sp_imp_GetAcctID`;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_imp_GetAcctID`(IN fileName VARCHAR(64))
BEGIN
/* grab the accountID found in the TastyWorks CSV export filename as AcctID */
SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(fileName, '_',-3),'_',1) as AcctID; 
END

--
/* Put the import data into LongTermStorage */
--
USE TastyTrade;
DROP PROCEDURE IF EXISTS `TastyTrade`.`sp_imp_updateTastyLts`;

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_imp_updateTastyLts`(IN AcctID VARCHAR(64))
BEGIN
/* put a copy of what was imported into a table with the unedited fields ... why? I dunno. just do it ... for now. 
   duplicates ignored - all fields match
*/
INSERT TastyTrade.tasty_lts 
	(`AccountID`,`ImportDate`,`Date`,`Type`,`Action`,`Symbol`,`Instrument Type`, `Description`, `Value`, `Quantity`, `Average Price`, `Commissions`, `Fees`, `Multiplier`, `Underlying Symbol`, `Expiration Date`, `Strike Price`, `Call or Put` )
SELECT 
	AcctID,
    now(),
    `Date`, `Type`, `Action`, `Symbol`,`Instrument Type`, `Description`, `Value`, `Quantity`, `Average Price`, `Commissions`, `Fees`, `Multiplier`, `Underlying Symbol`, `Expiration Date`, `Strike Price`, `Call or Put`
FROM TastyTrade.tmp_import AS tmp 
WHERE NOT EXISTS (
	SELECT `AccountID`, `Date`,`Type`,`Action`,`Symbol`,`Instrument Type`, `Description`, `Value`, `Quantity`, `Average Price`, `Commissions`, `Fees`, `Multiplier`, `Underlying Symbol`, `Expiration Date`, `Strike Price`, `Call or Put` 
	FROM TastyTrade.tasty_lts 
	WHERE (`AccountID`, `Date`,`Type`,`Action`,`Symbol`,`Instrument Type`, `Description`, `Value`, `Quantity`, `Average Price`, `Commissions`, `Fees`, `Multiplier`, `Underlying Symbol`, `Expiration Date`, `Strike Price`, `Call or Put`) 
	    = (AcctID, `Date`,`Type`,`Action`,`Symbol`,`Instrument Type`, `Description`, `Value`, `Quantity`, `Average Price`, `Commissions`, `Fees`, `Multiplier`, `Underlying Symbol`, `Expiration Date`, `Strike Price`, `Call or Put`)
) 
ORDER BY Date;
END

--
/* Put the import data into tasty_data with added/modified fields and data types */
--
USE TastyTrade;
DROP PROCEDURE IF EXISTS `TastyTrade`.`sp_imp_updateTastyData`;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_imp_updateTastyData`(IN AcctID VARCHAR(64))
BEGIN
/* migrate tmp_import to tasty_data table 
  - duplicates ignored - all fields match
  - every row gets a UUID used as table key
  - grab the acccount # from the importing CSV filename
  - get the current date for the ImportDate
  - adjust Date to be proper DATETIME 
  - adjust Symbol to get only the proper Symbol without the trailing option noise (which we can reconstruct with the other fields)
  - convert all the numeric fields into numbers. The quoted CSV fields with commas in them causes us to treat them intially as VARCHAR.
  - adjust ExpirationDate to be proper DATE
*/
SET SESSION sql_mode = '';
INSERT TastyTrade.tasty_data (`AccountID`,`ImportDate`,`Date`,`Type`,`Action`,`Symbol`,`InstrumentType`, `Description`, `Value`, `Quantity`, `AveragePrice`, `Commissions`, `Fees`, `Multiplier`, `UnderlyingSymbol`, `ExpirationDate`, `StrikePrice`, `CallPut` )
SELECT AcctID,
       now(),
	   STR_TO_DATE(Date,'%Y-%m-%dT%T'),
       Type,Action,
	   SUBSTRING_INDEX(Symbol, ' ',1),
       `Instrument Type`, 
	   `Description`, 
	   CAST(REPLACE(`Value`,',','') AS DECIMAL(38,2)),
	   CAST(REPLACE(`Quantity`,',','') AS DECIMAL(38,2)),
	   CAST(REPLACE(`Average Price`,',','') AS DECIMAL(38,2)),
	   CAST(REPLACE(`Commissions`,',','') AS DECIMAL(38,2)),
	   CAST(REPLACE(`Fees`,',','') AS DECIMAL(38,2)),
	   CAST(REPLACE(`Multiplier`,',','') AS DECIMAL(38,2)),
	   `Underlying Symbol`,
	   STR_TO_DATE(`Expiration Date`,'%m/%d/%Y'), 
	   `Strike Price`, 
	   `Call or Put`
FROM TastyTrade.tmp_import AS tmp
WHERE NOT EXISTS (
	SELECT `AccountID`,`Date`,`Type`,`Action`,`Symbol`,`InstrumentType`, `Description`, `Value`, `Quantity`, `AveragePrice`, `Commissions`, `Fees`, `Multiplier`, `UnderlyingSymbol`, `ExpirationDate`, `StrikePrice`, `CallPut`
	FROM TastyTrade.tasty_data
	WHERE (`AccountID`,`Date`,`Type`,`Action`,`Symbol`,`InstrumentType`, `Description`, `Value`, `Quantity`, `AveragePrice`, `Commissions`, `Fees`, `Multiplier`, `UnderlyingSymbol`, `ExpirationDate`, `StrikePrice`, `CallPut`) 
	    = (AcctID, `Date`,`Type`,`Action`,`Symbol`,`InstrumentType`, `Description`, `Value`, `Quantity`, `AveragePrice`, `Commissions`, `Fees`, `Multiplier`, `UnderlyingSymbol`, `ExpirationDate`, `StrikePrice`, `CallPut`)
)
ORDER BY Date;
END

--
/* update the user_data table with missing IDs (and some others) from tasty_data */
--
USE TastyTrade;
DROP PROCEDURE IF EXISTS `TastyTrade`.`sp_imp_updateUserData`;
USE TastyTrade;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_imp_updateUserData`()
BEGIN
/* get the converted table unique IDs into the user_data table ... 
dupes will be ignored because of the table unique constraint on convertID ... 
user_data and tasty_data can join via convertID ... yay */
INSERT IGNORE INTO TastyTrade.user_data 
	(user_data.convertID,user_data.updateDate,user_data.commfee,user_data.valuecf,user_data.dte)
SELECT 
	BIN_TO_UUID(tasty_data.id),
	now(),
	SUM(tasty_data.Commissions + tasty_data.Fees) AS commfee,
	SUM(tasty_data.Commissions + tasty_data.Fees + tasty_data.Value) AS valuecf,
	DATEDIFF(now(),tasty_data.ExpirationDate) 
	FROM tasty_data 
	GROUP BY tasty_data.id;
END

--
/* clear out the data tables for a redo ... got sick of doing each one at a time */
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_truncate_data`()
BEGIN
/* Clear out all the data tables and prepate for a new import */
TRUNCATE TABLE tasty_data;
TRUNCATE TABLE tasty_lts;
TRUNCATE TABLE user_data;
DROP TABLE tmp_import;
END

/*  ------------------------------------------------ */
/*  ------------  SETUP COMPLETE  ------------------ */
/*  ------------------------------------------------ */
