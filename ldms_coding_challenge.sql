/*********************************************************************
**
** This entire script can be run over and over as it drops and 
** recreates as necessary.  This script was created and tested on Live SQL of oracle cloud 19c
**
** This script is in three parts:
** 				Object Creation and Data Load
**				Reporting
**				Testing
**
** Part 1.	Object Creation and dataload
**
**		a>	Drop tables if they exist
**		b>	Create the tables
**		c>	Create the sequences 
**		d> 	Load data for departments
**		e> 	Insert data into the employees table
**		f>	Create sequence for employees note that initial data load has been commited
**		g>	Create trigger on employees to verify that the manager_id is a current employee
**		h>	Create procedure to create employees
**		i>	Create proc to adjust salary
**		j>	Create proc to transfer employees
**		k>	Function to get salary
**
** Part 2. 	Reports
**
**		Report 1
**		Report 2
**
** Part 3. 	Testing
**
**		a>	Test data load of departments
**		b>	Test data load of employees
**		c>	Test trigger employees_br_i
**		d>	Test procedure sp_create_employee 
**				Test d1.  Expected success
**				Test d2.  Expected Error - Manager ID does not exist in the employees table
**				Test d3.  Expected Error - Salary cannot be negative
**				Test d4.  Expected Error - Date Hired is not within the valid range 
**		e>	Test procedure sp_AdjustSalaryByPercentage	
**				Test e1 - Success
**				Test e2 - Employee ID does not exist in the employees table
**				Test e3 - Fail - Salary adjustment percentage cannot be 0
**				Test e4 - Fail - Resulting salary cannot be negative
**		f>	Test sp_TransferEmployee	
**				Test f1 - Success	
**				Test f2 - Fail, bad department
**				Test f3 - Fail, bad employee
**		g>	f_GetEmployeeSalary 
**				Test g1 - Success		
**				Test g2 - Fail, bad employee number
**
**********************************************************************/

/*********************************************************************
**
**
** PART 1 - Object Creation and Data Load
**
**
**********************************************************************/

-- ********************************************************
-- a>	Drop tables if they exist
-- ********************************************************

DECLARE
   c int;
BEGIN
    -- Drop tables if they exist
   SELECT COUNT(*) INTO c FROM user_tables WHERE table_name = UPPER('departments');
   IF c = 1 THEN
      EXECUTE IMMEDIATE 'DROP TABLE departments CASCADE CONSTRAINTS';
   END IF;
   SELECT COUNT(*) INTO c FROM user_tables WHERE table_name = UPPER('employees');
   IF c = 1 THEN
      EXECUTE IMMEDIATE 'DROP TABLE employees CASCADE CONSTRAINTS';
   END IF;
	-- Drop Sequences if they exist
   SELECT COUNT(*) INTO c FROM user_sequences WHERE sequence_name = UPPER('departments_seq');
   IF c = 1 THEN
      EXECUTE IMMEDIATE 'DROP SEQUENCE departments_seq';
   END IF;
   SELECT COUNT(*) INTO c FROM user_sequences WHERE sequence_name = UPPER('employees_seq');
   IF c = 1 THEN
      EXECUTE IMMEDIATE 'DROP SEQUENCE employees_seq';
   END IF;
END;
/

-- ********************************************************
-- b>	Create the tables
-- ********************************************************

CREATE TABLE departments (
  department_id NUMBER(5) PRIMARY KEY,
  department_name VARCHAR2(50) NOT NULL,
  location VARCHAR2(50) NOT NULL
);
/

CREATE TABLE employees (
  employee_id NUMBER(10) PRIMARY KEY,
  employee_name VARCHAR2(50) NOT NULL,
  job_title VARCHAR2(50) NOT NULL,
  manager_id NUMBER(10),
  date_hired DATE NOT NULL,
  salary NUMBER(10,2) NOT NULL,
  department_id NUMBER(5) NOT NULL,
  CONSTRAINT fk_dept_id FOREIGN KEY (department_id) REFERENCES departments(department_id)
);
/

-- ********************************************************
-- c>	Create the sequences ( creation of employees_seq is performed after initial data load)
-- ********************************************************

CREATE SEQUENCE departments_seq
  START WITH 1
  INCREMENT BY 1
  MINVALUE 1
  MAXVALUE 100000
  NOCYCLE
  NOCACHE;
