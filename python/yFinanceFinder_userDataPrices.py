# Update all the symbols to include the High, Low, Close, Volume from the trade date ... aka ... yFinanceFinder

import mysql.connector, yfinance, tasty_database
from mysql.connector import errorcode

def update_yfinance_data ():
  yfinance.pdr_override()
  yfUpdate=[]
  yfUpdateFeed={}

  # connect to DB
  cnx=tasty_database.connect_to_database()
  cursor=cnx.cursor()
    
  # Get a list of all rows that need updating via database view v_yFinanceFinder:
  #  - InstrumentType LIKE Equity% - Equity and Equity Option
  #  - symClose is NULL - dont include if we already looked it up
  #  - Symbol is not NULL - is there a Symbol?
  #  - Type is Trade - make sure it was a valid trade on a trading day that has data
  query = "SELECT * from TastyTrade.v_yFinanceFinder;"
  cursor.execute(query)

  print ("- YahooFinance data update")

  # Build up a list of dictionaries that need updating
  for i in cursor:
    # get the Yahoo Finance data for the tasty_data.Symbol on tasty_data.Date
    data = yfinance.download(i[1], start=i[2], end=i[2],progress=False)
    yfUpdateFeed={"CID": (i[0]),"High":data["High"][0],"Low":data["Low"][0],"Close":data["Close"][0],"Volume":data["Volume"][0]}
    yfUpdate.append (yfUpdateFeed)

  # Update the database for all dictionaries in the list
  z=0
  for i in yfUpdate:
    z += 1
    query = """UPDATE user_data SET symHigh=%s, symLow=%s, symClose=%s, symVol=%s WHERE convertID=%s"""
    inputData = (round(i["High"],2), round(i["Low"],2), round(i["Close"],2), int(i["Volume"]), i["CID"])
    #print (query, inputData)
    cursor.execute(query, inputData)
    cnx.commit()

  print ("--- records updated with YahooFinance data: " +str(z))
  cursor.close()
  cnx.close()

