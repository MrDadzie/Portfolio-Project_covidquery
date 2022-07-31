--select *
--from CovidDeath
--order by 3,4

------select*
------from CovidVaccination
------order by 3,4

--new_cases represent the increase in cases
--total_cases represent the case count at a particular point in time

 
--Analyzing the global data
--1. Determinine the highest recorded cases per population by continent in the world

with t1 as (
select distinct location,population,continent, max(total_cases) over (partition by location order by location) as totalcases
from CovidDeath
where continent is not null 
group by location, population,continent ,total_cases
)

select distinct continent,sum(totalcases) over (partition by continent order by continent) as Overall_TotalCases,
sum(population) over (partition by continent order by continent) as Overall_Population, 
(sum(totalcases) over (partition by continent order by continent)/sum(population) over (partition by continent order by continent)) as Case_per_Pop
from t1

--VIEW1 -for data visualization
create view Cont_caseperpop as

with t1 as (
select distinct location,population,continent, max(total_cases) over (partition by location order by location) as totalcases
from CovidDeath
where continent is not null 
group by location, population,continent ,total_cases
)

select distinct continent,sum(totalcases) over (partition by continent order by continent) as Overall_TotalCases,
sum(population) over (partition by continent order by continent) as Overall_Population, 
(sum(totalcases) over (partition by continent order by continent)/sum(population) over (partition by continent order by continent)) as Case_per_Pop
from t1


--2. Determine the highest chance of death per continent
with t1 as (
select distinct location,population,continent, max(total_cases) over (partition by location order by location) as totalcases,
max(total_deaths) over (partition by location order by location) as totaldeaths
from CovidDeath
where continent is not null 
group by location, population,continent ,total_cases,total_deaths
)

select distinct continent,sum(totalcases) over (partition by continent order by continent) as Overall_TotalCases,
sum(cast([totaldeaths] as int)) over (partition by continent order by continent) as Overall_deaths, 
(sum(cast([totaldeaths] as int)) over (partition by continent order by continent))/(sum(totalcases) over (partition by continent order by continent)) as DeathChances
from t1


--VIEW2
create view Cont_deathchance as
with t1 as (
select distinct location,population,continent, max(total_cases) over (partition by location order by location) as totalcases,
max(total_deaths) over (partition by location order by location) as totaldeaths
from CovidDeath
where continent is not null 
group by location, population,continent ,total_cases,total_deaths
)

select distinct continent,sum(totalcases) over (partition by continent order by continent) as Overall_TotalCases,
sum(cast([totaldeaths] as int)) over (partition by continent order by continent) as Overall_deaths, 
(sum(cast([totaldeaths] as int)) over (partition by continent order by continent))/(sum(totalcases) over (partition by continent order by continent)) as DeathChances
from t1

--Comment: From query 1 and 2, Africa has the lowest infection count per population but have the highest death chance

--3.Determine the top 100 hotspot countries with the highest cases

with tab1 as (
select location, max(total_cases) as totalcases  --totalcases represent the case count thus far
from CovidDeath
where continent is not null and location
group by location
),

tab2 as(
select *, dense_rank() over (order by totalcases desc) rnk
from tab1)

select *
from tab2
where rnk <=100 

4. --Determinine the highest chance of death  by country
--chance of death = max(total_death/total cases)

With t1 as( 
select location,continent, max(total_deaths) as totaldeaths, max(total_cases) as totalcases
from CovidDeath
where continent is not null
group by location,continent
),

t2 as(
select location,continent, totalcases,totaldeaths
,(totaldeaths/totalcases) as deathchance
from t1
)

select *
from t2
group by location,continent,totalcases, totaldeaths, deathchance
order by 5 desc

--Query 4 and 5 show that USA has the highest number of cases, Yemen(which is outside the hotspot areas) leads the count on the highest death rate

--5. Determine the number of vaccinations administered per continent vs total cases per continent
 
 drop table if exists temp
 create table temp (location nvarchar(100),
                    continent nvarchar(100),
					TotalVac bigint,
					TotalCases bigint,
					FullyVaccinated bigint,
					population float
				)


Insert into temp  
select distinct vac.location,cov.continent continent, max (vac.people_vaccinated) over (partition by vac.location order by vac.location) TotalVac, 
max(cov.total_cases) over (partition by vac.location order by vac.location) Totalcases, 
max(vac.people_fully_vaccinated) over (partition by vac.location order by vac.location) FullyVaccinated, cov.population as cnt_Population
from CovidDeath cov
join CovidVaccination vac
on cov.location =vac.location and cov.date =vac.date
where cov.continent is not null
group by vac.location, cov.continent, vac.people_vaccinated, cov.total_cases,vac.people_fully_vaccinated,cov.population

