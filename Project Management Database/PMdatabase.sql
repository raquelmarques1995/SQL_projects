-- O Objectivo é construir uma database que permita controlar os projectos de uma determinada empresa de IT e as tasks que definidas para cada projecto
-- Para isso foram criadas 4 tabelas (Client, Project, Task, Employee)

-- *** Criação da Base de dados ***
CREATE DATABASE ProjectManagement;

use ProjectManagement;

SHOW TABLES;
SHOW TRIGGERS; 
SHOW function status where db="ProjectManagement";
SHOW procedure status;

DROP TABLE Project;
DROP TABLE Task;

SELECT * FROM Project_log;
SELECT * FROM Task_log;
SELECT * FROM Project;
SELECT * FROM Task;
SELECT * FROM Client;
SELECT * FROM Employee;

TRUNCATE table Task;



-- *** Criação das Tabelas ***
CREATE TABLE Client (ID_client int not null auto_increment primary key, client_name varchar(50) not null, status ENUM('Class A', 'Class B', 'Class C') not null);

CREATE TABLE Employee(ID_employee int not null auto_increment primary key, employee_name varchar(50), email varchar(100), role varchar(50));

CREATE TABLE Project (ID_project int not null auto_increment primary key, project_name varchar(50) not null, ID_client int not null, description varchar(2000),start_date date, end_date date,
status ENUM('Done', 'In progress', 'Pending', 'Canceled', 'Late') not null, progress decimal(6,2) default 0, PM int not null, price decimal (10,2),
foreign key (ID_client) references Client(ID_client), foreign key (PM) references Employee(ID_employee));

CREATE TABLE Task (ID_task int not null auto_increment primary key, task_name varchar(50) not null, ID_project int not null ,start_date date, end_date date,
status ENUM('Done', 'In progress', 'Pending', 'Canceled', 'Late') not null, priority ENUM('High', 'Normal', 'Low') not null, employee int not null,
foreign key (ID_project) references Project (ID_project), foreign key (employee) references Employee(ID_employee));

CREATE TABLE Project_log (ID_projectlog int not null, modification varchar(200), Date datetime default now(), userName varchar(300));

CREATE TABLE Task_log (ID_tasklog int not null, modification varchar(200), Date datetime default now(), userName varchar(300));


-- *** Criação dos Índices *** 
	-- Considerou-se pretinente criar dois indices, um associado ao projecto e outro um índice composto que combina o projecto e a tarefa
CREATE UNIQUE INDEX project_idx on Project(project_name);
CREATE UNIQUE INDEX task_project on Task(ID_project,task_name);


-- *** TRIGGERS ***

-- ** Trigger que dá um alerta sempre que uma tarefa se encontra atrasada
		delimiter $$
		CREATE TRIGGER StatusDelay
		BEFORE UPDATE ON Task
		FOR EACH ROW
		begin
		 IF New.end_date < current_date() and New.status <> 'Done' THEN
			SET New.status = 'Late';
		 END IF;
		END $$
		delimiter ;

-- **Triggers para a registar as alterações feitas através dos updates nas tabelas Project e Task
		delimiter $$
		CREATE TRIGGER AfterUpdateProject
		After update on Project for each row
		BEGIN
			DECLARE modif varchar(200);
			SET modif = concat_ws(';', New.project_name, New.start_date, New.end_date, New.status, New.progress, New.PM, New.price, 'UPDATED');
			INSERT INTO Project_log (ID_projectlog, modification, userName) 
			values (New.ID_project, modif,user());
		END $$
		delimiter ;

		delimiter $$
		CREATE TRIGGER AfterUpdateTask
		After update on Task 
		For each row
		BEGIN
			DECLARE modif varchar(200);
			SET modif = concat_ws(';', New.task_name, New.start_date, New.end_date, New.status, New.priority, New.employee, 'UPDATED');
			INSERT INTO Task_log (ID_tasklog, modification, userName) values (New.ID_task, modif,user());
		END $$
		delimiter ;
        

