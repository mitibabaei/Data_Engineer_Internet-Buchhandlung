CREATE OR ALTER PROCEDURE dbo.usp_ETL_InternetBuchhandlung
AS
BEGIN
   SET NOCOUNT ON;


   ----------------------------------------------------
   -- 1️Step: Extract Data from Source DB
   ----------------------------------------------------
   PRINT 'Extracting data from InternetBuchhandlung...';


   -- Drop temp tables if they exist
   IF OBJECT_ID('temp_Buch', 'U') IS NOT NULL DROP TABLE temp_Buch;
   IF OBJECT_ID('temp_Kunde', 'U') IS NOT NULL DROP TABLE temp_Kunde;
   IF OBJECT_ID('temp_Bestellung', 'U') IS NOT NULL DROP TABLE temp_Bestellung;
   IF OBJECT_ID('temp_Rezension', 'U') IS NOT NULL DROP TABLE temp_Rezension;
   IF OBJECT_ID('temp_Zahlungsmodus', 'U') IS NOT NULL DROP TABLE temp_Zahlungsmodus;


   -- Extract data directly from fully qualified source tables
   SELECT * INTO temp_Buch
   FROM InternetBuchhandlung.dbo.Buch;


   SELECT * INTO temp_Kunde
   FROM InternetBuchhandlung.dbo.Kunde;


   SELECT b.BestellID, b.KundeID, p.ISBN, p.Menge, p.Aktuellerpreis,
          b.Bestelldatum, b.ZahlungsmodusID
   INTO temp_Bestellung
   FROM InternetBuchhandlung.dbo.Bestellung b
   JOIN InternetBuchhandlung.dbo.Bestellposition p ON b.BestellID = p.BestellID;


   SELECT * INTO temp_Rezension
   FROM InternetBuchhandlung.dbo.Rezension;


   SELECT ZahlungsmodusID,
          CASE
              WHEN Rechnung = 1 THEN 'Rechnung'
              WHEN Bankeinzug = 1 THEN 'Bankeinzug'
              WHEN Kreditkarte = 1 THEN 'Kreditkarte'
          END AS Zahlungsart
   INTO temp_Zahlungsmodus
   FROM InternetBuchhandlung.dbo.Zahlungsmodus;


   ----------------------------------------------------
   -- 2️Step: Transform Data
   ----------------------------------------------------
   PRINT 'Transforming extracted data...';


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
   -- 3️Step: Load Data into DWH
   ----------------------------------------------------
   PRINT 'Loading data into DWH_InternetBuchhandlung...';


   -- Load Dim_Buch
   DELETE FROM DWH_InternetBuchhandlung.dbo.Dim_Buch;
   INSERT INTO DWH_InternetBuchhandlung.dbo.Dim_Buch (ISBN, Titel, Seitenanzahl, Preis, gueltig_von, aktiv)
   SELECT DISTINCT ISBN, Titel, Seitenanzahl, Preis, GETDATE(), 1
   FROM temp_Buch;


   -- Load Dim_Kunde
   DELETE FROM DWH_InternetBuchhandlung.dbo.Dim_Kunde;
   INSERT INTO DWH_InternetBuchhandlung.dbo.Dim_Kunde (KundeID, Vorname, Nachname, Email, Straße, PLZ, gueltig_von, aktiv)
   SELECT DISTINCT KundeID, Vorname, Nachname, Email, Straße, PLZ, GETDATE(), 1
   FROM temp_Kunde;


   -- Load Dim_Zahlungsmodus
   DELETE FROM DWH_InternetBuchhandlung.dbo.Dim_Zahlungsmodus;
   INSERT INTO DWH_InternetBuchhandlung.dbo.Dim_Zahlungsmodus (ZahlungsmodusID, Zahlungsart)
   SELECT DISTINCT ZahlungsmodusID, Zahlungsart
   FROM temp_Zahlungsmodus;


   -- Load Dim_Zeit
   DELETE FROM DWH_InternetBuchhandlung.dbo.Dim_Zeit;
   INSERT INTO DWH_InternetBuchhandlung.dbo.Dim_Zeit (Datum, Tag, Monat, Jahr, Quartal)
   SELECT DISTINCT Bestelldatum,
          DAY(Bestelldatum),
          MONTH(Bestelldatum),
          YEAR(Bestelldatum),
          DATEPART(QUARTER, Bestelldatum)
   FROM temp_Bestellung;


   -- Load Dim_Rezension
   DELETE FROM DWH_InternetBuchhandlung.dbo.Dim_Rezension;
   INSERT INTO DWH_InternetBuchhandlung.dbo.Dim_Rezension (RezensionID, ISBN, KundeID, Buchbeschreibung, Erstelldatum)
   SELECT RezensionID, ISBN, KundeID, Buchbeschreibung, Erstelldatum
   FROM temp_Rezension;


   -- Load Fakt_Bestellung
   DELETE FROM DWH_InternetBuchhandlung.dbo.Fakt_Bestellung;
   INSERT INTO DWH_InternetBuchhandlung.dbo.Fakt_Bestellung (BestellID, KundeID, ISBN, ZahlungsmodusID, Menge, Aktuellerpreis, Umsatz, Bestelldatum)
   SELECT b.BestellID, b.KundeID, b.ISBN, b.ZahlungsmodusID,
          b.Menge, ROUND(b.Aktuellerpreis, 2),
          (b.Menge * b.Aktuellerpreis) AS Umsatz, b.Bestelldatum
   FROM temp_Bestellung b;


   ----------------------------------------------------
   -- 4️Step: Validation and Completion
   ----------------------------------------------------
   PRINT 'ETL process completed successfully.';


END
GO
