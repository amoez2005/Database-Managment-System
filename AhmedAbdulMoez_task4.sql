
-- Name / Initials: MH
-- Practical Assignment 4
-- Database: CRA
-- SQL Server Management Studio

USE [CRA];
GO


-- ============================================
-- TASK 1: Add discount column
-- ============================================

IF COL_LENGTH('dbo.Subscriber', 'discount') IS NULL
BEGIN
    ALTER TABLE dbo.Subscriber
    ADD discount DECIMAL(3,2) NOT NULL
        CONSTRAINT DF_Subscriber_discount
        DEFAULT (0.00) WITH VALUES;
END;
GO


-- ============================================
-- TASK 2: Add email column
-- ============================================

IF COL_LENGTH('dbo.Person', 'email') IS NULL
BEGIN
    ALTER TABLE dbo.Person
    ADD email VARCHAR(50) NULL;
END;
GO


-- ============================================
-- TASK 3: Create DomainMH table
-- ============================================

IF OBJECT_ID('dbo.DomainMH', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DomainMH
    (
        domainID INT IDENTITY(1,1) PRIMARY KEY,
        domainName VARCHAR(15)
    );
END;
GO


-- ============================================
-- TASK 4: Insert domains and remove duplicates
-- ============================================

INSERT INTO dbo.DomainMH (domainName)
SELECT v.domainName
FROM
(
    VALUES
        ('gmail.com'),
        ('yahoo.com'),
        ('hotmail.com'),
        ('eif.viko.lt')
) AS v(domainName)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.DomainMH AS d
    WHERE d.domainName = v.domainName
);
GO

-- Keep only one row for each domain

WITH DuplicateDomains AS
(
    SELECT
        domainID,
        ROW_NUMBER() OVER
        (
            PARTITION BY domainName
            ORDER BY domainID
        ) AS RowNum
    FROM dbo.DomainMH
)
DELETE FROM DuplicateDomains
WHERE RowNum > 1;
GO


-- ============================================
-- TASK 5: Generate random email addresses
-- ============================================

UPDATE p
SET email = LOWER(
    LTRIM(RTRIM(p.firstName)) + '.' +
    LTRIM(RTRIM(p.lastName)) + '@' +
    (
        SELECT TOP (1) d.domainName
        FROM dbo.DomainMH AS d
        ORDER BY CHECKSUM(
            NEWID(),
            p.personID,
            d.domainID
        )
    )
)
FROM dbo.Person AS p
WHERE p.email IS NULL;
GO


-- ============================================
-- TASK 6: Create MobilePhoneMH table
-- ============================================

IF OBJECT_ID('dbo.MobilePhoneMH', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.MobilePhoneMH
    (
        mobTelID INT IDENTITY(1,1) PRIMARY KEY,
        manufacturer VARCHAR(15),
        model VARCHAR(30),
        price FLOAT,
        monthlyPrice FLOAT
    );
END;
GO


-- ============================================
-- TASK 7: Add mobTelID to Subscriber
-- ============================================

IF COL_LENGTH('dbo.Subscriber', 'mobTelID') IS NULL
BEGIN
    ALTER TABLE dbo.Subscriber
    ADD mobTelID INT NULL;
END;
GO


-- ============================================
-- TASK 8: Create foreign key relationship
-- ============================================

IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_Subscriber_MobilePhoneMH'
      AND parent_object_id = OBJECT_ID('dbo.Subscriber')
)
BEGIN
    ALTER TABLE dbo.Subscriber
    ADD CONSTRAINT FK_Subscriber_MobilePhoneMH
        FOREIGN KEY (mobTelID)
        REFERENCES dbo.MobilePhoneMH (mobTelID);
END;
GO


-- ============================================
-- TASK 9: Import phone records
-- ============================================

-- First attempt BULK INSERT as required.
-- If permission is denied, load the same data
-- using INSERT as a temporary fallback.
-- The fallback does NOT satisfy the BULK INSERT
-- requirement of the assignment.

DECLARE @BulkSuccess BIT = 0;

IF NOT EXISTS
(
    SELECT 1 FROM dbo.MobilePhoneMH
)
BEGIN
    BEGIN TRY

        EXEC(
            'BULK INSERT dbo.MobilePhoneMH
             FROM ''C:\SQLData\mobile-phones.txt''
             WITH
             (
                 FIRSTROW = 2,
                 FIELDTERMINATOR = '','',
                 ROWTERMINATOR = ''0x0a'',
                 CODEPAGE = ''65001''
             );'
        );

        SET @BulkSuccess = 1;
        PRINT 'TASK 9: BULK INSERT succeeded.';

    END TRY
    BEGIN CATCH

        PRINT 'TASK 9: BULK INSERT failed.';
        PRINT ERROR_MESSAGE();

    END CATCH;
END
ELSE
BEGIN
    PRINT 'TASK 9: Phone table already contains records.';
END;


-- Fallback: exact phone data from teacher's file
-- Insert only phone models not already present.

