Select *
From CovidProject..CovidDeaths
order by 3,4

--Select *
--From CovidProject..CovidVaccinations
--order by 3,4

--Select the data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From CovidProject..CovidDeaths
order by 1,2

--Looking at Total Cases vs Total Deaths
--Shows liklihood of dying if you contract Covid in the US

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidProject..CovidDeaths
Where location = 'United States'
order by 1,2


--Looking at the Total Cases vs Population
--SHows the percentage of the population that got Covid

Select location, date, population, total_cases,  (total_cases/population)*100 as PercentageGotCovid
From CovidProject..CovidDeaths
Where location = 'United States'
order by 1,2

--Looking at countries with highest infection rate compared to population

Select location, population, MAX(total_cases)as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentagePopulationInfected
From CovidProject..CovidDeaths
--Where location = 'United States'
Group by location, population
order by PercentagePopulationInfected desc


--Showing the countries with the highest Death Count per Population
--(Varchar 255 needs to be cast as int)

Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidProject..CovidDeaths
Where continent is not null
Group by location
order by TotalDeathCount desc

--LET'S BREAK THINGS DOWN BY CONTINENT

SELECT continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidProject..CovidDeaths
--WHERE location = 'United States'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--Showing continents with the highest death count per population

SELECT continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidProject..CovidDeaths
--WHERE location = 'United States'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


--GLOBAL NUMBERS

Select date, SUM(new_cases), --total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidProject..CovidDeaths
--Where location = 'United States'
WHERE continent is not null
GROUP BY date
order by 1,2


--GLOBAL TOTAL CASES, TOTAL DEATHS, DEATH PERCENTAGE

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(New_deaths as int))/SUM(New_cases)/100 as DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

--Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
(RollingPeopleVaccinated/population)*100
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
ON dea.location = vac.location 
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--USE CTE

With PopvsVac (Continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
ON dea.location = vac.location 
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac




--TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated (
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
SELECT Continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated
FROM (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
    FROM CovidProject..CovidDeaths dea
    JOIN CovidProject..CovidVaccinations vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
) AS PopvsVac

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated (
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
SELECT Continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated
FROM (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
    FROM CovidProject..CovidDeaths dea
    JOIN CovidProject..CovidVaccinations vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
) AS PopvsVac

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Creating view to store data for later visualizations

CREATE View PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
    FROM CovidProject..CovidDeaths dea
    JOIN CovidProject..CovidVaccinations vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL