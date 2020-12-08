import mysql.connector
from mysql.connector import errorcode
from sqlalchemy import create_engine

def connect_to_database():
    try:
        # dont store passwords ... boo
        return mysql.connector.connect(user='root', password='password', database='TastyTrade')
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print("Something is wrong with your user name or password")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            print("Database does not exist")
        else:
            print(err)

def connect_to_dbEngine():
    try:
        # dont store passwords ... boo
        return create_engine('mysql+pymysql://root:password@127.0.0.1/TastyTrade', pool_recycle=3600)
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print("Something is wrong with your user name or password")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            print("Database does not exist")
        else:
            print(err)