-- DROP TRIGGER ChangeStatusProject;
-- **Trigger para atualização do estado do projecto
		delimiter $$
		CREATE TRIGGER ChangeStatusProject
		After update on Task
		For each row
		BEGIN
			-- caso não exista 1 tarefa com um status diferente de 'Done' faz update do status do projecto
			IF NOT EXISTS(SELECT 1 FROM Task WHERE ID_project = New.ID_project and status <>'Done') THEN 
				update Project 
				SET 
					status = 'Done',
                    end_date = current_date()
				WHERE ID_project = New.ID_project;
			END IF;
		END $$
		delimiter ;


-- DROP TRIGGER ProgressInsert;
-- DROP TRIGGER ProgressUpdate;

-- **Trigger para atualizar o campo Progress caso a tarefa inserida esteja já com o status 'Done'
		DELIMITER $$
		CREATE TRIGGER ProgressInsert
		AFTER INSERT ON Task
		FOR EACH ROW
		BEGIN
			DECLARE total INT;
			DECLARE done INT;
			DECLARE progress DECIMAL(6,2);
			
			-- Calcular o total e concluídas
			SELECT COUNT(*) INTO total FROM Task WHERE ID_project = New.ID_project;
			SELECT COUNT(*) INTO done FROM Task WHERE ID_project = New.ID_project AND status = 'Done';
			
			-- Calcular progresso
			IF total > 0 THEN
				SET progress = ROUND((done / total) * 100, 2);
			ELSE
				SET progress = 0;
			END IF;
            
            UPDATE Project
            SET progress = progress
            WHERE ID_project = New.ID_project;
		END$$
		DELIMITER ;


-- **Trigger para atualizar o campo Progress no caso de fazer update à tabela
		DELIMITER $$
		CREATE TRIGGER ProgressUpdate
		AFTER Update ON Task
		FOR EACH ROW
        BEGIN
			DECLARE total INT;
			DECLARE done INT;
			DECLARE progress DECIMAL(6,2);
			
			-- Calcular o total e concluídas
			SELECT COUNT(*) INTO total FROM Task WHERE ID_project = New.ID_project;
			SELECT COUNT(*) INTO done FROM Task WHERE ID_project = New.ID_project AND status = 'Done';
			
			-- Calcular progresso
			IF total > 0 THEN
				SET progress = ROUND((done / total) * 100, 2);
			ELSE
				SET progress = 0;
			END IF;
            
            UPDATE Project
            SET progress = progress
            WHERE ID_project = New.ID_project;
		END$$
		DELIMITER ;
        

-- *** FUNCTIONS ***

-- DROP FUNCTION ProjectDuration;
-- ** Function para cálculo do nº de dias do projecto
        DELIMITER $$
        CREATE FUNCTION ProjectDuration (IDproject INT)
		RETURNS VARCHAR(50)
		DETERMINISTIC
		BEGIN
			DECLARE startDate date;
			DECLARE endDate date;
			DECLARE months INT;
			DECLARE days INT;
			DECLARE projectDuration VARCHAR(50);

			-- Obtém as datas de início e fim do projeto
			SELECT start_date, end_date INTO startDate, endDate FROM Project WHERE ID_project = IDproject;

			-- Calcula a diferença em meses
			SET months = TIMESTAMPDIFF(MONTH, startDate, endDate);
			
			-- Calcula a diferença em dias da data de fim do projecto com a data de inicio mais os meses guardados na variável months (interval months month)
			SET days = DATEDIFF(endDate, DATE_ADD(startDate, INTERVAL months MONTH));

			-- Concatena os resultados em um formato "X meses Y dias"
			SET projectDuration = CONCAT(months, ' meses e ', days, ' dias');

			-- Retorna o resultado
			RETURN projectDuration;
		END$$
		DELIMITER ;

-- DROP FUNCTION PendingTasks;
-- **Function para o cálculo de nº de tasks pending de determinado projeto**
		delimiter $$
		CREATE FUNCTION PendingTasks (IDproject INT)
		RETURNS VARCHAR(50)
		DETERMINISTIC
		BEGIN
			DECLARE pendingTasks int;
            SELECT count(*) into pendingTasks FROM Task Where status = 'Pending' AND ID_project = IDproject;
			Return(concat(pendingTasks, ' task(s)'));
		END$$
		delimiter ;

