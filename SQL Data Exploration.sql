-- DATA COLLECTED FROM https://ourworldindata.org/covid-deaths ON OCT. 28, 2021 --
-- Data separated into 2 tables using Excel

SELECT *
FROM PortfolioProject..covidDeaths
ORDER BY location, date

SELECT *
FROM PortfolioProject..covidVaccinations
ORDER BY location, date

SELECT DISTINCT location
FROM PortfolioProject..covidDeaths
--WHERE continent IS NULL
ORDER BY location

-- DEATHS --

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..covidDeaths
ORDER BY location, date

-- Total Cases vs Total Deaths
-- Shows approximate chance of death from covid by country
SELECT location, date, continent, total_cases, total_deaths, (total_deaths/total_cases)*100 AS case_death_ratio
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Total Cases vs. Population
-- Shows percentage of Japanese population that contracted covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS case_rate
FROM PortfolioProject..covidDeaths
WHERE location='Japan'
ORDER BY date

-- Countries with Highest Total Infection Count per Population
SELECT location, population, MAX(total_cases) AS highest_infection_count, (MAX(total_cases)/population)*100 AS infection_rate
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infection_rate DESC

-- Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- BREAKING THINGS DOWN BY CONTINENT --

-- Continents with the Most Deaths per Population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC


-- GLOBAL NUMBERS --

-- Total Cumulative Death Rate on Oct. 28th
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_rate
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL

-- Daily Global Death Rate
SELECT date, SUM(new_cases) AS daily_cases, SUM(CAST(new_deaths AS INT)) AS daily_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_rate
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- --

-- VACCINATIONS --

-- Total daily Vaccines Administered using in total_vaccinations field
SELECT location, date, new_vaccinations, total_vaccinations
FROM PortfolioProject..covidVaccinations
WHERE continent IS NOT NULL
ORDER BY location, date

-- Total Vaccines Administered in Japan using cumulative sum of new_vaccinations
--NOTE: Not completely accurate because sometimes 'total_vaccinations' has data entries in records where 'new_vaccinations' is NULL
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccines_administered
FROM PortfolioProject..covidDeaths dea
JOIN PortfolioProject..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location='Japan'
ORDER BY dea.location, dea.date


-- Rough estimated percentage of fully vaxxed people in Japan, unrealistically assuming each person gets 2 doses before the next person gets 1
-- USING CTE --
WITH AdministeredVax (continent, location, date, population, new_vaccination, total_vaccines_administered)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccines_administered
FROM PortfolioProject..covidDeaths dea
JOIN PortfolioProject..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location='Japan'
--ORDER BY dea.location, dea.date
)
SELECT *, (total_vaccines_administered/2/population)*100
FROM AdministeredVax


-- USING TEMP TABLE --
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
total_vaccines_administered numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccines_administered
FROM PortfolioProject..covidDeaths dea
JOIN PortfolioProject..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location='Japan'
--ORDER BY dea.location, dea.date

SELECT *, (total_vaccines_administered/2/population)*100
FROM #PercentPopulationVaccinated


-- VIEWS --

CREATE VIEW JapanVaccinesAdministered AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccines_administered
FROM PortfolioProject..covidDeaths dea
JOIN PortfolioProject..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location='Japan'

CREATE VIEW DeathsByCountry AS
SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location

CREATE VIEW DeathsByContinent AS
SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY continent




-- QUERIES FOR TABLEAU --

-- This query used to double check numbers before finalizing Tableau queries
SELECT location, date, new_cases, total_cases, total_deaths
FROM PortfolioProject..covidDeaths
--WHERE location='World'
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International')
ORDER BY location, date

-- 1. Global deaths and death rate as of Oct. 28th 2021

SELECT MAX(total_cases) as total_cases, MAX(CAST(total_deaths AS INT)) AS total_deaths, MAX(CAST(total_deaths AS INT))/MAX(total_cases)*100 AS DeathRate
From PortfolioProject..covidDeaths
--Where location like '%states%'
WHERE location='World'
--GROUP BY location, date
ORDER BY 1,2

-- 2. Total deaths by continent

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeaths
FROM PortfolioProject..covidDeaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeaths DESC


-- 3. Highest Infection rate by Country

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS InfectionRate
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionRate DESC


-- 4. Highest daily cumulative infection rate by country

SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS InfectionRate
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population, date
ORDER BY InfectionRate DESC