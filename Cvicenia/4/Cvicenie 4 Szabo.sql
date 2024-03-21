-- Uloha 1
-- select sum((CURRENT_DATE - joined_at)) / count(*) as average_day
-- from projects_programmers

-- Uloha 2
-- select sum((CURRENT_DATE - joined_at)) as overall_days
-- from programmers
-- join projects_programmers on programmers.id = programmer_id
-- join projects on projects_programmers.project_id = projects.id
-- join languages on projects.language_id = languages.id
-- where label = 'ruby'

-- Uloha 3
-- select project_id, count(distinct  programmer_id)
-- from projects_programmers
-- group by project_id

-- Uloha 4
-- select name, (CURRENT_DATE - joined_at) as days_worked
-- select sum((CURRENT_DATE - joined_at)) as days_worked, name
-- from projects_programmers
-- join projects on projects.id = projects_programmers.project_id
-- group by name

-- Uloha 5
-- select name, max(programmers_count)
-- from (
--     select name, count(programmer_id) as programmers_count
--     from projects_programmers
--     join projects on projects.id = projects_programmers.project_id
--     group by projects_programmers.project_id, name
--     order by programmers_count DESC
-- ) as p
group by name
