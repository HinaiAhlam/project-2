----Section 1: Complex Queries with Joins
---1 
SELECT 
    l.Name AS LibraryName,
    COUNT(b.ISBN) AS TotalBooks,
    SUM(CASE WHEN b.IsAvailable = 1 THEN 1 ELSE 0 END) AS AvailableBooks,
    SUM(CASE WHEN b.IsAvailable = 0 THEN 1 ELSE 0 END) AS BooksOnLoan
FROM Library l
LEFT JOIN Book b ON l.LibraryID = b.LibraryID
GROUP BY l.Name;

---2
SELECT
    m.FullName AS MemberName,
    m.Email,
    b.Title AS BookTitle,
    l.LoanDate,
    l.DueDate,
    l.Status
FROM Loan l
JOIN Member m ON l.MemberID = m.MemberID
JOIN Book b ON l.BookID = b.BookID
WHERE l.Status IN ('Issued', 'Overdue');

---3
SELECT
    m.FullName AS MemberName,
    m.PhoneNumber,
    b.Title AS BookTitle,
    lib.Name AS LibraryName,
    DATEDIFF(day, l.DueDate, GETDATE()) AS DaysOverdue,
    COALESCE(SUM(p.Amount), 0) AS FinesPaid
FROM Loan l
JOIN Member m ON l.MemberID = m.MemberID
JOIN Book b ON l.BookID = b.BookID
JOIN Library lib ON b.LibraryID = lib.LibraryID
LEFT JOIN Payment p ON l.LoanID = p.LoanID
WHERE l.DueDate < GETDATE()
  AND l.ReturnDate IS NULL
GROUP BY
    l.LoanID,
    m.FullName,
    m.PhoneNumber,
    b.Title,
    lib.Name,
    l.DueDate;

---4
SELECT
    lib.Name AS LibraryName,
    s.FullName AS StaffName,
    s.Position,
    COUNT(b.ISBN) AS BooksManaged
FROM Staff s
JOIN Library lib ON s.LibraryID = lib.LibraryID
LEFT JOIN Book b ON lib.LibraryID = b.LibraryID
GROUP BY
    lib.Name,
    s.FullName,
    s.Position
ORDER BY lib.Name, s.FullName;

---5
SELECT
    b.Title AS BookTitle,
    b.ISBN,
    b.Genre,
    COUNT(l.LoanID) AS TimesLoaned,
    AVG(CAST(r.Rating AS FLOAT)) AS AvgReviewRating
FROM Book b
JOIN Loan l ON b.BookID = l.BookID
LEFT JOIN Review r ON b.BookID = r.BookID
GROUP BY b.BookID, b.Title, b.ISBN, b.Genre
HAVING COUNT(l.LoanID) >= 3
ORDER BY TimesLoaned DESC;


---6
SELECT
    m.FullName AS MemberName,
    b.Title AS BookTitle,
    l.LoanDate,
    l.ReturnDate,
    r.Rating,
    r.Comments
FROM Member m
JOIN Loan l ON m.MemberID = l.MemberID
JOIN Book b ON l.BookID = b.BookID
LEFT JOIN Review r 
       ON r.BookID = b.BookID AND r.MemberID = m.MemberID
ORDER BY m.FullName, l.LoanDate;


---7 
SELECT
    b.Genre as  genre_name,
    COUNT(l.LoanID) AS TotalLoans,
    COALESCE(SUM(p.Amount), 0) AS TotalFinesCollected,
    CASE 
        WHEN COUNT(l.LoanID) = 0 THEN 0
        ELSE COALESCE(SUM(p.Amount), 0) * 1.0 / COUNT(l.LoanID)
    END AS AvgFinePerLoan
FROM Book b
JOIN Loan l ON b.BookID = l.BookID
LEFT JOIN Payment p ON l.LoanID = p.LoanID
GROUP BY b.Genre
ORDER BY b.Genre;




-----Section 2: Aggregate Functions and Grouping
---8

SELECT
    DATENAME(MONTH, l.LoanDate) AS MonthName,
    COUNT(l.LoanID) AS TotalLoans,
    SUM(CASE WHEN l.Status = 'Returned' THEN 1 ELSE 0 END) AS TotalReturned,
    SUM(CASE WHEN l.Status IN ('Issued', 'Overdue') THEN 1 ELSE 0 END) AS TotalStillIssuedOrOverdue
