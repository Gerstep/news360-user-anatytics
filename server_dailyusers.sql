SELECT ActionDate, 
        COUNT(*)
        FROM UserStats.EditionUsers WITH(NOLOCK)
        WHERE ActionDate
                BETWEEN ('1/01/2014 00:00:00') AND ('12/31/2014 23:59:59')
        GROUP BY ActionDate
        order by ActionDate