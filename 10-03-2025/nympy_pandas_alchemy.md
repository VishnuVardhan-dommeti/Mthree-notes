# NumPy, Pandas, and SQLAlchemy

## Overview
This script demonstrates fundamental operations using NumPy, Pandas, and SQLAlchemy in Python. It covers array creation, mathematical operations, statistical functions, Pandas DataFrame manipulations, and database interactions using SQLAlchemy.

## NumPy Operations

### Import NumPy
```python
import numpy as np
```
NumPy is a fundamental package for numerical computing in Python.

### Creating Arrays
```python
arr = np.array([1, 2, 3, 4, 5])
arr_2d = np.array([[1, 2, 3], [4, 5, 6]])
print(arr)
print(arr_2d)
```
- `np.array([values])` creates a one-dimensional NumPy array.
- `np.array([[values]])` creates a two-dimensional NumPy array.

### Creating Special Arrays
```python
arr_random = np.random.rand(3, 4)
zeros_array = np.zeros((3, 4))
ones_array = np.ones((3, 4))
full_array = np.full((3, 4), 10)
```
- `np.random.rand(rows, cols)` creates a random array with values between 0 and 1.
- `np.zeros((rows, cols))` creates an array filled with zeros.
- `np.ones((rows, cols))` creates an array filled with ones.
- `np.full((rows, cols), value)` creates an array filled with a specified value.

### Creating Ranges
```python
arr_range = np.arange(10, 20, 0.5)
print(arr_range)
```
- `np.arange(start, stop, step)` creates an array with a specified range and step size.

### Matrix Operations
```python
matrix_1 = np.array([[1, 2, 3], [4, 5, 6]])
matrix_2 = np.array([[1, 2, 3], [4, 5, 6]])

matrix_addition = matrix_1 + matrix_2
matrix_subtraction = matrix_1 - matrix_2
matrix_multiplication = matrix_1 * matrix_2
matrix_division = matrix_1 / matrix_2
matrix_power = matrix_1 ** matrix_2
matrix_transpose = matrix_1.T
```
- `matrix_1 + matrix_2` performs element-wise addition.
- `matrix_1 - matrix_2` performs element-wise subtraction.
- `matrix_1 * matrix_2` performs element-wise multiplication.
- `matrix_1 / matrix_2` performs element-wise division.
- `matrix_1 ** matrix_2` raises each element to the power of the corresponding element.
- `matrix_1.T` returns the transpose of a matrix.

### Statistical Functions
```python
arr_mean = np.mean(arr)
arr_median = np.median(arr)
arr_std = np.std(arr)
arr_var = np.var(arr)
```
- `np.mean(arr)` calculates the mean (average) of an array.
- `np.median(arr)` calculates the median of an array.
- `np.std(arr)` calculates the standard deviation of an array.
- `np.var(arr)` calculates the variance of an array.

## Pandas Operations

### Import Pandas
```python
import pandas as pd
```
Pandas is used for data analysis and manipulation.

### Creating Series
```python
series = pd.Series([1, 2, 3, 4, 5])
series_2 = pd.Series([1, 2, 3, 4, 5], index=['a', 'b', 'c', 'd', 'e'])
```
- `pd.Series([values])` creates a Pandas Series.
- `pd.Series([values], index=[labels])` creates a Series with custom index labels.

### Creating DataFrame
```python
data = {
    'Name': ['John', 'Jane', 'Jim', 'Jill'],
    'Age': [20, 21, 22, 23],
    'City': ['New York', 'Los Angeles', 'Chicago', 'Houston']
}
df = pd.DataFrame(data)
print(df)
```
- `pd.DataFrame(dictionary)` creates a tabular data structure.

### Reading CSV
```python
df_csv = pd.read_csv('data.csv')
print(df_csv)
```
- `pd.read_csv(filename)` reads a CSV file into a Pandas DataFrame.

## SQLAlchemy Operations

### Import SQLAlchemy
```python
from sqlalchemy import create_engine, text, MetaData, Table, Column, Integer, String, ForeignKey, insert, select
```
- SQLAlchemy is used for interacting with databases.
## APPROACH-1
### Create SQLite Engine
```python
import os
print(os.getcwd())  # Get the current working directory

engine = create_engine('sqlite:///basic_module/src/Datastructures/data.db', echo=True)
```
- `os.getcwd()` retrieves the current working directory.
- `#create_engine('sqlite:///database_path')
  create_engine('sqlite:///mnt/e/desktop/Mthree_training/basicModule/src/Datastructures/data.db', echo=True)` connects SQLite to the project.