FROM Loan l
WHERE YEAR(l.LoanDate) = 2023
GROUP BY MONTH(l.LoanDate), DATENAME(MONTH, l.LoanDate)
ORDER BY MONTH(l.LoanDate);

----9

SELECT
    m.FullName AS MemberName,
    COUNT(l.LoanID) AS TotalBooksBorrowed,
    SUM(CASE WHEN l.Status IN ('Issued', 'Overdue') THEN 1 ELSE 0 END) AS TotalBooksCurrentlyOnLoan,
    COALESCE(SUM(p.Amount), 0) AS TotalFinesPaid,
    AVG(CAST(r.Rating AS FLOAT)) AS AvgRatingGiven
FROM Member m
JOIN Loan l ON m.MemberID = l.MemberID
LEFT JOIN Payment p ON l.LoanID = p.LoanID
LEFT JOIN Review r ON m.MemberID = r.MemberID AND l.BookID = r.BookID
GROUP BY m.FullName
HAVING COUNT(l.LoanID) >= 1
ORDER BY m.FullName;


---10
SELECT
    lib.Name AS LibraryName,
    COUNT(b.BookID) AS TotalBooksOwned,
    COUNT(DISTINCT l.MemberID) AS TotalActiveMembers,
    COALESCE(SUM(p.Amount), 0) AS TotalRevenueFromFines,
    CASE 
        WHEN COUNT(DISTINCT l.MemberID) = 0 THEN 0
        ELSE CAST(COUNT(b.BookID) AS FLOAT) / COUNT(DISTINCT l.MemberID)
    END AS AvgBooksPerMember
FROM Library lib
LEFT JOIN Book b ON lib.LibraryID = b.LibraryID
LEFT JOIN Loan l ON b.BookID = l.BookID
LEFT JOIN Payment p ON l.LoanID = p.LoanID
GROUP BY lib.Name
ORDER BY lib.Name;

----11

SELECT
    b.Title AS BookTitle,
    b.Genre,
    b.Price,
    g.AvgPrice AS GenreAveragePrice,
    b.Price - g.AvgPrice AS DifferenceFromAverage
FROM Book b
JOIN (
    SELECT Genre, AVG(Price) AS AvgPrice
    FROM Book
    GROUP BY Genre
) g ON b.Genre = g.Genre
WHERE b.Price > g.AvgPrice
ORDER BY DifferenceFromAverage DESC;

---12



SELECT
    p.Method AS PaymentMethod,
    COUNT(*) AS NumberOfTransactions,
    SUM(p.Amount) AS TotalAmountCollected,
    AVG(p.Amount) AS AveragePaymentAmount,
    ROUND(100.0 * SUM(p.Amount) / (SELECT SUM(Amount) FROM Payment), 2) AS PercentageOfTotalRevenue
FROM Payment p
GROUP BY p.Method
ORDER BY TotalAmountCollected DESC;



-----Section 3: Views Creation
----13

CREATE VIEW vw_CurrentLoans AS
SELECT
    m.MemberID,
    m.FullName AS MemberName,
    m.Email,
    m.PhoneNumber,
    b.BookID,
    b.Title AS BookTitle,
    b.Genre,
    lib.Name AS LibraryName,
    l.LoanID,
    l.LoanDate,
    l.DueDate,
    l.Status,
    CASE 
        WHEN l.DueDate >= CAST(GETDATE() AS DATE) THEN DATEDIFF(DAY, CAST(GETDATE() AS DATE), l.DueDate)
        ELSE DATEDIFF(DAY, l.DueDate, CAST(GETDATE() AS DATE))
    END AS DaysUntilDueOrOverdue
FROM Loan l
JOIN Member m ON l.MemberID = m.MemberID
JOIN Book b ON l.BookID = b.BookID
JOIN Library lib ON b.LibraryID = lib.LibraryID
WHERE l.Status IN ('Issued', 'Overdue');


select * from vw_CurrentLoans