/

-- ********************************************************
-- d> 	Load data for departments
-- ********************************************************

DECLARE
  v_seq_val NUMBER;
BEGIN
  -- Insert row 1
  SELECT departments_seq.NEXTVAL INTO v_seq_val FROM dual;
  INSERT INTO departments (department_id, department_name, location)
  VALUES (v_seq_val, 'Management', 'London');

  -- Insert row 2
  SELECT departments_seq.NEXTVAL INTO v_seq_val FROM dual;
  INSERT INTO departments (department_id, department_name, location)
  VALUES (v_seq_val, 'Engineering', 'Cardiff');

  -- Insert row 3
  SELECT departments_seq.NEXTVAL INTO v_seq_val FROM dual;
  INSERT INTO departments (department_id, department_name, location)
  VALUES (v_seq_val, 'Research & Development', 'Edinburgh');

  -- Insert row 4
  SELECT departments_seq.NEXTVAL INTO v_seq_val FROM dual;
  INSERT INTO departments (department_id, department_name, location)
  VALUES (v_seq_val, 'Sales', 'Belfast');

  COMMIT;
END;
/

-- ********************************************************
-- e> 	Insert data into the employees table
-- ********************************************************

-- Row 1
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (90001, 'John Smith', 'CEO', NULL, TO_DATE('01-Jan-1995', 'DD-MON-YYYY'), 100000, 1);

-- Row 2
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (90002, 'Jimmy Willis', 'Manager', 90001, TO_DATE('23-Sep-2003', 'DD-MON-YYYY'), 52500, 4);

-- Row 3
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (90003, 'Roxy Jones', 'Salesperson', 90002, TO_DATE('11-Feb-2017', 'DD-MON-YYYY'), 35500, 4);

-- Row 4
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (90004, 'Selwyn Field', 'Salesperson', 90003, TO_DATE('20-May-2015', 'DD-MON-YYYY'), 32000, 4);

-- Row 5
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (90005, 'David Hallett', 'Engineer', 90006, TO_DATE('17-Apr-2018', 'DD-MON-YYYY'), 40000, 2);

-- Row 6
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (90006, 'Sarah Phelps', 'Manager', 90006, TO_DATE('21-Mar-2015', 'DD-MON-YYYY'), 45000, 2);

-- Row 7
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (90007, 'Louise Harper', 'Engineer', 90006, TO_DATE('01-Jan-2013', 'DD-MON-YYYY'), 47000, 2);

-- Row 8
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (90009, 'Gus Jones', 'Manager', 90001, TO_DATE('15-May-2018', 'DD-MON-YYYY'), 50000, 3);

-- Row 9
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (90008, 'Tina Hart', 'Engineer', 90009, TO_DATE('28-Jul-2014', 'DD-MON-YYYY'), 45000, 3);

-- Row 10
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (90010, 'Mildred Hall', 'Secretary', 90001, TO_DATE('12-Oct-1996', 'DD-MON-YYYY'), 35000, 1);

-- Commit the changes 
COMMIT;

-- ********************************************************
-- f>	Create sequence for employees note that initial data load has been commited
-- ********************************************************

CREATE SEQUENCE employees_seq
  START WITH 90011
  INCREMENT BY 1
  MINVALUE 90011
  MAXVALUE 100000000
  NOCYCLE
  NOCACHE;
/

-- ********************************************************
-- g>	Create trigger on employees to verify that the manager_id is a current employee
-- ********************************************************

CREATE OR REPLACE TRIGGER check_manager_id_br_i
BEFORE INSERT ON employees
FOR EACH ROW
DECLARE
  v_manager_exists NUMBER;
BEGIN
  -- Check if the manager_id exists in the employees table
  SELECT COUNT(*)
  INTO v_manager_exists
  FROM employees
  WHERE employee_id = :NEW.manager_id;

  -- If manager_id doesn't exist, raise an exception
  IF v_manager_exists = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Invalid manager_id. The manager_id must exist as an employee_id.');
  END IF;
END;
/

-- ********************************************************
-- h>	Create procedure to create employees
-- ********************************************************

CREATE OR REPLACE PROCEDURE sp_create_employee (
  p_employee_name VARCHAR2,
  p_job_title VARCHAR2,
  p_manager_id NUMBER,
  p_date_hired DATE,
  p_salary NUMBER,
  p_department_id NUMBER
)
IS
    v_count_manger NUMBER;
BEGIN
  -- Check if the manager_id exists
  SELECT COUNT(*) INTO v_count_manger
  FROM employees
  WHERE employee_id = p_manager_id;
  
  IF v_count_manger = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Manager ID does not exist in the employees table.');
  END IF;

  -- Check if salary is negative
  IF p_salary < 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Salary cannot be negative.');
  END IF;

  -- Check if date_hired is within the specified range
  IF p_date_hired < TO_DATE('1900-01-01', 'YYYY-MM-DD') OR
     p_date_hired > ADD_MONTHS(SYSDATE, 12) THEN
    RAISE_APPLICATION_ERROR(-20003, 'Date Hired is not within the valid range.');
  END IF;

  -- Insert the employee using the employees_seq for employee_id
  INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
  VALUES (employees_seq.NEXTVAL, p_employee_name, p_job_title, p_manager_id, p_date_hired, p_salary, p_department_id);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Employee ' || p_employee_name || ' has been added.');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

-- ********************************************************
-- i>	Create proc to adjust salary
-- ********************************************************
    
CREATE OR REPLACE PROCEDURE sp_AdjustSalaryByPercentage (
  p_employee_id NUMBER,
  p_salary_adjustment_percentage NUMBER
)
IS
  v_current_salary NUMBER;
  v_new_salary NUMBER;
BEGIN
  -- Check if the employee_id exists
  BEGIN
    SELECT salary INTO v_current_salary
    FROM employees
    WHERE employee_id = p_employee_id;

    -- Check if the salary_adjustment_percentage is not 0
    IF p_salary_adjustment_percentage = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'Salary adjustment percentage cannot be 0.');
    END IF;

    -- Calculate the new salary
    v_new_salary := ROUND(v_current_salary + (v_current_salary * (p_salary_adjustment_percentage / 100)), 2);

    -- Check if the new salary is not negative
    IF v_new_salary < 0 THEN
      RAISE_APPLICATION_ERROR(-20003, 'Resulting salary cannot be negative.');
    END IF;

    -- Update the salary for the given employee_id
    UPDATE employees
    SET salary = v_new_salary
    WHERE employee_id = p_employee_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Salary for Employee ID ' || p_employee_id || ' has been adjusted to ' || v_new_salary);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Employee ID does not exist in the employees table.');
    WHEN OTHERS THEN
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
  END;
END;
/

-- ********************************************************
-- j>	Create proc to transfer employees
-- ********************************************************

CREATE OR REPLACE PROCEDURE sp_TransferEmployee (
  p_employee_id NUMBER,
  p_department_id NUMBER
)
IS
  v_employee_exists NUMBER;
  v_department_exists NUMBER;
BEGIN
  -- Check if the employee_id exists
  SELECT COUNT(*) INTO v_employee_exists
  FROM employees
  WHERE employee_id = p_employee_id;

  -- Check if the department_id exists
  SELECT COUNT(*) INTO v_department_exists
  FROM departments
  WHERE department_id = p_department_id;

  -- Raise exceptions for validation failures
  IF v_employee_exists = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Employee ID does not exist.');
  END IF;

  IF v_department_exists = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Department ID does not exist.');
  END IF;

  -- Update the employee's department
  UPDATE employees
  SET department_id = p_department_id
  WHERE employee_id = p_employee_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Employee ' || p_employee_id || ' transferred to department ' || p_department_id);
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20003, 'An error occurred: ' || SQLERRM);
END;
/

-- ********************************************************
-- k>	Function to get salary
-- ********************************************************

CREATE OR REPLACE FUNCTION f_GetEmployeeSalary (p_employee_id NUMBER)
RETURN NUMBER
IS
  v_salary NUMBER;
BEGIN
  -- Check if the employee_id exists
  SELECT salary INTO v_salary
  FROM employees
  WHERE employee_id = p_employee_id;

  IF v_salary IS NULL THEN
    RAISE_APPLICATION_ERROR(-20001, 'Employee ID does not exist in the employees table.');
  END IF;

  -- Return the employee.salary for the given employee_id
  RETURN v_salary;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL; -- Return NULL in case of an error
END;
/

-- ********************************************************
-- ********************************************************
--
-- REPORTS
--
-- ********************************************************
-- Report 1
-- ********************************************************