### Set Permissions (if needed)
If permission issues arise, use the following command:
```bash
chmod 755 /mnt/e/desktop/Mthree_training/basicModule/src/Datastructures/data.db
```
- This grants appropriate access permissions.
![image](https://github.com/user-attachments/assets/ac93f3e0-fdcf-4abf-9f8f-e6391ed17c6e)

### Execute SQLite Commands in Terminal
To open the database in the terminal, use:
```bash
sqlite3 /mnt/e/desktop/Mthree_training/basicModule/src/Datastructures/data.db
```
Once inside SQLite, list available tables with:
```sql
.tables
```
![image](https://github.com/user-attachments/assets/0e5055d5-5b9d-43e9-a6c1-107992b06cb2)

Alternatively, use the SQLite extension for better visualization.
View it in sqlite extension(download it from extensions)
![Sqlite Explorer](https://github.com/user-attachments/assets/744393a4-7b55-4e82-8c1a-c545ddb93a41)


### UBUNTU TERMINAL:
```sqlite3 /mnt/e/desktop/Mthree_training/basicModule/src/Datastructures/data.db```

![image](https://github.com/user-attachments/assets/920746c4-841c-4d68-9947-a13bd5c618a0)
## APPROACH-2
# Database Setup Guide

## 1. Creating a Database Directory
```sh
mkdir -p ~/databases
```
- This command creates a new folder called `databases` in the home directory (`~`).
- The `-p` option ensures that no error occurs if the directory already exists.

## 2. Moving the Database File
```sh
mv /home/ganesh/basic-module/data.db ~/databases/
```
- Moves the SQLite database file (`data.db`) from `basic-module` to `~/databases/`.

## 3. Checking If the File Exists
```sh
ls -l ~/databases/data.db
```
- Lists the details of `data.db` to confirm it was successfully moved.

## 4. Navigating to the Project Directory
```sh
cd basic-module/
cd numerical/
```
- Moves into the `basic-module/numerical` directory where the Python script (`temp.py`) is located.

## 5. Installing Required Packages
```sh
sudo apt install python3-pip
```
- Installs `pip`, the package manager for Python.

```sh
pip3 install sqlalchemy
```
- Installs `SQLAlchemy`, which allows Python to interact with databases.

```sh
sudo apt install sqlalchemy
```
- Attempts to install `SQLAlchemy` using Ubuntu’s package manager (but it's not available via this method).

```sh
pip3 install --break-system-packages sqlalchemy
```
- Forces the installation of `SQLAlchemy`, bypassing Ubuntu’s restrictions.

## 6. Running the Python Script
```sh
python3 temp.py
```
- Executes `temp.py`, which:
  - Connects to the database.
  - Creates tables (`users`, `posts`, `book`) if they don’t exist.
  - Inserts data into the tables.
  - Fetches and prints data.

## 7. Opening the SQLite Database
```sh
sqlite3 /home/ganesh/databases/data.db
```
- Opens the SQLite shell and connects to the `data.db` database.

## 8. Checking Available Tables
```sh
.tables
```
- Displays all tables in the database (`book`, `posts`, `users`).

## 9. Viewing Data in Tables
```sql
SELECT * FROM users;
SELECT * FROM posts;
SELECT * FROM book;
```
- Retrieves and displays all records from the respective tables.

## 10. Exiting the Virtual Environment
```sh
deactivate
```
- Exits the virtual environment (if activated).

## 11. Checking Python and SQLAlchemy Versions
```sh
python3 -V
```
- Displays the installed Python version.

```sh
pip3 list | grep sqlalchemy
```
- Checks if `SQLAlchemy` is installed and displays its version.

## 12. Reinstalling SQLAlchemy
```sh
pip3 install --break-system-packages sqlalchemy
```
- Reinstalls `SQLAlchemy` in case of issues.

## 13. Running Python Script Again
```sh
python3 /home/ganesh/basic-module/numerical/temp.py
```
- Runs `temp.py` to create/update the database tables and insert data.

## 14. Reopening SQLite and Checking Tables
```sh
sqlite3 /home/ganesh/databases/data.db
.tables
```
- Ensures all tables (`book`, `posts`, `users`) are still present.

## APPROACH-3
## Without ENV

## 1. Creating a Database Directory
```sh
mkdir -p ~/databases
```
- This command creates a new folder called `databases` in the home directory (`~`).
- The `-p` option ensures that no error occurs if the directory already exists.

## 2. Moving the Database File
```sh
mv /mnt/e/desktop/Mthree_training/basicModule/src/Datastructures/data.db ~/databases/
```
- Moves the SQLite database file (`data.db`) from `basic-module` to `~/databases/`.

## 3. Checking If the File Exists
```sh
ls -l ~/databases/data.db
```
- Lists the details of `data.db` to confirm it was successfully moved.

## 4. Navigating to the Project Directory
```sh
cd basic-module/
cd numerical/
```
- Moves into the `basic-module/numerical` directory where the Python script (`temp.py`) is located.

## 5. Installing Required Packages
```sh
sudo apt install python3-pip
```
- Installs `pip`, the package manager for Python.

```sh
pip3 install sqlalchemy
```
- Installs `SQLAlchemy`, which allows Python to interact with databases.

```sh
sudo apt install sqlalchemy
```
- Attempts to install `SQLAlchemy` using Ubuntu’s package manager (but it's not available via this method).

```sh
pip3 install --break-system-packages sqlalchemy
```
- Forces the installation of `SQLAlchemy`, bypassing Ubuntu’s restrictions.

## 6. Running the Python Script
```sh
python3 temp.py
```
- Executes `temp.py`, which:
  - Connects to the database.
  - Creates tables (`users`, `posts`, `book`) if they don’t exist.
  - Inserts data into the tables.
  - Fetches and prints data.

## 7. Opening the SQLite Database
```sh
sqlite3 /mnt/e/desktop/Mthree_training/basicModule/src/Datastructures/data.db
```
- Opens the SQLite shell and connects to the `data.db` database.

## 8. Checking Available Tables
```sh
.tables
```
- Displays all tables in the database (`book`, `posts`, `users`).

## 9. Viewing Data in Tables
```sql
SELECT * FROM users;
SELECT * FROM posts;
SELECT * FROM book;
```
- Retrieves and displays all records from the respective tables.

## 10. Exiting the Virtual Environment
```sh
deactivate
```
- Exits the virtual environment (if activated).

## 11. Checking Python and SQLAlchemy Versions
```sh
python3 -V
```
- Displays the installed Python version.

```sh
pip3 list | grep sqlalchemy
```
- Checks if `SQLAlchemy` is installed and displays its version.

## 12. Reinstalling SQLAlchemy
```sh
pip3 install --break-system-packages sqlalchemy
```
- Reinstalls `SQLAlchemy` in case of issues.

## 13. Running Python Script Again
```sh
python3 /home/ganesh/basic-module/numerical/temp.py
```
- Runs `temp.py` to create/update the database tables and insert data.

## 14. Reopening SQLite and Checking Tables
```sh
sqlite3 /mnt/e/desktop/Mthree_training/basicModule/src/Datastructures/data.db
.tables
```
- Ensures all tables (`book`, `posts`, `users`) are still present.

---

## Python Script (`temp.py`)
```python
from sqlalchemy import create_engine, text, MetaData, Table, Column, Integer, String, ForeignKey, insert, select

db_path = "/mnt/e/desktop/Mthree_training/basicModule/src/Datastructures/data.db"
engine = create_engine(f'sqlite:///{db_path}', echo=True)

metadata = MetaData()

users = Table('users', metadata,
    Column('id', Integer, primary_key=True),
    Column('name', String),
    Column('age', Integer),
    Column('city', String),
)

posts = Table('posts', metadata,
    Column('id', Integer, primary_key=True),
    Column('title', String),
    Column('content', String),
    Column('user_id', Integer, ForeignKey('users.id')),
)

metadata.create_all(engine)

with engine.connect() as con:
    insert_stmt = insert(users).values(name='John', age=20, city='New York')
    result = con.execute(insert_stmt)
    print(result.rowcount)

    insert_stmt = insert(posts).values(title='Post 1', content='Content 1', user_id=1)
    result = con.execute(insert_stmt)
    print(result.rowcount)

    con.commit()

    select_stmt = select(users)
    result = con.execute(select_stmt)
    for row in result:
        print(row)

    select_stmt = select(posts)
    result = con.execute(select_stmt)
    for row in result:
        print(row)
```




### Define Database Schema
```python
metadata = MetaData()

users = Table('users', metadata,
    Column('id', Integer, primary_key=True),
    Column('name', String),
    Column('age', Integer),
    Column('city', String),
)

posts = Table('posts', metadata,
    Column('id', Integer, primary_key=True),
    Column('title', String),
    Column('content', String),
    Column('user_id', Integer, ForeignKey('users.id')),
)

metadata.create_all(engine)
```
- `MetaData()` stores table definitions.
- `Table('name', metadata, columns)` defines a table with columns.
- `metadata.create_all(engine)` creates the tables in the database.