----14
SELECT
    l.Name AS LibraryName,

    (SELECT COUNT(*)
     FROM Book b
     WHERE b.LibraryID = l.LibraryID) AS TotalBooks,

    (SELECT COUNT(*)
     FROM Book b
     WHERE b.LibraryID = l.LibraryID
       AND b.IsAvailable = 1) AS AvailableBooks,

    (SELECT COUNT(DISTINCT lo.MemberID)
     FROM Loan lo
     JOIN Book b ON lo.BookID = b.BookID
     WHERE b.LibraryID = l.LibraryID) AS ActiveMembers,

    (SELECT COUNT(*)
     FROM Loan lo
     JOIN Book b ON lo.BookID = b.BookID
     WHERE b.LibraryID = l.LibraryID
       AND lo.Status = 'Issued') AS ActiveLoans,

    (SELECT COUNT(*)
     FROM Staff s
     WHERE s.LibraryID = l.LibraryID) AS TotalStaff,

    (SELECT COALESCE(SUM(p.Amount), 0)
     FROM Payment p
     JOIN Loan lo ON p.LoanID = lo.LoanID
     JOIN Book b ON lo.BookID = b.BookID
     WHERE b.LibraryID = l.LibraryID) AS TotalRevenue

FROM Library l;



---15
CREATE VIEW vw_BookDetailsWithReviews AS
SELECT
    b.BookID,
    b.Title AS BookTitle,
    b.Genre,
    b.Price,
    b.IsAvailable,
    b.ShelfLocation,
    lib.Name AS LibraryName,
    COUNT(r.ReviewID) AS TotalReviews,
    AVG(CAST(r.Rating AS FLOAT)) AS AverageRating,
    MAX(r.ReviewDate) AS LatestReviewDate
FROM Book b
JOIN Library lib ON b.LibraryID = lib.LibraryID
LEFT JOIN Review r ON b.BookID = r.BookID
GROUP BY 
    b.BookID, 
    b.Title, 
    b.Genre, 
    b.Price, 
    b.IsAvailable, 
    b.ShelfLocation, 
    lib.Name;

	select * from vw_BookDetailsWithReviews

	
--------Section 4: Stored Procedures
----16


CREATE PROCEDURE sp_IssueBook
    @MemberID INT,
    @BookID INT,
    @DueDate DATE
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Book
        WHERE BookID = @BookID
          AND IsAvailable = 1
    )
    BEGIN
        PRINT 'Error: Book is not available.';
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM Loan
        WHERE MemberID = @MemberID
          AND Status = 'Issued'
          AND DueDate < GETDATE()
    )
    BEGIN
        PRINT 'Error: Member has overdue loans.';
        RETURN;
    END

    INSERT INTO Loan (LoanDate, DueDate, ReturnDate, Status, MemberID, BookID)
    VALUES (GETDATE(), @DueDate, NULL, 'Issued', @MemberID, @BookID);

    UPDATE Book
    SET IsAvailable = 0
    WHERE BookID = @BookID;

    PRINT 'Success: Book issued successfully.';
END;



EXEC sp_helptext 'sp_IssueBook';




------17
CREATE PROCEDURE sp_ReturnBook
    @LoanID INT,
    @ReturnDate DATE
AS
BEGIN
    DECLARE @DueDate DATE;
    DECLARE @BookID INT;
    DECLARE @OverdueDays INT;
    DECLARE @FineAmount DECIMAL(10,2);

    SELECT 
        @DueDate = DueDate,
        @BookID = BookID
    FROM Loan
    WHERE LoanID = @LoanID
      AND Status = 'Issued';

    IF @DueDate IS NULL
    BEGIN
        PRINT 'Error: Invalid LoanID or book already returned.';
        RETURN;
    END

    UPDATE Loan
    SET 
        Status = 'Returned',
        ReturnDate = @ReturnDate
    WHERE LoanID = @LoanID;

    UPDATE Book
    SET IsAvailable = 1
    WHERE BookID = @BookID;

    SET @OverdueDays = DATEDIFF(DAY, @DueDate, @ReturnDate);

    IF @OverdueDays > 0
    BEGIN
        SET @FineAmount = @OverdueDays * 2;

        INSERT INTO Payment (PaymentDate, Amount, Method, LoanID)
        VALUES (GETDATE(), @FineAmount, 'Pending', @LoanID);

        PRINT 'Book returned with fine.';
        PRINT 'Total Fine = ' + CAST(@FineAmount AS VARCHAR);
    END
    ELSE
    BEGIN
        SET @FineAmount = 0;
        PRINT 'Book returned successfully. No fine.';
    END
