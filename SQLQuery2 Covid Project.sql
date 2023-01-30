SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


--SELECT * 
--FROM PortfolioProject..Covid_Vaccinations
--ORDER BY 3,4

-- Select Data that we will be be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- I had to pause at this point and work backwards. I realised I did not add the "population"
-- back into the excel sheet when I was cleaning the raw data. 
--population column is now added in both tables and no errors occured when executing the command above. 

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2
-- We will be looking at total cases vs total deaths

-- How many cases are there in x country, how many deaths do they have per case
-- SHows liklihod of dying if you contract covid in your country


SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
WHERE continent is not null
ORDER BY 1,2
-- Looking at the total cases vs population 
--Shows what percentage of population has contracted covid

SELECT location, date,population, total_cases, (total_cases/population)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
ORDER BY 1,2
--Looking at countrues wuth highest infection rate compared to population 

SELECT location,population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases)/population)*100 AS PercentofPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentofPopulationInfected desc

-- Showing the countries with the highest death count per population 

SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc

-- LETS BREAK THRINGS DOWN BY CONTINENT

SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

--More accurate number representation. However, with this formula we include the columns that are not continents

SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc


-- Global Numbers 


SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths,
SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY DATE 
ORDER BY 1,2;

-- Looking at total population vs vaccinations 



SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations AS int)) -- OVER (Partition BY dea.location ORDER BY dea.location, dea.date)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent is not null 
ORDER BY 1,2,3

-- Msg 8115, Level 16, State 2, Line 115
--Arithmetic overflow error converting expression to data type int.

SELECT CONVERT(int,dea.continent), dea.location, dea.date, dea.population, CONVERT(int,vac.new_vaccinations), 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent is not null 
ORDER BY 2,3

-- Msg 8115, Level 16, State 2, Line 115
--Arithmetic overflow error converting expression to data type int.

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Still recieving error message but with the above script I was able to get the information to populate

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
SELECT*, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

-- Temp Table


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating view to store in later visuilzatio 

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
