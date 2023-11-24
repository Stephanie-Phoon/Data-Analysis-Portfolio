/* Order the result based on the values 
in the third column in ascending order, 
and then by the values in the fourth column 
in ascending order as well.*/
SELECT * 
FROM CovidDeaths
WHERE continent is not null
ORDER by 3,4;

-- Select data that we are going to be using 

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER by 1,2;

-- Looking at Total cases vs Total Deaths 
-- Shows likelihood of dying if you contract covid in United State
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths * 100.0 / total_cases) as DeathPercentage
FROM 
    CovidDeaths
WHERE location like '%state%'
ORDER BY 1, date(2);

-- Looking at total_cases vs population
-- Shows what percentage of population got covid
SELECT 
    location, 
    date, 
	population,
    total_cases, 
    (total_cases * 100.0 / population) as PercentofPopulationInfected
FROM 
    CovidDeaths
WHERE location like '%state%'
ORDER BY 1, date(2);

-- What country has the highest infection rate compared to population? 
SELECT 
    location, 
	population,
    max(total_cases) as HighestInfectionCount,
    max((total_cases * 100.0 / population)) as PercentofPopulationInfected
FROM 
    CovidDeaths
GROUP by location, population
ORDER BY PercentofPopulationInfected DESC;

-- Showing COuntries with highest death count per population
-- notice that total_deaths data type is text 
SELECT 
    location, 
    max(CAST(total_deaths as INT)) as TotalDeathCount
FROM 
    CovidDeaths
-- notice that World, Europe, North America which are continent instead of country
WHERE continent is not null
GROUP by location
ORDER BY TotalDeathCount DESC;

-- Break down by continent
SELECT 
    location, 
    max(CAST(total_deaths as INT)) as TotalDeathCount
FROM 
    CovidDeaths
-- filtering countries 
WHERE continent is null
GROUP by location
ORDER BY TotalDeathCount DESC;

-- showing continent with the highest death_count per population
SELECT 
    continent, 
    max(CAST(total_deaths as INT)) as TotalDeathCount
FROM 
    CovidDeaths
WHERE continent is NOT null
GROUP by continent
ORDER BY TotalDeathCount DESC; 

-- Global numbers 
SELECT 
	sum(new_cases) as total_cases, 
	sum(cast(new_deaths as INT)) as total_deaths,
	sum(new_deaths*100.0)/sum(new_cases) as DeathPercentage 
FROM CovidDeaths
WHERE continent is not NULL
ORDER by 1;

-- join two table 
-- total population vs vaccination
-- rolling bases 
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INTEGER)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingPeopleVaccinated,
	--(RollingPeopleVaccinated*100.0)/population
FROM 
    CovidDeaths dea
JOIN 
    CovidVaccinations vac
ON 
    dea.location = vac.location
    AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL 
ORDER BY 
    2, date(dea.date);
	
	
-- Use Common Table Expression CTE to perform Calculation on Partition By in previous query 
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) 
as (
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INTEGER)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated*100.0)/population
FROM 
    CovidDeaths dea
JOIN 
    CovidVaccinations vac
ON 
    dea.location = vac.location
    AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL 
)
SELECT *, 
	(RollingPeopleVaccinated*100.0)/population
FROM PopVsVac

-- Create the temporary table
CREATE TEMP TABLE IF NOT EXISTS PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Insert data into the temporary table
INSERT INTO PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INTEGER)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM
    CovidDeaths dea
JOIN
    CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

-- Select data from the temporary table
SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100 as PercentPopulationVaccinated
FROM
    PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INTEGER)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null ;

SELECT * 
FROM PercentPopulationVaccinated