DECLARE
  p_department_id NUMBER := 4;  -- Specify the department_id you want to report on
  v_department_name departments.department_name%TYPE;
  v_location departments.location%TYPE;
BEGIN
  -- Get the department name and location
  SELECT department_name, location
  INTO v_department_name, v_location
  FROM departments
  WHERE department_id = p_department_id;

  -- Output the report header
  DBMS_OUTPUT.PUT_LINE('Employee Report for ' || v_department_name || ' Department');
  DBMS_OUTPUT.PUT_LINE('Location: ' || v_location);
  DBMS_OUTPUT.PUT_LINE('------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Employee Name   Job Title');
  DBMS_OUTPUT.PUT_LINE('------------------------------------');

  -- Fetch and display employee names and job titles for the specified department
  FOR emp_record IN (
    SELECT employee_name, job_title
    FROM employees
    WHERE department_id = p_department_id
  ) 
  LOOP
    DBMS_OUTPUT.PUT_LINE(RPAD(emp_record.employee_name, 20) || emp_record.job_title);
  END LOOP;  -- Corrected the loop structure
END;
/

-- ********************************************************
-- Report 2
-- ********************************************************

DECLARE
  p_department_id NUMBER := 4;  -- Specify the department_id you want to report on
  v_department_name VARCHAR2(50);
  v_location VARCHAR2(50);
  v_total_salary NUMBER;

BEGIN
  -- Get the department_name and location for the specified department
  SELECT department_name, location
  INTO v_department_name, v_location
  FROM departments
  WHERE department_id = p_department_id;

  -- Calculate the total salary for the specified department
  SELECT SUM(salary)
  INTO v_total_salary
  FROM employees
  WHERE department_id = p_department_id;

  -- Output the report header
  DBMS_OUTPUT.PUT_LINE('Salary Report for Department ' || v_department_name || ' - ' || v_location);
  DBMS_OUTPUT.PUT_LINE('--------------------------------------');

  -- Display the total salary for the department
  DBMS_OUTPUT.PUT_LINE('Total Employee Salary: $' || TO_CHAR(v_total_salary, '999,999.99'));
END;
/

-- ********************************************************
-- ********************************************************
--
-- Part 3.	TESTING
--
-- ********************************************************
-- a>	Test data load of departments
-- ********************************************************    
SELECT * FROM departments;
-- Expected result: 4 rows

-- ********************************************************
-- b>	Test data load of employees
-- ********************************************************
SELECT * FROM employees;
-- Expected result: 10 rows

-- ********************************************************
-- c>	Test trigger employees_br_i
-- ********************************************************
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (employees_seq.NEXTVAL, 'Joe Bloggs', 'Engineer', 8000, TO_DATE('23-Sep-2009', 'DD-MON-YYYY'), 28250.22, 4);

-- Expected Result: ORA-20001: Invalid manager_id. The manager_id must exist as an employee_id.
--					No row inserted

INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
VALUES (employees_seq.NEXTVAL, 'Joe Bloggs', 'Engineer', 90006, TO_DATE('23-Sep-2009', 'DD-MON-YYYY'), 28250.22, 4);
COMMIT;
-- Expect Result: One row inserted

-- ******************************
-- d>	Test procedure sp_create_employee 
-- ******************************


-- Test d1.  Expected success
-- ******************************

DECLARE
  v_employee_name VARCHAR2(50) := 'New Employee';
  v_job_title VARCHAR2(50) := 'Developer';
  v_manager_id NUMBER := 90006; 
  v_date_hired DATE := TO_DATE('2023-10-29', 'YYYY-MM-DD'); 
  v_salary NUMBER := 55000; 
  v_department_id NUMBER := 2; 

BEGIN
  -- Attempt to create the employee
  BEGIN
    sp_create_employee(
      v_employee_name,
      v_job_title,
      v_manager_id,
      v_date_hired,
      v_salary,
      v_department_id
    );

    -- If there are no errors, commit the transaction
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      -- If an error occurs, rollback the transaction
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END;

END;
/
-- Expected Result: 
-- 'Employee New Employee has been added.'
    
-- Test d2.  Expected Error - Manager ID does not exist in the employees table
-- ******************************

