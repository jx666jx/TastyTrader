# TastyTrader
Database and scripts for managing TastyWorks trade exports.  Geared toward equity options.

DB and DB import kinda done. TW import is done via SQL ... might be better in Python or somewhere else.

- Install MySQL. 
- Use the MySQL scripts to build out all the tables, views, and stored procedures. 
- Update your MySQL password in tasty_database.py.
- Put your TastyWorks export files in /var/lib/mysql-files/  ... Make sure your user has access to those files.
- run the import.py.  This will ask which file to process from the above folder.  Some Yahoo finance data (symbol high/low/close/volume) will be looked up as part of the import process.

- UD_status_none.py checks for any user_data rows with no status.      This is as far as I got.  We need to start manually processing and joining records with no status.
