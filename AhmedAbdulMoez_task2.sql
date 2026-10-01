
USE [CRA];
GO

-- 1
SELECT COUNT(*) AS CityCount
FROM City;
GO

-- 2
SELECT p.planName,
       p.price AS PlanPrice,
       i.internetDataPlanName,
       i.dataAllowanceMB,
       i.price AS InternetPrice,
       o.operatorName
FROM [Plan] p
INNER JOIN InternetDataPlan i
    ON p.internetDataPlanID = i.internetDataPlanID
INNER JOIN MobileNetworkOperator o
    ON i.operatorID = o.operatorID;
GO


-- 4
SELECT c.cityName, COUNT(p.personID) AS UserCount
FROM City c
LEFT JOIN Person p ON c.cityID = p.cityID
GROUP BY c.cityID, c.cityName
ORDER BY c.cityName;
GO

-- 5
SELECT c.cityName
FROM City c
LEFT JOIN Person p ON c.cityID = p.cityID
WHERE p.personID IS NULL
ORDER BY c.cityName;
GO

-- 6a
SELECT CAST(AVG(1.0 * UserCount) AS DECIMAL(18, 2)) AS AverageUsers
FROM (
    SELECT COUNT(p.personID) AS UserCount
    FROM City c
    INNER JOIN Person p ON c.cityID = p.cityID
    GROUP BY c.cityID
) counts;
GO

-- 6b
SELECT CAST(AVG(1.0 * UserCount) AS DECIMAL(18, 2)) AS AverageUsers
FROM (
    SELECT COUNT(p.personID) AS UserCount
    FROM City c
    LEFT JOIN Person p ON c.cityID = p.cityID
    GROUP BY c.cityID
) counts;
GO

-- 7
SELECT TOP (1) WITH TIES
       o.operatorName, COUNT(p.planID) AS PlanCount
FROM MobileNetworkOperator o
LEFT JOIN [Plan] p ON o.operatorID = p.operatorID
GROUP BY o.operatorID, o.operatorName
ORDER BY PlanCount DESC;
GO

-- 8
SELECT pe.firstName, pe.lastName, p.planName, s.contractStartDate
FROM Subscriber s
INNER JOIN Person pe ON s.personID = pe.personID
INNER JOIN [Plan] p ON s.planID = p.planID
WHERE s.contractStartDate >= '20250103'
  AND s.contractStartDate < '20250111';
GO

-- 9
SELECT o.operatorName,
       CAST(AVG(p.price) AS DECIMAL(18, 2)) AS AveragePrice
FROM MobileNetworkOperator o
LEFT JOIN [Plan] p ON o.operatorID = p.operatorID
GROUP BY o.operatorID, o.operatorName
ORDER BY AVG(p.price) DESC;
GO

-- 10
SELECT o.operatorName,
       COUNT(DISTINCT a.additionalServiceID) AS ServiceCount
FROM MobileNetworkOperator o
LEFT JOIN OperatorAdditionalService a ON o.operatorID = a.operatorID
GROUP BY o.operatorID, o.operatorName;
GO

