-- ============================================
-- 1. DWH-Datenbank erstellen
-- ============================================
CREATE DATABASE DWH_InternetBuchhandlung;
GO
USE DWH_InternetBuchhandlung;
GO

-- ============================================
-- 2. Dimensionstabellen erstellen
-- ============================================
-- Dimension: Buch
CREATE TABLE Dim_Buch (
ISBN CHAR(13) PRIMARY KEY,
Titel NVARCHAR(50),
Seitenanzahl INT,
Preis DECIMAL(6,2),
gueltig_von DATE,
gueltig_bis DATE,
aktiv BIT DEFAULT 1
);

-- Dimension: Kunde
CREATE TABLE Dim_Kunde (
KundeID INT PRIMARY KEY,
Vorname NVARCHAR(50),
Nachname NVARCHAR(50),
Email NVARCHAR(100),
Straﬂe NVARCHAR(100),
PLZ NVARCHAR(10),
gueltig_von DATE,
gueltig_bis DATE,
aktiv BIT DEFAULT 1
);

-- Dimension: Zahlungsmodus
CREATE TABLE Dim_Zahlungsmodus (
ZahlungsmodusID INT PRIMARY KEY,
Zahlungsart NVARCHAR(20)
);

-- Dimension: Zeit
CREATE TABLE Dim_Zeit (
DatumID INT IDENTITY(1,1) PRIMARY KEY,
Datum DATE,
Tag INT,
Monat INT,
Quartal INT,
Jahr INT
);

-- Dimension: Rezension
CREATE TABLE Dim_Rezension (
RezensionID INT PRIMARY KEY,
ISBN CHAR(13),
KundeID INT,
Buchbeschreibung NVARCHAR(2000),
Erstelldatum DATE,
FOREIGN KEY (ISBN) REFERENCES Dim_Buch(ISBN),
FOREIGN KEY (KundeID) REFERENCES Dim_Kunde(KundeID)
);

-- ============================================
-- 3. Faktentabelle erstellen
-- ============================================
CREATE TABLE Fakt_Bestellung (
BestellID INT PRIMARY KEY,
KundeID INT,
ISBN CHAR(13),
ZahlungsmodusID INT,
Menge INT,
Aktuellerpreis DECIMAL(6,2),
Umsatz DECIMAL(8,2),
Bestelldatum DATE,
FOREIGN KEY (KundeID) REFERENCES Dim_Kunde(KundeID),
FOREIGN KEY (ISBN) REFERENCES Dim_Buch(ISBN),
FOREIGN KEY (ZahlungsmodusID) REFERENCES Dim_Zahlungsmodus(ZahlungsmodusID)
);