DROP FUNCTION RemainingTime;
-- **Function para calcular o tempo restante para concluir uma tarefa																																															delimiter $$
		delimiter $$
        CREATE FUNCTION RemainingTime (IDtask INT)
		RETURNS VARCHAR(50)
		DETERMINISTIC
		BEGIN
			DECLARE remaining_days int;
            SELECT DATEDIFF(end_date, current_date) INTO remaining_days
            FROM Task Where ID_task = IDtask;
            Return concat(remaining_days, ' days to finish the task ', IDtask);
		END $$
		delimiter ;


-- *** PROCEDURES ***

-- DROP PROCEDURE AddClient;
-- ** Adicionar novo cliente
		delimiter $$
		CREATE PROCEDURE AddClient (in client_name varchar(50), in status Enum('Class A', 'Class B', 'Class C'))
		BEGIN
			INSERT INTO Client(client_name, status)
			VALUES (client_name, status);
		END $$
		delimiter ;


-- DROP PROCEDURE AddProject;
-- **Adicionar novo project
		delimiter $$
		CREATE PROCEDURE AddProject (in project_name varchar(50), in ID_client int, in description varchar(2000), in start_date date, in end_date date, in status Enum('Done', 'In progress', 'Pending', 'Canceled', 'Late'), in PM int, in price decimal (6,2))
		BEGIN
			INSERT INTO Project(project_name, ID_client, description, start_date, end_date, status, PM, price)
			VALUES (project_name, ID_client, description, start_date, end_date, status, PM, price);
		END $$
		delimiter ;


-- DROP PROCEDURE AddTask;
-- **Adicionar nova tarefa
		delimiter $$
		CREATE PROCEDURE AddTask (in task_name varchar(50), in ID_project int, in start_date date, in end_date date, in status Enum('Done', 'In progress', 'Pending', 'Canceled'), in priority ENUM('High', 'Normal', 'Low'), in employee int)
		BEGIN
			INSERT INTO Task (task_name, ID_project, start_date, end_date, status, priority, employee)
			VALUES (task_name, ID_project, start_date, end_date, status, priority, employee);
		END $$
		delimiter ;


-- DROP PROCEDURE AddEmployee;
-- ** Adicionar novo Colaborador
		delimiter $$
		CREATE PROCEDURE AddEmployee (in employee_name varchar(50), in email varchar(100), role varchar(20))
		BEGIN
			INSERT INTO Employee(employee_name, email, role)
			VALUES (employee_name, email, role);
		END $$
		delimiter ;

-- DROP PROCEDURE Task_Done;
-- ** Marcar tarefa como concluída
		delimiter $$
		CREATE PROCEDURE Task_Done (in IDtask int, in endDate date)
		BEGIN
			UPDATE Task
			SET status ='Done', end_date = endDate
			WHERE ID_task = IDtask;
		END $$
		delimiter ;


DROP PROCEDURE Delete_Project;
-- ** Eliminar projectos e as respetivas tarefas
		delimiter $$
		CREATE PROCEDURE Delete_Project (in IDproject int)
		BEGIN
			DELETE From Task where ID_project = IDproject;
			DELETE From Project where ID_project = IDproject;
		END$$
		delimiter ;


-- DROP PROCEDURE Tasks_Employee;
-- ** Listar tarefas de um employee especifico
		delimiter $$
		CREATE PROCEDURE Tasks_Employee (in IDemployee int)
		BEGIN
			SELECT task_name, start_date, end_date, status, priority
            FROM Task
			WHERE employee = IDemployee;
		END$$
		delimiter ;
   
-- Procedure que permite fazer a atualização de uma task sem ter de mencionar todos os campos da tabela. Aqueles que não queremos alterar devem ser preenchidos como NULL para manter o valor que já existe na tabela  
		DELIMITER $$
		CREATE PROCEDURE UpdateTask( IN taskID INT, IN newTaskName VARCHAR(50), IN newStartDate DATE, IN newEndDate DATE, 
		IN newStatus ENUM('Done', 'In progress', 'Pending', 'Late', 'Canceled'), IN newPriority ENUM('High', 'Normal', 'Low'), IN newEmployee INT)
		BEGIN
			-- Atualiza apenas os campos fornecidos (não nulos)
			UPDATE Task
			SET 
				task_name = COALESCE(newTaskName, task_name),
				start_date = COALESCE(newStartDate, start_date),
				end_date = COALESCE(newEndDate, end_date),
				status = COALESCE(newStatus, status),
				priority = COALESCE(newPriority, priority),
				employee = COALESCE(newEmployee, employee)
			WHERE ID_task = taskID;
		END$$
		DELIMITER ;
        
 DROP PROCEDURE UpdateProject;
-- Procedure que permite fazer a atualização de um project sem ter de mencionar todos os campos da tabela. Aqueles que não queremos alterar devem ser preenchidos como NULL para manter o valor que já existe na tabela  
		DELIMITER $$
		CREATE PROCEDURE UpdateProject( IN projectID INT, IN newProjectName VARCHAR(50), IN newClientID INT, IN newStartDate DATE, IN newEndDate DATE, 
		IN newStatus ENUM('Done', 'In progress', 'Pending', 'Canceled', 'Late'), IN newPM INT, IN newPrice DECIMAL)
		BEGIN
			-- Atualiza apenas os campos fornecidos (não nulos)
			UPDATE Project
			SET 
				project_name = COALESCE(newProjectName, project_name),
                ID_client = COALESCE(newClientID, ID_client),
				start_date = COALESCE(newStartDate, start_date),
				end_date = COALESCE(newEndDate, end_date),
				status = COALESCE(newStatus, status),
				PM = COALESCE(newPM, PM),
				price = COALESCE(newPrice, price)
			WHERE ID_project = projectID;
		END$$
		DELIMITER ;

-- DROP PROCEDURE totalTasks;
-- ** Criar uma view para mostrar o nº de tarefas por colaborador
		delimiter $$
		CREATE PROCEDURE totalTasks()
		BEGIN
			SELECT employee_name AS Employee, count(*) AS totalTasks
			FROM Task
            inner join Employee on Task.employee = Employee.ID_employee
			Group by employee
			Order by totalTasks desc;
		END $$
        delimiter ;


-- *** Inserir dados ***
	-- 'client_name', status ('Class A', 'Class B', 'Class C')
CALL AddClient ('Tech Innovations', 'Class A');
CALL AddClient ('Green Energy Solutions', 'Class B');
CALL AddClient ('HealthTech Ltd.', 'Class A');
CALL AddClient ('BuildSmart Inc.', 'Class C');
CALL AddClient ('EduLearn Systems', 'Class B');
CALL AddClient('InnoProject Solutions', 'Class C');

	-- 'employee_name', 'email', 'role'
CALL AddEmployee ('Alice Martins', 'alice.martins@empresa.com', 'Project Manager');
CALL AddEmployee ('Carlos Silva', 'carlos.silva@empresa.com', 'Developer');
CALL AddEmployee ('Beatriz Costa', 'beatriz.costa@empresa.com', 'Tester');
CALL AddEmployee ('Ricardo Mendes', 'ricardo.mendes@empresa.com', 'Designer');
CALL AddEmployee('Joana Figueiredo', 'joana.figueiredo@empresa.com', 'Team Lead');
CALL AddEmployee('Raquel Marques', 'raquel.marques@empresa.com', 'Project Manager');

	-- 'project_name', ID_client, 'description', 'start_date', 'end_date', status ('Done', 'In progress', 'Canceled'),PM, price