IF @BulkSuccess = 0
BEGIN

    INSERT INTO dbo.MobilePhoneMH
    (
        manufacturer,
        model,
        price,
        monthlyPrice
    )
    SELECT
        v.manufacturer,
        v.model,
        v.price,
        v.monthlyPrice
    FROM
    (
        VALUES
        ('Apple','iPhone 18 Pro 256GB',1399,58.29),
        ('Apple','iPhone 18 Pro Max 256GB',1549,64.54),
        ('Apple','iPhone 17 256GB',999,41.63),
        ('Apple','iPhone 17e 256GB',749,31.21),
        ('Apple','iPhone Air 256GB',1199,49.96),

        ('Samsung','Galaxy S26 256GB',999,41.63),
        ('Samsung','Galaxy S26+ 256GB',1199,49.96),
        ('Samsung','Galaxy S26 Ultra 256GB',1499,62.46),
        ('Samsung','Galaxy S26 FE 128GB',699,29.13),
        ('Samsung','Galaxy A57 5G 128GB',499,20.79),
        ('Samsung','Galaxy A37 5G 128GB',379,15.79),
        ('Samsung','Galaxy Z Fold8 256GB',1999,83.29),
        ('Samsung','Galaxy Z Flip8 256GB',1199,49.96),

        ('Google','Pixel 11 128GB',899,37.46),
        ('Google','Pixel 11 Pro 128GB',1099,45.79),
        ('Google','Pixel 11 Pro XL 256GB',1299,54.13),
        ('Google','Pixel 11 Pro Fold 256GB',1899,79.13),

        ('Xiaomi','Xiaomi 17 256GB',899,37.46),
        ('Xiaomi','Xiaomi 17 Ultra 512GB',1499,62.46),

        ('Nothing','Phone (3) 256GB',699,29.13),

        ('Sony','Xperia 1 VIII 256GB',1499,62.46),
        ('Sony','Xperia 10 VIII 128GB',449,18.71),
        ('Sony','Xperia 1 VII 256GB',1299,54.13),
        ('Sony','Xperia 10 VII 128GB',399,16.63),

        ('Google','Pixel 10a 128GB',549,22.88),
        ('Google','Pixel 10 128GB',799,33.29),
        ('Google','Pixel 10 Pro 128GB',999,41.63),
        ('Google','Pixel 10 Pro XL 256GB',1199,49.96),
        ('Google','Pixel 10 Pro Fold 256GB',1799,74.96)

    ) AS v(manufacturer, model, price, monthlyPrice)

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.MobilePhoneMH AS m
        WHERE m.manufacturer = v.manufacturer
          AND m.model = v.model
    );

    PRINT 'TASK 9: SQL INSERT fallback completed.';
    PRINT 'BULK INSERT requirement still needs verification.';

END;
GO


-- ============================================
-- TASK 10: Assign random phones to subscribers
-- ============================================

IF EXISTS
(
    SELECT 1
    FROM dbo.MobilePhoneMH
)
BEGIN

    UPDATE s
    SET mobTelID =
    (
        SELECT TOP (1) m.mobTelID
        FROM dbo.MobilePhoneMH AS m
        ORDER BY CHECKSUM(
            NEWID(),
            s.subscriberID,
            m.mobTelID
        )
    )
    FROM dbo.Subscriber AS s
    WHERE s.contractEndDate IS NULL
      AND s.mobTelID IS NULL;

    PRINT 'TASK 10: Phone assignments completed.';

END
ELSE
BEGIN
    PRINT 'TASK 10: Skipped. No mobile phones available.';
END;
GO


-- ============================================
-- TASK 10: Assign random phones to subscribers extra
-- ============================================

USE [CRA];
GO

SELECT TOP 10
    s.subscriberID,
    p.mobTelID,
    p.manufacturer,
    p.model
FROM dbo.Subscriber AS s
CROSS APPLY
(
    SELECT TOP (1)
        m.mobTelID,
        m.manufacturer,
        m.model
    FROM dbo.MobilePhoneMH AS m
    ORDER BY CHECKSUM(
        NEWID(),
        s.subscriberID,
        m.mobTelID
    )
) AS p
WHERE s.contractEndDate IS NULL;
GO


-- ============================================
-- FINAL VERIFICATION
-- ============================================


-- Verify discount
SELECT TOP 10
    subscriberID,
    discount
FROM dbo.Subscriber;
GO


-- Verify emails
SELECT TOP 10
    personID,
    firstName,
    lastName,
    email
FROM dbo.Person;
GO


-- Verify domains
SELECT
    domainID,
    domainName
FROM dbo.DomainMH
ORDER BY domainID;
GO


-- Verify mobile phones
SELECT *
FROM dbo.MobilePhoneMH
ORDER BY mobTelID;
GO


-- Verify foreign key
SELECT
    name AS ForeignKeyName
FROM sys.foreign_keys
WHERE name = 'FK_Subscriber_MobilePhoneMH';
GO


-- Verify subscriber assignments
SELECT TOP 10
    s.subscriberID,
    s.contractEndDate,
    s.mobTelID,
    m.manufacturer,
    m.model
FROM dbo.Subscriber AS s
LEFT JOIN dbo.MobilePhoneMH AS m
    ON s.mobTelID = m.mobTelID
WHERE s.contractEndDate IS NULL
ORDER BY s.subscriberID;
GO


-- ============================================
-- FINAL SUMMARY
-- ============================================

SELECT

    (SELECT COUNT(*)
     FROM dbo.Person
     WHERE email IS NOT NULL)
        AS TotalEmails,

    (SELECT COUNT(*)
     FROM dbo.DomainMH)
        AS TotalDomains,

    (SELECT COUNT(DISTINCT domainName)
     FROM dbo.DomainMH)
        AS UniqueDomains,

    (SELECT COUNT(*)
     FROM dbo.MobilePhoneMH)
        AS TotalPhones,

    (SELECT COUNT(*)
     FROM dbo.Subscriber
     WHERE contractEndDate IS NULL)
        AS EligibleSubscribers,

    (SELECT COUNT(*)
     FROM dbo.Subscriber
     WHERE contractEndDate IS NULL
       AND mobTelID IS NOT NULL)
        AS AssignedPhones;
GO
