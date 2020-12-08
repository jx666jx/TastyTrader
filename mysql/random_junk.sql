/*  -------------- RANDOM JUNK  -------------- */

-- CLEAR IT ALL OUT AND START OVER
USE TastyTrade;CALL sp_truncate_data;

-- SELECT COUNT 
SELECT count(*) FROM TastyTrade.tmp_import;
SELECT count(*) FROM TastyTrade.tasty_lts;
SELECT count(*) FROM TastyTrade.tasty_data;
SELECT count(*) FROM TastyTrade.user_data;
SELECT count(*) FROM TastyTrade.user_strategy;
SELECT count(*) FROM TastyTrade.user_variables ORDER BY type,data;

-- SELECT * 
SELECT * FROM TastyTrade.tmp_import;
SELECT * FROM TastyTrade.tasty_lts;
SELECT * FROM TastyTrade.tasty_data;
SELECT * FROM TastyTrade.user_data;
SELECT * FROM TastyTrade.user_strategy ORDER BY strategy;
SELECT * FROM TastyTrade.user_variables ORDER BY type,data;

/* view based */
-- show me rows that qualify for YahooFinance data lookup
SELECT * from TastyTrade.v_yFinanceFinder;

-- what is that DB setup like
DESCRIBE tmp_import;

-- what do the IDs look like?
USE TastyTrade;
SELECT BIN_TO_UUID(user_data.id) AS UID,user_data.convertID AS CID,user_data.updateDate FROM user_data ORDER BY CID

-- how many items are in the userinput table
SELECT COUNT(user_data.convertID) AS count FROM TastyTrade.user_data

-- join the tables and show me the IDs from each
USE TastyTrade;
SELECT BIN_TO_UUID(tasty_data.id) AS CID, BIN_TO_UUID(user_data.id) AS UID
FROM tasty_data 
LEFT JOIN user_data ON BIN_TO_UUID(tasty_data.id) = user_data.convertID 
ORDER BY UID;
--ORDER BY CID;

-- show me some of the junk in the tables that are joined - YAY!
USE TastyTrade;
SELECT tasty_data.Symbol, tasty_data.Quantity, tasty_data.Value, tasty_data.Commissions, tasty_data.Fees, user_data.commfee, user_data.valuecf, user_data.status 
FROM tasty_data 
LEFT JOIN user_data ON BIN_TO_UUID(tasty_data.id) = user_data.convertID 
ORDER BY Symbol;

-- Let's try and isolate the items that need a python script to update the trade day prices ... this became the yFinanceFinder
USE TastyTrade;
SELECT BIN_TO_UUID(tasty_data.id) AS CID, tasty_data.Symbol, tasty_data.Date
FROM tasty_data LEFT JOIN user_data ON BIN_TO_UUID(tasty_data.id) = user_data.convertID 
WHERE tasty_data.InstrumentType LIKE 'Equity%' AND user_data.symClose IS NULL AND tasty_data.Symbol IS NOT NULL AND tasty_data.Type = 'Trade'
ORDER BY Symbol

-- Show me the ones that have no status set and show the stuff we will need to manually fill out
USE TastyTrade;
SELECT tasty_data.AccountID, tasty_data.Date, tasty_data.Type, tasty_data.InstrumentType, tasty_data.Symbol, tasty_data.Description, tasty_data.Quantity, tasty_data.ExpirationDate, tasty_data.StrikePrice, tasty_data.Action, tasty_data.CallPut, user_data.symOrder, user_data.IVR, user_data.delta, user_data.theta, user_data.status, user_data.stratID, user_data.strategy, user_data.rollLink, user_data.notes
FROM tasty_data LEFT JOIN user_data ON BIN_TO_UUID(tasty_data.id) = user_data.convertID 
WHERE user_data.status IS NULL
ORDER BY tasty_data.Date







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
	WHERE (`AccountID`, `Date`,`Type`,`Action`,`Symbol`,`Instrument Type`, `Description`, `Value`, `Quantity`, `Average Price`, `Commissions`, `Fees`, `Multiplier`, `Underlying Symbol`, `Expiration Date`, `Strike Price`, `Call or Put`) = ('x6664', `Date`,`Type`,`Action`,`Symbol`,`Instrument Type`, `Description`, `Value`, `Quantity`, `Average Price`, `Commissions`, `Fees`, `Multiplier`, `Underlying Symbol`, `Expiration Date`, `Strike Price`, `Call or Put`)
) 
ORDER BY Date;




