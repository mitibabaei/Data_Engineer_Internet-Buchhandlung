-- ============================================
-- 1️⃣ Datenbank erstellen und aktivieren
-- ============================================
CREATE DATABASE InternetBuchhandlung;
GO

USE InternetBuchhandlung;
GO

-- ============================================
-- 2️⃣ Tabellen erstellen
-- ============================================

-- Tabelle: Buch
CREATE TABLE Buch (
ISBN CHAR(13) PRIMARY KEY,
Titel NVARCHAR(50),
Seitenanzahl INT,
Preis DECIMAL(6,2)
);

-- Tabelle: Kunde
CREATE TABLE Kunde (
KundeID INT PRIMARY KEY IDENTITY(1,1),
Vorname NVARCHAR(50),
Nachname NVARCHAR(50),
Email NVARCHAR(100),
Straße NVARCHAR(100),
PLZ NVARCHAR(10),
Ort NVARCHAR(50)
);

-- Tabelle: Zahlungsmodus
CREATE TABLE Zahlungsmodus (
ZahlungsmodusID INT PRIMARY KEY IDENTITY(1,1),
Rechnung BIT,
Bankeinzug BIT,
Kreditkarte BIT

);

-- Tabelle: Bestellung
CREATE TABLE Bestellung (
BestellID INT PRIMARY KEY IDENTITY(1,1),
Bestelldatum DATE,
KundeID INT,
ZahlungsmodusID INT,
FOREIGN KEY (KundeID) REFERENCES Kunde(KundeID),
FOREIGN KEY (ZahlungsmodusID) REFERENCES Zahlungsmodus(ZahlungsmodusID)
);

-- Tabelle: Bestellposition
CREATE TABLE Bestellposition (
BestellID INT,
ISBN CHAR(13),
Menge INT,
Aktuellerpreis DECIMAL(6,2),
PRIMARY KEY (BestellID, ISBN),
FOREIGN KEY (BestellID) REFERENCES Bestellung(BestellID),
FOREIGN KEY (ISBN) REFERENCES Buch(ISBN)
);

-- Tabelle: Rezension
CREATE TABLE Rezension (
RezensionID INT PRIMARY KEY IDENTITY(1,1),
ISBN CHAR(13),
KundeID INT,
Buchbeschreibung NVARCHAR(2000),
Erstelldatum DATE,
FOREIGN KEY (ISBN) REFERENCES Buch(ISBN),
FOREIGN KEY (KundeID) REFERENCES Kunde(KundeID)
);

-- ============================================
-- 3️⃣ Beispiel-Datensätze einfügen
-- ============================================

-- Bücher
INSERT INTO Buch VALUES
('9780140449112', 'Die Odyssee', 480, 14.99),
('9783832180577', 'Der Steppenwolf', 320, 12.50),
('9783453315125', 'Der Vorleser', 210, 9.90),
('9783596294316', 'Faust I', 180, 8.50),
('9783551551672', 'Harry Potter und der Stein der Weisen', 336, 19.99);

-- Kunden
INSERT INTO Kunde (Vorname, Nachname, Email, Straße, PLZ, Ort) VALUES
('Anna', 'Schmidt', 'anna.schmidt@mail.de', 'Hauptstraße 12', '50667', 'Köln'),
('Markus', 'Weber', 'markus.weber@mail.de', 'Bahnhofstr. 5', '10115', 'Berlin'),
('Laura', 'Fischer', 'laura.fischer@mail.de', 'Lindenweg 3', '80331', 'München'),
('Tim', 'Keller', 'tim.keller@mail.de', 'Am See 8', '20095', 'Hamburg');

-- Zahlungsmodi
INSERT INTO Zahlungsmodus (Rechnung, Bankeinzug, Kreditkarte) VALUES
(0, 0, 1),  -- Kreditkarte
(1, 0, 0),  -- Rechnung
(0, 1, 0);  -- Bankeinzug

-- Bestellungen
INSERT INTO Bestellung (Bestelldatum, KundeID, ZahlungsmodusID) VALUES
('2024-09-01', 1, 1),
('2024-09-03', 2, 2),
('2024-09-05', 3, 3),
('2024-09-07', 4, 1),
('2024-09-08', 1, 2);

-- Bestellpositionen
INSERT INTO Bestellposition VALUES
(1, '9780140449112', 1, 14.99),
(1, '9783551551672', 1, 19.99),
(2, '9783832180577', 2, 12.50),
(3, '9783596294316', 1, 8.50),
(4, '9783453315125', 3, 9.90),
(5, '9780140449112', 1, 14.99);

-- Rezensionen
INSERT INTO Rezension (ISBN, KundeID, Buchbeschreibung, Erstelldatum) VALUES
('9780140449112', 1, 'Ein großartiges Epos, spannend bis zum Schluss.', '2024-09-10'),
('9783551551672', 3, 'Sehr fantasievoll, gut für junge Leser.', '2024-09-12'),
('9783832180577', 2, 'Tiefgründig, aber manchmal schwer verständlich.', '2024-09-15'),
('9783596294316', 4, 'Klassiker, den man gelesen haben muss.', '2024-09-17'),
('9783453315125', 1, 'Emotional und bewegend, sehr empfehlenswert.', '2024-09-20');

