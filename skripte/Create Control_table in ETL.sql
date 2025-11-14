USE DWH_InternetBuchhandlung;
GO


-------------------------------------------------------------
-- Ensure Schema and Control Table Exist Before ETL Starts
-------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dwh')
BEGIN
   PRINT 'Creating schema [dwh]...';
   EXEC('CREATE SCHEMA dwh AUTHORIZATION dbo;');
END
GO


IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ETL_Control' AND SCHEMA_NAME(schema_id) = 'dwh')
BEGIN
   PRINT 'Creating control table [dwh.ETL_Control]...';
   CREATE TABLE dwh.ETL_Control (
       ETL_ID INT IDENTITY(1,1) PRIMARY KEY,
       ProcedureName VARCHAR(100),
       StartTime DATETIME,
       EndTime DATETIME,
       Status VARCHAR(20),
       RowsInserted INT,
       ErrorMessage VARCHAR(4000)
   );
END
GO


-------------------------------------------------------------
-- Main ETL Procedure
-------------------------------------------------------------


CREATE OR ALTER PROCEDURE dwh.usp_ETL_InternetBuchhandlung
AS
BEGIN
   SET NOCOUNT ON;
   DECLARE @StartTime DATETIME = GETDATE();
   DECLARE @Status VARCHAR(20) = 'Started';
   DECLARE @RowsInserted INT = 0;
   DECLARE @ErrorMessage VARCHAR(4000) = NULL;


   BEGIN TRY
       BEGIN TRANSACTION;


       PRINT 'ETL started at ' + CONVERT(VARCHAR(30), @StartTime, 120);


       ----------------------------------------------------
       -- 1 Extract
       ----------------------------------------------------
       IF OBJECT_ID('temp_Buch', 'U') IS NOT NULL DROP TABLE temp_Buch;
       IF OBJECT_ID('temp_Kunde', 'U') IS NOT NULL DROP TABLE temp_Kunde;
       IF OBJECT_ID('temp_Bestellung', 'U') IS NOT NULL DROP TABLE temp_Bestellung;
       IF OBJECT_ID('temp_Rezension', 'U') IS NOT NULL DROP TABLE temp_Rezension;
       IF OBJECT_ID('temp_Zahlungsmodus', 'U') IS NOT NULL DROP TABLE temp_Zahlungsmodus;


       SELECT * INTO temp_Buch FROM InternetBuchhandlung.dbo.Buch;
       SELECT * INTO temp_Kunde FROM InternetBuchhandlung.dbo.Kunde;
       SELECT b.BestellID, b.KundeID, p.ISBN, p.Menge, p.Aktuellerpreis, b.Bestelldatum, b.ZahlungsmodusID
       INTO temp_Bestellung
       FROM InternetBuchhandlung.dbo.Bestellung b
       JOIN InternetBuchhandlung.dbo.Bestellposition p ON b.BestellID = p.BestellID;
       SELECT * INTO temp_Rezension FROM InternetBuchhandlung.dbo.Rezension;
       SELECT ZahlungsmodusID,
              CASE WHEN Rechnung=1 THEN 'Rechnung'
                   WHEN Bankeinzug=1 THEN 'Bankeinzug'
                   WHEN Kreditkarte=1 THEN 'Kreditkarte'
              END AS Zahlungsart
       INTO temp_Zahlungsmodus
       FROM InternetBuchhandlung.dbo.Zahlungsmodus;


       ----------------------------------------------------
       -- 2 Transform
       ----------------------------------------------------
       UPDATE temp_Buch
       SET Titel = LTRIM(RTRIM(Titel)),
           Preis = ROUND(Preis, 2);


       UPDATE temp_Kunde
       SET PLZ = RIGHT('00000' + PLZ, 5),
           Vorname = UPPER(LEFT(Vorname, 1)) + LOWER(SUBSTRING(Vorname, 2, LEN(Vorname))),
           Nachname = UPPER(LEFT(Nachname, 1)) + LOWER(SUBSTRING(Nachname, 2, LEN(Nachname)));


       UPDATE temp_Rezension
       SET Buchbeschreibung = LEFT(Buchbeschreibung, 2000),
           Erstelldatum = CONVERT(DATE, Erstelldatum, 104);


       ----------------------------------------------------
       -- 3 Load (DWH)
       ----------------------------------------------------
       PRINT 'Loading data into DWH...';


       DELETE FROM dwh.Dim_Buch;
       INSERT INTO dwh.Dim_Buch (ISBN, Titel, Seitenanzahl, Preis, gueltig_von, aktiv)
       SELECT DISTINCT ISBN, Titel, Seitenanzahl, Preis, GETDATE(), 1 FROM temp_Buch;


       DELETE FROM dwh.Dim_Kunde;
       INSERT INTO dwh.Dim_Kunde (KundeID, Vorname, Nachname, Email, Straﬂe, PLZ, gueltig_von, aktiv)
       SELECT DISTINCT KundeID, Vorname, Nachname, Email, Straﬂe, PLZ, GETDATE(), 1 FROM temp_Kunde;


       DELETE FROM dwh.Dim_Zahlungsmodus;
       INSERT INTO dwh.Dim_Zahlungsmodus (ZahlungsmodusID, Zahlungsart)
       SELECT DISTINCT ZahlungsmodusID, Zahlungsart FROM temp_Zahlungsmodus;


       DELETE FROM dwh.Dim_Zeit;
       INSERT INTO dwh.Dim_Zeit (Datum, Tag, Monat, Jahr, Quartal)
       SELECT DISTINCT Bestelldatum, DAY(Bestelldatum), MONTH(Bestelldatum),
              YEAR(Bestelldatum), DATEPART(QUARTER, Bestelldatum)
       FROM temp_Bestellung;


       DELETE FROM dwh.Dim_Rezension;
       INSERT INTO dwh.Dim_Rezension (RezensionID, ISBN, KundeID, Buchbeschreibung, Erstelldatum)
       SELECT RezensionID, ISBN, KundeID, Buchbeschreibung, Erstelldatum FROM temp_Rezension;


       DELETE FROM dwh.Fakt_Bestellung;
       INSERT INTO dwh.Fakt_Bestellung (BestellID, KundeID, ISBN, ZahlungsmodusID, Menge, Aktuellerpreis, Umsatz, Bestelldatum)
       SELECT b.BestellID, b.KundeID, b.ISBN, b.ZahlungsmodusID,
              b.Menge, ROUND(b.Aktuellerpreis, 2), (b.Menge * b.Aktuellerpreis), b.Bestelldatum
       FROM temp_Bestellung b;


       SET @RowsInserted = @@ROWCOUNT;


       ----------------------------------------------------
       -- 4 Log Success
       ----------------------------------------------------
       COMMIT TRANSACTION;
       SET @Status = 'Success';
       INSERT INTO dwh.ETL_Control (ProcedureName, StartTime, EndTime, Status, RowsInserted)
       VALUES ('usp_ETL_InternetBuchhandlung', @StartTime, GETDATE(), @Status, @RowsInserted);


       PRINT 'ETL completed successfully.';


   END TRY
   BEGIN CATCH
       ROLLBACK TRANSACTION;
       SET @Status = 'Failed';
       SET @ErrorMessage = ERROR_MESSAGE();


       INSERT INTO dwh.ETL_Control (ProcedureName, StartTime, EndTime, Status, ErrorMessage)
       VALUES ('usp_ETL_InternetBuchhandlung', @StartTime, GETDATE(), @Status, @ErrorMessage);


       PRINT 'ETL failed: ' + @ErrorMessage;
   END CATCH
END
GO
