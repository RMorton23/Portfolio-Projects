SELECT *
FROM portfolio_projects..[covid deaths]
WHERE continent is not null
ORDER BY 3,4


--SELECT *
--FROM portfolio_projects..[covid vaccinations]
--ORDER BY 3,4

-- Select data that we are going to be using

SELECT 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM portfolio_projects..[covid deaths]
WHERE continent is not null
ORDER BY 1,2

--looking at total cases vs total deaths
-- shows the likelihood of dying if you contract covid in the USA
SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS death_percentage
FROM portfolio_projects..[covid deaths]
WHERE location like '%states%'
WHERE continent is not null
ORDER BY 1,2

--Looking at total cases vs population
--shows what percentage of population got covid
SELECT 
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 AS population_infection_percentage
FROM portfolio_projects..[covid deaths]
WHERE location like '%states%'
WHERE continent is not null
ORDER BY 1,2

--looking at countries with highest infection rate compared to population

SELECT
location,
population,
MAX(total_cases) AS highest_infection_count, 
MAX((total_Cases/population))*100 AS population_infection_percentage
FROM portfolio_projects..[covid deaths]
WHERE continent is not null
GROUP BY 
	population,
	location
ORDER BY population_infection_percentage DESC

--looking at countries with highest death count per population

SELECT
location,
MAX(cast(total_deaths as int)) AS total_death_count
FROM portfolio_projects..[covid deaths]
WHERE continent is not null
GROUP BY 
	population,
	location
ORDER BY total_death_count DESC

--lets break things down by continent


--showing continents with highest death count

SELECT
continent,
MAX(cast(total_deaths as int)) AS total_death_count
FROM portfolio_projects..[covid deaths]
WHERE continent is not null
GROUP BY 
	continent
ORDER BY total_death_count DESC

--looking at which continent had the highest infection rate per population

SELECT
continent,
MAX(total_cases) AS highest_infection_count, 
MAX((total_Cases/population))*100 AS population_infection_percentage
FROM portfolio_projects..[covid deaths]
WHERE continent is not null
GROUP BY 
	continent
ORDER BY population_infection_percentage DESC


--global numbers

SELECT 
	date,
	SUM(new_cases) AS global_cases,
	SUM(CAST(new_deaths AS int)) AS global_deaths,
	SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS global_death_percentage
FROM portfolio_projects..[covid deaths]
WHERE continent is not null
GROUP BY date
ORDER BY 1,2




--joining covid vaccines on covid deaths to look at total population vs vaccinations

SELECT 
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination_count
FROM
 portfolio_projects..[covid deaths] dea
 JOIN portfolio_projects..[covid vaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--use cte

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccination_count)
AS
(
SELECT 
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination_count
FROM
 portfolio_projects..[covid deaths] dea
 JOIN portfolio_projects..[covid vaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)

SELECT *, (rolling_vaccination_count/population)*100 AS percentage_population_vaccinated
FROM PopvsVac


--Temp table
DROP TABLE IF exists #percent_population_vaccinated --workaround if your temp table 'has already been created'
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)



INSERT INTO #percent_population_vaccinated
SELECT 
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination_count
FROM
 portfolio_projects..[covid deaths] dea
 JOIN portfolio_projects..[covid vaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (rolling_people_vaccinated/population)*100
FROM #percent_population_vaccinated


--create views to store data later for viz
--this view is for percent population vaccinated
CREATE VIEW percent_population_vaccinated AS 
SELECT 
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination_count
FROM
 portfolio_projects..[covid deaths] dea
 JOIN portfolio_projects..[covid vaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3


--this view is global cases and global deaths
CREATE VIEW global_numbers AS
SELECT 
	date,
	SUM(new_cases) AS global_cases,
	SUM(CAST(new_deaths AS int)) AS global_deaths,
	SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS global_death_percentage
FROM portfolio_projects..[covid deaths]
WHERE continent is not null
GROUP BY date
--ORDER BY 1,2

--this view shows death count by continent
CREATE View total_death_continent AS
SELECT
continent,
MAX(cast(total_deaths as int)) AS total_death_count
FROM portfolio_projects..[covid deaths]
WHERE continent is not null
GROUP BY 
	continent
--ORDER BY total_death_count DESC

--creating view of countries with highest infection count

CREATE VIEW countries_infection_count AS
SELECT
location,
population,
MAX(total_cases) AS highest_infection_count, 
MAX((total_Cases/population))*100 AS population_infection_percentage
FROM portfolio_projects..[covid deaths]
WHERE continent is not null
GROUP BY 
	population,
	location
--ORDER BY population_infection_percentage DESC


--this view looks at total populations vs total vaccinations

CREATE VIEW population_vaccination_rate AS
SELECT 
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination_count
FROM
 portfolio_projects..[covid deaths] dea
 JOIN portfolio_projects..[covid vaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3