END;


EXEC sp_helptext 'sp_ReturnBook'



-----18
CREATE PROCEDURE sp_GetMemberReport
    @MemberID INT
AS
BEGIN

    SELECT 
        MemberID,
        FullName,
        Email,
        PhoneNumber,
        MembershipStartDate
    FROM Member
    WHERE MemberID = @MemberID;


    SELECT 
        l.LoanID,
        b.Title AS BookTitle,
        l.LoanDate,
        l.DueDate
    FROM Loan l
    JOIN Book b ON l.BookID = b.BookID
    WHERE l.MemberID = @MemberID
      AND l.Status = 'Issued';


    SELECT 
        l.LoanID,
        b.Title AS BookTitle,
        l.LoanDate,
        l.DueDate,
        l.ReturnDate,
        l.Status
    FROM Loan l
    JOIN Book b ON l.BookID = b.BookID
    WHERE l.MemberID = @MemberID
    ORDER BY l.LoanDate DESC;

    SELECT
        SUM(CASE WHEN p.Method <> 'Pending' THEN p.Amount ELSE 0 END) AS TotalPaidFines,
        SUM(CASE WHEN p.Method = 'Pending' THEN p.Amount ELSE 0 END) AS PendingFines
    FROM Payment p
    JOIN Loan l ON p.LoanID = l.LoanID
    WHERE l.MemberID = @MemberID;

    SELECT
        r.ReviewID,
        b.Title AS BookTitle,
        r.Rating,
        r.Comments,
        r.ReviewDate
    FROM Review r
    JOIN Book b ON r.BookID = b.BookID
    WHERE r.MemberID = @MemberID;
END;


EXEC sp_helptext sp_GetMemberReport


----19

CREATE PROCEDURE sp_MonthlyLibraryReport
    @LibraryID INT,
    @Month INT,
    @Year INT
AS
BEGIN

    SELECT 
        COUNT(*) AS TotalLoansIssued
    FROM Loan l
    JOIN Book b ON l.BookID = b.BookID
    WHERE b.LibraryID = @LibraryID
      AND MONTH(l.LoanDate) = @Month
      AND YEAR(l.LoanDate) = @Year;

    SELECT 
        COUNT(*) AS TotalBooksReturned
    FROM Loan l
    JOIN Book b ON l.BookID = b.BookID
    WHERE b.LibraryID = @LibraryID
      AND l.Status = 'Returned'
      AND MONTH(l.ReturnDate) = @Month
      AND YEAR(l.ReturnDate) = @Year;

    SELECT 
        COALESCE(SUM(p.Amount), 0) AS TotalRevenue
    FROM Payment p
    JOIN Loan l ON p.LoanID = l.LoanID
    JOIN Book b ON l.BookID = b.BookID
    WHERE b.LibraryID = @LibraryID
      AND MONTH(p.PaymentDate) = @Month
      AND YEAR(p.PaymentDate) = @Year;

    SELECT TOP 1
        b.Genre,
        COUNT(*) AS LoanCount
    FROM Loan l
    JOIN Book b ON l.BookID = b.BookID
    WHERE b.LibraryID = @LibraryID
      AND MONTH(l.LoanDate) = @Month
      AND YEAR(l.LoanDate) = @Year
    GROUP BY b.Genre
    ORDER BY COUNT(*) DESC;

    SELECT TOP 3
        m.MemberID,
        m.FullName,
        COUNT(*) AS NumberOfLoans
    FROM Loan l
    JOIN Book b ON l.BookID = b.BookID
    JOIN Member m ON l.MemberID = m.MemberID
    WHERE b.LibraryID = @LibraryID
      AND MONTH(l.LoanDate) = @Month
      AND YEAR(l.LoanDate) = @Year
    GROUP BY m.MemberID, m.FullName
    ORDER BY COUNT(*) DESC;

END;



EXEC sp_helptext sp_MonthlyLibraryReport