DECLARE
  v_employee_name VARCHAR2(50) := 'New Employee';
  v_job_title VARCHAR2(50) := 'Developer';
  v_manager_id NUMBER := 92; 
  v_date_hired DATE := TO_DATE('2023-10-29', 'YYYY-MM-DD'); 
  v_salary NUMBER := 55000; 
  v_department_id NUMBER := 2; 

BEGIN
  -- Attempt to create the employee
  BEGIN
    sp_create_employee(
      v_employee_name,
      v_job_title,
      v_manager_id,
      v_date_hired,
      v_salary,
      v_department_id
    );

    -- If there are no errors, commit the transaction
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      -- If an error occurs, rollback the transaction
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END;

END;
/
-- Expected Result: 
-- An error occurred: ORA-20001: Manager ID does not exist in the employees table.

    
-- Test d3.  Expected Error - Salary cannot be negative.
-- ******************************

DECLARE
  v_employee_name VARCHAR2(50) := 'New Employee';
  v_job_title VARCHAR2(50) := 'Developer';
  v_manager_id NUMBER := 90006; 
  v_date_hired DATE := TO_DATE('2023-10-29', 'YYYY-MM-DD'); 
  v_salary NUMBER := -55000; 
  v_department_id NUMBER := 2; 

BEGIN
  -- Attempt to create the employee
  BEGIN
    sp_create_employee(
      v_employee_name,
      v_job_title,
      v_manager_id,
      v_date_hired,
      v_salary,
      v_department_id
    );

    -- If there are no errors, commit the transaction
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      -- If an error occurs, rollback the transaction
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END;

END;
/
-- Expected Result: 
-- An error occurred: ORA-20002: Salary cannot be negative.

-- Test d4.  Expected Error - Date Hired is not within the valid range (1901/1/1 until 12 months in the future)
-- ******************************

DECLARE
  v_employee_name VARCHAR2(50) := 'New Employee';
  v_job_title VARCHAR2(50) := 'Developer';
  v_manager_id NUMBER := 90006; 
  v_date_hired DATE := TO_DATE('2025-10-29', 'YYYY-MM-DD'); 
  v_salary NUMBER := 55000; 
  v_department_id NUMBER := 2; 

BEGIN
  -- Attempt to create the employee
  BEGIN
    sp_create_employee(
      v_employee_name,
      v_job_title,
      v_manager_id,
      v_date_hired,
      v_salary,
      v_department_id
    );

    -- If there are no errors, commit the transaction
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      -- If an error occurs, rollback the transaction
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END;

END;
/
-- Expected Result: 
-- An error occurred: ORA-20003: Date Hired is not within the valid range.


-- ******************************
-- e>	Test procedure sp_AdjustSalaryByPercentage
-- ******************************


-- Test e1 - Success
-- ******************************

DECLARE
  v_employee_id NUMBER := 90006; 
  v_salary_adjustment_percentage NUMBER := 10; 

BEGIN
  -- Attempt to adjust the employee's salary
  BEGIN
    sp_AdjustSalaryByPercentage(
      v_employee_id,
      v_salary_adjustment_percentage
    );

    -- If there are no errors, commit the transaction
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      -- If an error occurs, rollback the transaction
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END;

END;
/
-- Expected Result: Salary for Employee ID 90006 has been adjusted to 49500
    
-- Test e2 - Employee ID does not exist in the employees table
-- ******************************

DECLARE
  v_employee_id NUMBER := 54; 
  v_salary_adjustment_percentage NUMBER := 10; 

BEGIN
  -- Attempt to adjust the employee's salary
  BEGIN
    sp_AdjustSalaryByPercentage(
      v_employee_id,
      v_salary_adjustment_percentage
    );

    -- If there are no errors, commit the transaction
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      -- If an error occurs, rollback the transaction
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END;

END;
/
-- Expected Result: Fail Test 2
-- Error: ORA-20001: Employee ID does not exist in the employees table.
    
-- Test e3- Fail - Salary adjustment percentage cannot be 0.
-- ******************************

DECLARE
  v_employee_id NUMBER := 90006; 
  v_salary_adjustment_percentage NUMBER := 0; 

BEGIN
  -- Attempt to adjust the employee's salary
  BEGIN
    sp_AdjustSalaryByPercentage(
      v_employee_id,
      v_salary_adjustment_percentage
    );

    -- If there are no errors, commit the transaction
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      -- If an error occurs, rollback the transaction
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END;

