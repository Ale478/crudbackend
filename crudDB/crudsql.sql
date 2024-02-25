CREATE DATABASE DBCRUDCORE;

USE DBCRUDCORE;

CREATE TABLE T_STATUS (
    IdStatus INT PRIMARY KEY IDENTITY(1,1),
    StatusName VARCHAR(10) CHECK (StatusName IN ('A', 'I')),
    StatusDescription VARCHAR(100),
    UserCreation VARCHAR(100),
    DateCreation DATETIME,
    UserModification VARCHAR(100),
    DateModification DATETIME
);

INSERT INTO T_STATUS (StatusName, StatusDescription, UserCreation, DateCreation)
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
    @Status VARCHAR(10),
    @Register BIT OUTPUT,
    @Message VARCHAR(100) OUTPUT
)
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM T_USERS WHERE Email = @Email)
    BEGIN
        DECLARE @IdStatus INT;
		DECLARE @IdUser INT;

        IF (@Status = 'A')
        BEGIN
            SET @IdStatus = 1;
        END
        ELSE IF (@Status = 'I')
        BEGIN
            SET @IdStatus = 2;
        END
        ELSE
        BEGIN
            SET @IdStatus = NULL;
        END

        IF (@IdStatus IS NOT NULL)
        BEGIN
            INSERT INTO T_USERS (FirstName, LastName, Username, Email, Pass, IdStatus, UserCreation, DateCreation)
            VALUES (@FirstName, @LastName, @Username, @Email, @Pass, @IdStatus,@Username, GETDATE());

            SET @IdUser = SCOPE_IDENTITY();

            INSERT INTO T_AUDIT_LOG (IdUser, AuditType, AuditDate, UserName)
            VALUES (@IdUser, 'create', GETDATE(), (SELECT Username FROM T_USERS WHERE IdUser = @IdUser));

            SET @Register = 1;
            SET @Message = 'registered user';

            UPDATE T_USERS
            SET UserModification = @Username,
                DateModification = GETDATE()
            WHERE IdUser = @IdUser;

            UPDATE T_STATUS
            SET UserModification = @Username,
                DateModification = GETDATE()
            WHERE IdStatus = @IdStatus;
        END
        ELSE
        BEGIN
            SET @Register = 0;
            SET @Message = 'invalid status';
        END
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
    DECLARE @IdUser INT;

    SELECT @IdUser = IdUser FROM T_USERS WHERE Email = @Email AND Pass = @Pass AND IdStatus = 1;

    IF @IdUser IS NOT NULL
    BEGIN
        SELECT @IdUser AS IdUser;

        INSERT INTO T_AUDIT_LOG (IdUser, AuditType, AuditDate, UserName)
        VALUES (@IdUser, 'validate', GETDATE(), (SELECT Username FROM T_USERS WHERE IdUser = @IdUser));
    END
    ELSE
    BEGIN
        SELECT '0' AS IdUser;
    END
END;



CREATE PROC sp_ReadUser(
    @IdUser INT,
    @Singin VARCHAR(100)
)
AS
BEGIN
    DECLARE @Username VARCHAR(100);

    SELECT @Username = Username FROM T_USERS WHERE IdUser = @IdUser;

    SELECT U.IdUser, U.FirstName, U.LastName, U.Username, U.Email, S.StatusName, U.UserModification, U.DateModification, S.UserModification AS StatusUserModification, S.DateModification AS StatusDateModification
    FROM T_USERS U
    INNER JOIN T_STATUS S ON U.IdStatus = S.IdStatus
    WHERE IdUser = @IdUser;

    INSERT INTO T_AUDIT_LOG (IdUser, AuditType, AuditDate, UserName)
    VALUES (@IdUser, 'read', GETDATE(), @Username);
END;



CREATE PROC sp_EditUser(
    @IdUser INT,
    @FirstName VARCHAR(100),
    @LastName VARCHAR(100),
    @Username VARCHAR(100),
    @Email VARCHAR(100),
    @Pass VARCHAR(500),
    @IdStatus INT,
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
        IdStatus = @IdStatus,
        UserModification = @Username,
        DateModification = GETDATE()
    WHERE IdUser = @IdUser;

    INSERT INTO T_AUDIT_LOG (IdUser, AuditType, AuditDate, UserName)
    VALUES (@IdUser, 'edit', GETDATE(), @Singin);
END;


CREATE PROC sp_RemoveUser(
    @IdUser INT,
    @Singin VARCHAR(100)
)
AS
BEGIN
    DELETE FROM T_AUDIT_LOG WHERE IdUser = @IdUser;

    DELETE FROM T_USERS WHERE IdUser = @IdUser;

    INSERT INTO T_AUDIT_LOG (IdUser, AuditType, AuditDate, UserName)
    VALUES (@IdUser, 'delete', GETDATE(), @Singin);
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
DECLARE @Status VARCHAR(10) = 'A';
DECLARE @Register BIT;
DECLARE @Message VARCHAR(100);

EXEC sp_CreateUser @FirstName, @LastName,@Username, @Email, @Pass, @Status, @Register OUTPUT, @Message OUTPUT;

SELECT @Register AS Registered, @Message AS Message;

-- Validate user
EXEC sp_ValidateUser 'ale@gmail.com', 'a62039e2dd75ceffa3b72c632010c53a';

-- Read user
DECLARE @IdUser INT = 1
DECLARE @Singin VARCHAR(100) = SUSER_SNAME();

EXEC sp_ReadUser @IdUser, @Singin;

-- Update user
DECLARE @IdUser INT = 1;
DECLARE @FirstName VARCHAR(100) = 'Alejandra Updated';
DECLARE @LastName VARCHAR(100) = 'Linares Updated';
DECLARE @Username VARCHAR(100) = 'ale478 Updated';
DECLARE @Email VARCHAR(100) = 'ale@gmail.com Updated';
DECLARE @Pass VARCHAR(500) = 'a62039e2dd75ceffa3b72c632010c53a Updated';
DECLARE @IdStatus INT = 1;
DECLARE @Singin VARCHAR(100) = SUSER_SNAME();

EXEC sp_EditUser @IdUser, @FirstName, @LastName, @Username, @Email, @Pass, @IdStatus, @Singin;


-- Remove user
DECLARE @IdUser INT = 2;
DECLARE @Singin VARCHAR(100) = SUSER_SNAME();

EXEC sp_RemoveUser @IdUser, @Singin;

-- Display audit logs
DECLARE @PageSize INT = 10;
DECLARE @PageNumber INT = 1;

EXEC sp_GetAuditLogs @PageSize, @PageNumber;

-- Display status legend
SELECT StatusName, StatusDescription
FROM T_STATUS;



 						   