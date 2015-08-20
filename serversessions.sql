SELECT * FROM ( SELECT AccountGuid, COUNT(*) AS num  FROM UserStats.ApplicationStarts WITH(NOLOCK)
                WHERE ActionTime 
                BETWEEN ('2/01/2015 00:00:00') AND ('3/01/2015 23:59:59')
                AND ActionTime < '3/01/2015 00:00:00'
                GROUP BY AccountGuid) TMP
        WHERE num > 200