END;
/
-- Expected Result: Fail Test 3
-- An error occurred: ORA-20002: Salary adjustment percentage cannot be 0.
    
-- Test e4 - Fail - Resulting salary cannot be negative.
-- ******************************

DECLARE
  v_employee_id NUMBER := 90006; 
  v_salary_adjustment_percentage NUMBER := -200; 

BEGIN
  -- Attempt to adjust the employee's salary
  BEGIN
    sp_AdjustSalaryByPercentage(
      v_employee_id,
      v_salary_adjustment_percentage
    );

    -- If there are no errors, commit the transaction
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      -- If an error occurs, rollback the transaction
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END;

END;
/

-- Expected Result: Fail Test 4
-- An error occurred: ORA-20003: Resulting salary cannot be negative.


-- ******************************
-- f>	Test sp_TransferEmployee
-- ******************************
-- Test f1 - Success
-- ******************************

DECLARE
  v_employee_id NUMBER := 90002; 
  v_department_id NUMBER := 3;    

BEGIN
  -- Attempt to transfer the employee
  sp_TransferEmployee(
    v_employee_id,
    v_department_id
  );

  -- If there are no errors, commit the transaction
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Employee transferred successfully.');

EXCEPTION
  WHEN OTHERS THEN
    -- If an error occurs, rollback the transaction
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
-- Expected Result: 
-- Employee 90002 transferred to Department 3
-- Employee transferred successfully.


-- Test f2 - Fail, bad department
-- ******************************

DECLARE
  v_employee_id NUMBER := 90002; 
  v_department_id NUMBER := 52;    

BEGIN
  -- Attempt to transfer the employee
  sp_TransferEmployee(
    v_employee_id,
    v_department_id
  );

  -- If there are no errors, commit the transaction
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Employee transferred successfully.');

EXCEPTION
  WHEN OTHERS THEN
    -- If an error occurs, rollback the transaction
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
-- Expected Result: 
-- Error: ORA-20003: An error occurred: ORA-20002: Department ID does not exist.

-- Test f3 - Fail, bad employee
-- ******************************

DECLARE
  v_employee_id NUMBER := 67; 
  v_department_id NUMBER := 3;    

BEGIN
  -- Attempt to transfer the employee
  sp_TransferEmployee(
    v_employee_id,
    v_department_id
  );

  -- If there are no errors, commit the transaction
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Employee transferred successfully.');

EXCEPTION
  WHEN OTHERS THEN
    -- If an error occurs, rollback the transaction
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
-- Expected Result: 
-- Error: ORA-20003: An error occurred: ORA-20001: Employee ID does not exist.
-- ******************************
-- Test g>	f_GetEmployeeSalary 
-- ******************************

-- Test g1 - Success
-- ******************************

DECLARE
  v_employee_id NUMBER := 90001; 
  v_salary NUMBER; 
BEGIN
  -- Call the function to retrieve the employee's salary
  v_salary := f_GetEmployeeSalary(v_employee_id);

  -- Check if the salary is valid (not null or negative)
  IF v_salary IS NULL OR v_salary < 0 THEN
    DBMS_OUTPUT.PUT_LINE('Error: Invalid salary value');
  ELSE
    -- Display the retrieved salary
    DBMS_OUTPUT.PUT_LINE('Employee ID ' || v_employee_id || ' has a salary of $' || TO_CHAR(v_salary, '999,999.99'));
  END IF;
END;
/
   
-- Expected Result: 
-- Employee ID 90001 has a salary of $ 100,000.00

-- Test g2 - Fail, bad employee number
-- ******************************

DECLARE
  v_employee_id NUMBER := 34; 
  v_salary NUMBER; 
BEGIN
  -- Call the function to retrieve the employee's salary
  v_salary := f_GetEmployeeSalary(v_employee_id);

  -- Check if the salary is valid (not null or negative)
  IF v_salary IS NULL OR v_salary < 0 THEN
    DBMS_OUTPUT.PUT_LINE('Error: Invalid salary value');
  ELSE
    -- Display the retrieved salary
    DBMS_OUTPUT.PUT_LINE('Employee ID ' || v_employee_id || ' has a salary of $' || TO_CHAR(v_salary, '999,999.99'));
  END IF;
END;
/
-- Expected Result: 
--Error: Invalid salary value

--** TESTING COMPLETE