CALL AddProject ('Plataforma de Gestão de Recursos Humanos', 6, 'Desenvolvimento de uma plataforma para gerir recursos humanos da empresa', '2024-10-17', '2024-12-03', 'In progress', 1, 1200.00);
CALL AddProject ('Plataforma E-commerce Verde', 2, 'CriaÃ§Ã£o de uma plataforma de e-commerce para produtos sustentÃ¡veis.', '2024-02-01', '2024-09-15', 'In progress', 1, 1500.00);
CALL AddProject ('Sistema de Gestão Escolar', 1, 'Desenvolvimento de um sistema completo para escolas.', '2024-01-10', '2024-06-20', 'In progress', 1, 1000.00);
CALL AddProject ('App de Saúde', 3, 'Aplicação para gestão de saúde pessoal.', '2024-03-01', '2024-08-30', 'In progress', 6, 2000.00);
CALL AddProject ('Design de Marca BuildSmart', 4, 'Projeto para redesenho da identidade visual.', '2024-04-05', '2024-05-20', 'In progress', 6, 5000.00);
CALL AddProject ('Portal de Aprendizagem', 5, 'Portal para cursos online e gestão de estudantes.', '2024-05-01', '2024-11-15', 'In progress', 1, 1200.00);
CALL AddProject ('Plataforma de Gestão de Projectos', 6, 'Desenvolvimento de uma plataforma para gerir os projectos da empresa', '2024-10-17', '2024-12-03', 'In progress', 1, 1200.00);

SELECT * FROM Project;

	-- projectID, 'newProjectName', newClientID, 'newStartDate', 'newEndDate', newStatus('Done', 'In progress', 'Pending', 'Canceled', 'Late'),newPM, newPrice
CALL UpdateProject(5, NULL, NULL, '2025-01-02', '2025-02-14', 'Pending',NULL,NULL);

-- 'task_name', ID_project, 'start_date', 'end_date', status ('Done', 'In progress', 'Pending', 'Canceled'), priority ('High', 'Normal', 'Low'),employee
CALL AddTask ('Análise de Requisitos', 1, '2024-01-10', '2024-01-25', 'Done', 'High', 1);
CALL AddTask ('Desenvolvimento do Backend', 1, '2024-01-26', '2024-03-15', 'In progress', 'High', 2);
CALL AddTask ('Testes Iniciais', 1, '2024-03-16', '2024-04-10', 'Pending', 'Normal', 3);
CALL AddTask ('Planejamento do Design', 4, '2024-04-05', '2024-04-15', 'Done', 'High', 4);
CALL AddTask ('Criação de Propostas Visuais', 4, '2024-04-16', '2024-04-30', 'In progress', 'High', 4);
CALL AddTask ('Aprovação pelo Cliente', 4, '2024-05-01', '2024-05-05', 'Pending', 'Normal', 1);
CALL AddTask ('Definição de Funcionalidades', 3, '2024-03-01', '2024-03-10', 'Done', 'High', 1);
CALL AddTask ('Protótipo Inicial', 3, '2024-03-11', '2024-04-01', 'In progress', 'Normal', 2);
CALL AddTask ('Testes de Aceitação', 3, '2024-04-02', '2024-04-20', 'Pending', 'Normal', 3);
CALL AddTask ('Reunião com Cliente', 5, '2025-01-02', '2025-01-02', 'Pending', 'High',6);
CALL AddTask ('Reunião final com Cliente', 1, '2024-11-24', '2025-11-24', 'In progress', 'High',6);


CALL Tasks_Employee (3);
CALL totalTasks();

SELECT * FROM Project;
SELECT * FROM Task;
CALL Task_Done (2,'2024-03-15');
CALL Task_Done (3,'2024-04-10');
CALL Task_Done (11,'2024-11-28');

-- taskID, 'newTaskName', 'newStartDate', 'newEndDate', newStatus ('Done', 'In progress', 'Pending', 'Late', 'Canceled'), newPriority ('High', 'Normal', 'Low')newEmployee
CALL UpdateTask(8, NULL, '2024-11-21', '2024-11-26', NULL, NULL, NULL);
CALL UpdateTask(9, NULL, '2024-11-28', '2024-12-04',NULL, NULL, NULL);

CALL totalTasks();

-- DELETE DO Projecto com o ID 4 para teste (App de Saúde), tem as tarefas 4, 5 e 6
CALL Delete_Project(4);

SELECT RemainingTime(2) AS RemainingDays;
SELECT PendingTasks (5) AS PendingTasks;
SELECT ProjectDuration (3) AS ProjectDuration;

SELECT * FROM Project_log;
SELECT * FROM Task_log;