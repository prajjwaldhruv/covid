use covid;
SELECT * FROM CovidDeaths ORDER BY 3,4;


--Looking at Total Cases, Total Deaths and Mortality Rate
SELECT location, date, total_cases, total_deaths, (total_deaths*100/total_cases) AS mortalitly_rate
FROM CovidDeaths
WHERE location like '%India%'
ORDER BY 1,2;


--Looking at Total Cases vs Population
SELECT location, date, total_cases, population, (total_cases*100/population) AS infection_rate
FROM CovidDeaths
WHERE location LIKE '%India%'
ORDER BY 1,2;


--Looking at countries with highest infection rate
SELECT location, max(total_cases) AS total_count, population, MAX(total_cases*100/population) AS infection_rate
FROM CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC;


--Showing countries with highest death count per unit population
SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;


--BREAKING DOWN ACCORDING TO CONTINENT
--Showing continents with the highest death count
SELECT location, MAX(CAST(total_deaths AS INT)) AS Total_death_count
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC;


--GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS total_new_cases, SUM(CAST(new_deaths AS INT)) as total_deaths, (SUM(CAST(new_deaths AS INT))*100/SUM(new_cases)) AS mortality_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;


--Looking at Total Population and Vaccination
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(CAST(vacc.new_vaccinations AS INT)) OVER (PARTITION BY deaths.location, deaths.date) AS RollingPeopleVaccinated
FROM CovidDeaths deaths
JOIN CovidVaccinations vacc
ON deaths.location = vacc.location
AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3;


-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVacc (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(CONVERT(int,vacc.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as RollingPeopleVaccinated
From CovidDeaths deaths
Join CovidVaccinations vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date
where deaths.continent is not null 
)
Select *, (RollingPeopleVaccinated*100/Population)
From PopvsVacc


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
);

Insert into #PercentPopulationVaccinated
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(CONVERT(int,vacc.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as RollingPeopleVaccinated
From CovidDeaths deaths
Join CovidVaccinations vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date;

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(CONVERT(int,vacc.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as RollingPeopleVaccinated
FROM CovidDeaths deaths
JOIN CovidVaccinations vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL 