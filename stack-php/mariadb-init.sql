-- MySQL dump 10.13  Distrib 5.7.28, for Linux (x86_64)
--
-- Host: localhost    Database: domain_names
-- ------------------------------------------------------
-- Server version	5.7.28-0ubuntu0.19.04.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- CREATE DATABASE test;
USE test;

DROP TABLE IF EXISTS `pays`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pays` (
  `iso2` char(2) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`iso2`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pays`
--

LOCK TABLES `pays` WRITE;
/*!40000 ALTER TABLE `pays` DISABLE KEYS */;
INSERT INTO `pays` VALUES ('AE','Emirats Arabes Unis'),('AT','Autriche'),('AU','Australie'),('BE','Belgique'),('BS','Bahamas'),('CA','Canada'),('CH','Chine'),('CY','Chypre'),('CZ','République tchèque'),('DE','Allemagne'),('DK','Danemark'),('ES','Espagne'),('FR','France'),('GB','Royaume Uni'),('GP','Guadeloupe'),('HK','Hong Kong'),('IE','Irlande'),('IL','Israël'),('IT','Italie'),('JP','Japon'),('KR','République de Corée'),('KY','Iles Caïmans'),('LI','Liechtenstein'),('LU','Luxembourg'),('MA','Maroc'),('MC','Monaco'),('MQ','Martinique'),('MU','Maurice'),('NL','Pays-Bas'),('NO','Norvège'),('PM','Saint-Pierre et Miquelon'),('RE','Réunion'),('SE','Suède'),('SG','Singapour'),('US','Etats Unis');
/*!40000 ALTER TABLE `pays` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-06-11 10:02:20
