CREATE DATABASE DBCRUDCORE;

USE DBCRUDCORE;

CREATE TABLE T_STATUS (
    IdStatus INT PRIMARY KEY IDENTITY(1,1),
    Status VARCHAR(10) CHECK (Status IN ('A', 'I')),
    Description VARCHAR(100),
    UserCreation VARCHAR(100),
    DateCreation DATETIME,
    UserModification VARCHAR(100),
    DateModification DATETIME
);

INSERT INTO T_STATUS (Status, Description, UserCreation, DateCreation)
VALUES ('A', 'Activated', SUSER_SNAME(), GETDATE()), ('I', 'Inactivated', SUSER_SNAME(), GETDATE());

CREATE TABLE T_USERS (
    IdUser INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    Username VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    Pass VARCHAR(500),
    IdStatus INT,
    UserCreation VARCHAR(100),
    DateCreation DATETIME,
    UserModification VARCHAR(100),
    DateModification DATETIME,
    FOREIGN KEY (IdStatus) REFERENCES T_STATUS(IdStatus)
);

CREATE TABLE T_AUDIT_LOG (
    IdAuditLog INT PRIMARY KEY IDENTITY(1,1),
    IdUser INT,
    AuditType VARCHAR(50),
    AuditDate DATETIME,
    UserName VARCHAR(100),
);

CREATE PROC sp_CreateUser(
    @FirstName VARCHAR(100),
    @LastName VARCHAR(100),
    @Username VARCHAR(100),
    @Email VARCHAR(100),
    @Pass VARCHAR(500),
    @Register BIT OUTPUT,
    @Message VARCHAR(100) OUTPUT
)
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM T_USERS WHERE Email = @Email)
    BEGIN
        DECLARE @IdUser INT;

        INSERT INTO T_USERS (FirstName, LastName, Username, Email, Pass, IdStatus, UserCreation, DateCreation)
        VALUES (@FirstName, @LastName, @Username, @Email, @Pass, 1, SUSER_SNAME(), GETDATE());

        SET @IdUser = SCOPE_IDENTITY();

        INSERT INTO T_AUDIT_LOG (IdUser, AuditType, AuditDate, UserName)
        VALUES (@IdUser, 'create', GETDATE(), SUSER_SNAME());

        SET @Register = 1;
        SET @Message = 'registered user';
    END
    ELSE
    BEGIN
        SET @Register = 0;
        SET @Message = 'mail already exists';
    END
END;


CREATE PROC sp_ValidateUser(
    @Email VARCHAR(100),
    @Pass VARCHAR(500)
)
AS
BEGIN
    IF EXISTS (SELECT * FROM T_USERS WHERE Email = @Email AND Pass = @Pass AND IdStatus = 1)
    BEGIN
 SELECT IdUser FROM T_USERS WHERE Email = @Email AND Pass = @Pass AND IdStatus = 1;
    END
    ELSE
    BEGIN
        SELECT '0' AS IdUser;
    END
END;



CREATE PROC sp_Read(
    @IdUser INT,
    @Singin VARCHAR(100)
)
AS
BEGIN
    SELECT * FROM T_USERS WHERE IdUser = @IdUser;

    INSERT INTO T_AUDIT_LOG (IdUser, AuditType, AuditDate, UserName)
    VALUES (@IdUser, 'read', GETDATE(), @Singin);
END;



CREATE PROC sp_Edit(
    @IdUser INT,
    @FirstName VARCHAR(100),
    @LastName VARCHAR(100),
    @Username VARCHAR(100),
    @Email VARCHAR(100),
    @Pass VARCHAR(500),
    @Singin VARCHAR(100)
)
AS
BEGIN
    UPDATE T_USERS
    SET FirstName = @FirstName,
        LastName = @LastName,
        Username = @Username,
        Email = @Email,
        Pass = @Pass,
        UserModification = SUSER_SNAME(),
        DateModification = GETDATE()
    WHERE IdUser = @IdUser;

    INSERT INTO T_AUDIT_LOG (IdUser, AuditType, AuditDate, UserName)
    VALUES (@IdUser, 'edit', GETDATE(), @Singin);
END;



CREATE PROC sp_Remove(
    @IdUser INT,
    @Singin VARCHAR(100)
)
AS
BEGIN
    DELETE FROM T_USERS WHERE IdUser = @IdUser;

    INSERT INTO T_AUDIT_LOG (IdUser, AuditType, AuditDate, UserName)
    VALUES (@IdUser, 'remove', GETDATE(), @Singin);
END;



CREATE PROC sp_GetAuditLogs(
    @PageSize INT,
    @PageNumber INT
)
AS
BEGIN
    SELECT * FROM T_AUDIT_LOG
    ORDER BY AuditDate ASC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;




-- EXAMPLES

-- Create a new user
DECLARE @FirstName VARCHAR(100) = 'Alejandra';
DECLARE @LastName VARCHAR(100) = 'Linares';
DECLARE @Username VARCHAR(100) = 'ale478';
DECLARE @Email VARCHAR(100) = 'ale@gmail.com';
DECLARE @Pass VARCHAR(500) = 'a62039e2dd75ceffa3b72c632010c53a';
DECLARE @Register BIT;
DECLARE @Message VARCHAR(100);

EXEC sp_CreateUser @FirstName, @LastName,Username, @Email, @Pass, @Register OUTPUT, @Message OUTPUT;

SELECT @Register AS Registered, @Message AS Message;

-- Validate user
EXEC sp_ValidateUser 'ale@gmail.com', 'a62039e2dd75ceffa3b72c632010c53a';

-- Read user
DECLARE @IdUser INT = 1;
DECLARE @Singin VARCHAR(100) = SUSER_SNAME();

EXEC sp_Read @IdUser, @Singin;

-- Update user
DECLARE @FirstName VARCHAR(100) = 'Alejandra Updated';
DECLARE @LastName VARCHAR(100) = 'Linares Updated';
DECLARE @Username VARCHAR(100) = 'ale478 Updated';
DECLARE @Email VARCHAR(100) = 'ale@gmail.com Updated';
DECLARE @Pass VARCHAR(500) = 'a62039e2dd75ceffa3b72c632010c53a Updated';
DECLARE @Singin VARCHAR(100) = SUSER_SNAME();

EXEC sp_Edit @IdUser, @FirstName, @LastName, @Username, @Email, @Pass, @Singin;

-- Delete user
DECLARE @IdUser INT = 1;
DECLARE @Singin VARCHAR(100) = SUSER_SNAME();

EXEC sp_Remove @IdUser, @Singin;

-- Display audit logs
DECLARE @PageSize INT = 10;
DECLARE @PageNumber INT = 1;

EXEC sp_GetAuditLogs @PageSize, @PageNumber;

-- Display status legend
SELECT Status, Description
FROM T_STATUS;


DELETE FROM T_USERS Where IdUser = 1
