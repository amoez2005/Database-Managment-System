USE [CRA];


-- 1. 
ALTER TABLE dbo.Subscriber
ADD discount DECIMAL(3,2) NOT NULL
    CONSTRAINT DF_Subscriber_discount
    DEFAULT (0.00) WITH VALUES;



-- 2. 
ALTER TABLE dbo.Person
ADD email VARCHAR(50) NULL;



-- 3. 
CREATE TABLE dbo.[Domain]
(
    domainID INT IDENTITY(1,1) PRIMARY KEY,
    domainName VARCHAR(15)
);



-- 4.
INSERT INTO dbo.[Domain] (domainName)
VALUES ('gmail.com'),
       ('yahoo.com'),
       ('hotmail.com'),
       ('eif.viko.lt');



-- 5. 
UPDATE p
SET email = LOWER(
    LTRIM(RTRIM(p.firstName)) + '.' +
    LTRIM(RTRIM(p.lastName)) + '@' +
    (
        SELECT TOP (1) d.domainName
        FROM dbo.[Domain] AS d
        ORDER BY CHECKSUM(NEWID(), p.personID, d.domainID)
    )
)
FROM dbo.Person AS p;



-- 6. 
CREATE TABLE dbo.MobilePhone
(
    mobTelID INT IDENTITY(1,1) PRIMARY KEY,
    manufacturer VARCHAR(15),
    model VARCHAR(30),
    price FLOAT,
    monthlyPrice FLOAT
);



-- 7. 
ALTER TABLE dbo.Subscriber
ADD mobTelID INT NULL;



-- 8. 
ALTER TABLE dbo.Subscriber
ADD CONSTRAINT FK_Subscriber_MobilePhone
    FOREIGN KEY (mobTelID)
    REFERENCES dbo.MobilePhone (mobTelID);



-- 9. 
BULK INSERT dbo.MobilePhone
FROM 'C:\SQLData\mobile-phones.txt'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);


-- 10. 
UPDATE s
SET mobTelID =
(
    SELECT TOP (1) m.mobTelID
    FROM dbo.MobilePhone AS m
    ORDER BY CHECKSUM(NEWID(), s.subscriberID, m.mobTelID)
)
FROM dbo.Subscriber AS s
WHERE s.contractEndDate IS NULL;
