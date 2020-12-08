/*  ------------------------------------------------ */
/*  --------------  IMPORT PROCESSS   -------------- */
/*  ----  run these in python script  -------------- */
/*  ------------------------------------------------ */

/* create the tmp_import table  */
USE TastyTrade;
CALL sp_create_tmpImport;

/* import the CSV into tmp_import via fully qualified path  */
USE TastyTrade;
SET SESSION sql_mode = '';
LOAD DATA INFILE '/var/lib/mysql-files/tastyworks_transactions_x1234_2020-04-20_2020-08-18.csv'
INTO TABLE TastyTrade.tmp_import
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
--SHOW WARNINGS

/* get the accountID from the import CSV filename ... returns AcctID */
USE TastyTrade;
CALL sp_imp_GetAcctID ('tastyworks_transactions_x1234_2020-04-20_2020-08-18.csv')

/* put import data in the LTS ... pass the AcctID */ 
USE TastyTrade;
CALL sp_imp_updateTastyLts ('x1234')

/* import the data into tasty_data ... pass the AcctID */
USE TastyTrade;
CALL sp_imp_updateTastyData ('x1234');

/* import the data into user_data */
USE TastyTrade;
CALL sp_imp_updateUserData;

/* DROP the temp table */ 
USE TastyTrade;
DROP TABLE IF EXISTS `tmp_import`;


/*  ------------------------------------------------ */
/*  ------------  IMPORT COMPLETE  ----------------- */
/*  ------------------------------------------------ */



