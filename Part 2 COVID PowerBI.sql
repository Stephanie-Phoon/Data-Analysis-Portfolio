/* 
Queries used for PowerBI */

-- 1. Total number of death vs cases
SELECT 
	sum(new_cases) as total_cases, 
	sum(CAST(new_deaths as INT)) as total_deaths,
	sum(cast(new_deaths as INT))*100.0/sum(new_cases) as DeathPercentage 
FROM CovidDeaths 
where continent is not null 
order by 1, 2;

-- 2. Total Death in different Continent
SELECT 
	location, 
	sum(cast(new_deaths as INT)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is null 
and location not in ('World', 'European Union', 'International')
GROUP by location 
order by TotalDeathCount DESC;

-- 3. Percent Population Infected
SELECT 
	location,
	population,
	max(total_cases) as HighestInfectionCount,
	max(total_cases*100.0/population)as PercentPopulationInfected
FROM CovidDeaths
GROUP by location, population
ORDER by PercentPopulationInfected DESC;

-- 4. Percent Population Infected (time series)
SELECT
	location,
	population,
	date,
	max(total_cases) as HighestInfectionCount,
	max(total_cases*100.0/population)as PercentPopulationInfected
FROM CovidDeaths
GROUP by location, population, date
ORDER by PercentPopulationInfected DESC;