# Project Management Database

This project aims to create a relational database to manage projects for an IT company. The database includes information about clients, projects, tasks, and employees, and offers features to register, update, and monitor the progress of projects and tasks.

## Database Structure

The database was built using MySQL and contains the following tables:

- **Client**: Stores information about the company's clients.
- **Employee**: Contains data about the company's employees.
- **Project**: Stores information about projects done for clients.
- **Task**: Contains tasks assigned to employees in each project.
- **Project_log**: Logs changes made to projects.
- **Task_log**: Logs changes made to tasks.

## Features

### Tables

The tables created for managing the data are as follows:

1. **Client**: Contains information about the company's clients.
   - Fields: `ID_client`, `client_name`, `status`

2. **Employee**: Contains information about the company's employees.
   - Fields: `ID_employee`, `employee_name`, `email`, `role`

3. **Project**: Stores information about the projects.
   - Fields: `ID_project`, `project_name`, `ID_client`, `description`, `start_date`, `end_date`, `status`, `progress`, `PM`, `price`

4. **Task**: Stores information about tasks assigned to employees.
   - Fields: `ID_task`, `task_name`, `ID_project`, `start_date`, `end_date`, `status`, `priority`, `employee`

5. **Project_log**: Logs changes made to projects.
   - Fields: `ID_projectlog`, `modification`, `Date`, `userName`

6. **Task_log**: Logs changes made to tasks.
   - Fields: `ID_tasklog`, `modification`, `Date`, `userName`

### Indexes

- **project_idx**: Unique index on the `Project` table based on the project name.
- **task_project**: Composite index on the `Task` table (with `ID_project` and `task_name`).

### Triggers

- **StatusDelay**: Updates the task status to "Late" when the end date is passed, and the task is not completed.
- **AfterUpdateProject**: Logs changes made to projects.
- **AfterUpdateTask**: Logs changes made to tasks.
- **ChangeStatusProject**: Updates the project status to "Done" when all tasks associated with the project are completed.
- **ProgressInsert**: Updates the project progress when a new task is inserted.
- **ProgressUpdate**: Updates the project progress when an existing task is modified.

### Functions

- **ProjectDuration**: Calculates and returns the duration of a project in months and days.
- **PendingTasks**: Returns the number of pending tasks for a specific project.
- **RemainingTime**: Calculates the remaining time to complete a task.

### Procedures

- **AddClient**: Adds a new client.
- **AddEmployee**: Adds a new employee.
- **AddProject**: Adds a new project.
- **AddTask**: Adds a new task.
- **Task_Done**: Marks a task as completed.
- **Delete_Project**: Deletes a project and its associated tasks.
- **Tasks_Employee**: Lists tasks assigned to a specific employee.
- **UpdateProject**: Updates information about a project.
- **UpdateTask**: Updates information about a task.
- **totalTasks**: Displays the total number of tasks for each employee.

## How to Run

1. **Prerequisites**: 
   - MySQL installed on your machine.
   - Access to the database and permission to create tables and procedures.

2. **Steps to run the project**:
   - Clone the repository:
     ```bash
     git clone https://github.com/your-username/project-management-database.git
     cd project-management-database
     ```
   - Execute the database creation script (`create_database.sql`) on your MySQL server.
   - You can use the MySQL client or a tool like MySQL Workbench to run the script.

3. **Example usage**:
   - Add new clients, projects, and tasks using the procedures `AddClient`, `AddProject`, `AddTask`, etc.
   - Use functions like `ProjectDuration`, `PendingTasks`, and `RemainingTime` to get detailed information about projects and tasks.


## Contributions

Feel free to submit contributions or suggestions for improvements to the project!
