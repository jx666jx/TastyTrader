# find the CSV files in mysql-files dir and ask the user which one to process. 
# delete it upon completion.

import os, sys, datetime, fnmatch,mysql.connector, tasty_database, yFinanceFinder_userDataPrices
from mysql.connector import errorcode, ClientFlag

# VARS
startDirectory = ('/var/lib/mysql-files/')
filetypes = ['tastyworks_transactions*.csv']
importFiles=[]
filetoprocess=()
numFiles=0
nomore=0

# build a list of the files to import (importFiles)
for root, dirs, files in os.walk( startDirectory ):
	for extension in ( tuple(filetypes) ):
		for filename in fnmatch.filter(files, extension):
			filepath = os.path.join(root, filename)
			if os.path.isfile( filepath ):
				importFiles.append(filename)

while nomore == 0 and len(importFiles) > 0:
    # ask the user which one to process
    print ('---------------------------------------------------------------------------')
    print ('Files named '+ str(filetypes) +' found in '+ startDirectory )
    print ('---------------------------------------------------------------------------')

    # list out the files that match
    for i in importFiles:
        numFiles+=1
        print (str(numFiles) + ". " + i)

    while True:
        try:
            num = int(input('\nWhich file would you like to process (1 - '+str(len(importFiles))+') : '))
            if 1 <= num <= len(importFiles):
                break
            else:
                print ('Must be in range 1 - '+str(len(importFiles))+'.')   
        except ValueError:
            print('Does not compute. Select a number.')

    # got the file to process from user 
    filetoprocess=startDirectory + importFiles[num-1]
    print('\n- File selected: ', filetoprocess)

    # connect to DB
    cnx=tasty_database.connect_to_database()
    cursor=cnx.cursor()

    # Since I wrote this fancy stored procedure first, Im going to use it. 
    # I dont care how much easier it is with Python. :)
    # we should only have 1 returning anyway
    query = """CALL sp_imp_GetAcctID ('%s') """ % (importFiles[num-1])
    cursor.execute(query)
    result=cursor.fetchone()
    for row in result:
        acctid = str(result[0])
    print("\n- Account ID derived from the filename: " + acctid )

    # Close and re-establish the DB connection
    cursor.close()
    cnx.close()
    cnx=tasty_database.connect_to_database()
    cursor=cnx.cursor()

    # import the CSV into tmp_import via fully qualified path
    print("\n- Create the tmp_import table and import data  ")
    # drop and create the tmp_import table
    query = """CALL sp_create_tmpImport;"""
    cursor.execute(query)

    query = """LOAD DATA INFILE '%s'
    INTO TABLE TastyTrade.tmp_import
    FIELDS TERMINATED BY ',' 
    ENCLOSED BY '"'
    LINES TERMINATED BY '\\r\\n'
    IGNORE 1 ROWS""" % (filetoprocess)
    cursor.execute(query)
    cnx.commit()
    print("--- ",cursor.rowcount," row(s) of data imported to tmp_import.")

    # Close and re-establish the DB connection
    cursor.close()
    cnx.close()
    cnx=tasty_database.connect_to_database()
    cursor=cnx.cursor()

    # put the import into LongTermStorage, unless dupe ... thanks storedProcedure
    print("\n- Import file to LTS for: " + acctid + "       ---duplicate entries will not be imported")
    query = "CALL sp_imp_updateTastyLts ('%s') """ % (acctid) 
    cursor.execute(query)
    print("--- ",cursor.rowcount," row(s) of data imported to LTS.")

    # put the import into tasty_data, unless dupe ... thanks storedProcedure
    print("\n- Import file to tasty_data for: " + acctid + "       ---duplicate entries will not be imported")
    query = """CALL sp_imp_updateTastyData ('%s') """ % (acctid)
    cursor.execute(query)
    print("--- ",cursor.rowcount," row(s) of data added to tasty_data.")

    # put the import into user_data, unless dupe ... thanks storedProcedure and table indexes
    print("\n- Import new CIDs to user_data" )
    query = """CALL sp_imp_updateUserData """
    cursor.execute(query)
    print("--- ",cursor.rowcount," row(s) of data added to user_data.")

    # drop the temp table
    print("\n- Drop the tmp_import table\n" )
    query = """DROP TABLE IF EXISTS `tmp_import`; """
    cursor.execute(query)

    # close the DB
    cursor.close()
    cnx.close()

    # update the yahoo finance data on all records ... if required
    # print("- Update the YahooFinance data for applicable records" )
    yFinanceFinder_userDataPrices.update_yfinance_data()

    # move the processed file to an archive
    print ("\n- Moved import file: "+ filetoprocess + "_imported-"+datetime.date.today().strftime('%Y%m%d'))
    os.rename(filetoprocess, filetoprocess + "_imported-"+datetime.date.today().strftime('%Y%m%d'))
    # remove from processing    
    importFiles.remove(importFiles[num-1])
    numFiles=0

    if (len(importFiles) > 0):
        while nomore < 1:
            reply = str(input('\n- '+str(len(importFiles))+' files remain. Continue (y/n): ')).lower().strip()
            if reply[:1] == 'y':
                print ("...\n")
                break
            if reply[:1] == 'n':
                print ('exit')
                nomore=1
                break
    else:
        nomore=1
        print ('exit')
        break