select distinct continent, sum(nullif (cast([Totalcases] as bigint),0))over (partition by continent order by continent) as Overall_Tcases, 
sum( nullif (cast([TotalVac] as bigint),0)) over (partition by continent order by continent) as Overall_Vac,
sum( nullif (cast([FullyVaccinated] as bigint),0)) over (partition by continent order by continent) as Overall_FulVac,
sum(population) over (partition by continent order by continent) as Overall_Pop,
(sum( nullif (cast([FullyVaccinated] as bigint),0)) over (partition by continent order by continent)/(sum(population) over (partition by continent order by continent)))*100 
as FulVac_perc_Population
from temp
group by continent, Totalcases, Totalvac, FullyVaccinated, population
order by 3

--VIEW 3
create view ContFullVacPop as

select distinct continent, sum(nullif (cast([Totalcases] as bigint),0))over (partition by continent order by continent) as Overall_Tcases, 
sum( nullif (cast([TotalVac] as bigint),0)) over (partition by continent order by continent) as Overall_Vac,
sum( nullif (cast([FullyVaccinated] as bigint),0)) over (partition by continent order by continent) as Overall_FulVac,
sum(population) over (partition by continent order by continent) as Overall_Pop,
(sum( nullif (cast([FullyVaccinated] as bigint),0)) over (partition by continent order by continent)/(sum(population) over (partition by continent order by continent)))*100 
as FulVac_perc_Population
from temp
group by continent, Totalcases, Totalvac, FullyVaccinated, population

select ContFuz

--comment : Asia has the largest number of people vaccinated



--6. Determine the countries the countries that are yet to get vaccinated

with t1 as(
select distinct location,continent, max(total_vaccinations) over (partition by location order by location) totalVac
from CovidVaccination
where continent is not null
group by location, continent, total_vaccinations
)

select *
from t1
where totalVac is  null
group by location,continent, totalVac

/*Comment: Vatican is the only state in europe where vaccination has not been administered; 
Also, Eritrea is the only location in Africa where vaccination has not been administered;
*/


--7. Determine  the country with the highest case recorded in each continent

with tab1 as
 (select distinct location, continent, max(total_cases) over (partition by location order by location) as Totalcases
 from CovidDeath
 where continent is not null
 group by location, continent, total_cases),

 tab2 as(
 select continent,Location,Totalcases, max(Totalcases) over (partition by continent order by continent) HighestCase_Count
 from tab1)

 select *
 from tab2 
 where Totalcases = HighestCase_Count
 group by continent,location, Totalcases,HighestCase_Count
 order by 3


 --VIEW 4
 create view Cont_HighestcaseCountry as
 
with tab1 as
 (select distinct location, continent, max(total_cases) over (partition by location order by location) as Totalcases
 from CovidDeath
 where continent is not null
 group by location, continent, total_cases),

 tab2 as(
 select continent,Location,Totalcases, max(Totalcases) over (partition by continent order by continent) HighestCase_Count
 from tab1)

 select *
 from tab2 
 where Totalcases = HighestCase_Count
 group by continent,location, Totalcases,HighestCase_Count
 

 --8. Determine the countries with the highest deathcases per total cases across the continent
 
 with tab1 as
 (select distinct location, continent, max(total_cases) over (partition by location order by location) as Totalcases
 ,max(total_deaths) over (partition by location order by location) Totaldeaths,
 (max(total_deaths) over (partition by location order by location)/ max(total_cases) over (partition by location order by location))*100 as Rate 
 from CovidDeath
 where continent is not null 
 group by location, continent, total_cases,total_deaths
 ),

 tab2 as(
 select continent,Location,Totalcases,Rate, max(Totalcases) over (partition by continent order by continent) HighestCase_Count,Totaldeaths,
 max(Rate) over (partition by continent order by continent) RateDeath_perc
 from tab1)

 select *
 from tab2 
 where Rate =RateDeath_perc
 group by continent,location, Totalcases,Totaldeaths,HighestCase_Count, Rate,RateDeath_perc
 order by 7
 
 --Comment: Yemen has the highest percentage of death to cases recorded
 --View 5
create view Cont_HighestRateofDeath as

 with tab1 as
 (select distinct location, continent, max(total_cases) over (partition by location order by location) as Totalcases
 ,max(total_deaths) over (partition by location order by location) Totaldeaths,
 (max(total_deaths) over (partition by location order by location)/ max(total_cases) over (partition by location order by location))*100 as Rate 
 from CovidDeath
 where continent is not null 
 group by location, continent, total_cases,total_deaths
 ),

 tab2 as(
 select continent,Location,Totalcases,Rate, max(Totalcases) over (partition by continent order by continent) HighestCase_Count,Totaldeaths,
 max(Rate) over (partition by continent order by continent) RateDeath_perc
 from tab1)

 select *
 from tab2 
 where Rate =RateDeath_perc
 group by continent,location, Totalcases,Totaldeaths,HighestCase_Count, Rate,RateDeath_perc
 








