import pymysql, tasty_database
import pandas as pd
import sqlalchemy as db

engine = tasty_database.connect_to_dbEngine()
connection = engine.connect()
metadata = db.MetaData()

workingData = db.Table('v_MergedData', metadata, autoload=True, autoload_with=engine)

query = db.select([workingData]).where(workingData.columns.status == None)

results = connection.execute(query).fetchall()
df = pd.DataFrame(results)
df.columns = results[0].keys()

for index, row in df.iterrows():
    print(row['AccountID'], row['Date'], row['Description'])

#for column_name in df:
#    print(column_name)
#
#for column_name, item in df.iteritems():
#    print(column_name)
#    print(item)
#    
#for index, row in df.iterrows():
#    print(index)
#    print(row)