-- Zadanie 1
-- SELECT * FROM programmers

-- Zadanie 2
-- SELECT * FROM programmers WHERE programmers.name LIKE 'R%';

-- Zadanie 3
-- SELECT * FROM programmers WHERE programmers.name LIKE 'R%' ORDER BY public.programmers.signed_in_at DESC LIMIT 1;

-- Zadanie 4
-- SELECT name FROM programmers WHERE length(name)<12;

-- Zadanie 5
-- SELECT left(name, 12) FROM programmers;

-- Zadanie 6
-- SELECT upper(reverse(name)) FROM programmers;

-- Zadanie 7
-- SELECT split_part(name, ' ', 1) FROM programmers;

-- Zadanie 8
-- SELECT * FROM programmers WHERE programmers.signed_in_at::text LIKE '2016-%'

-- Zadanie 9
-- SELECT * FROM programmers WHERE programmers.signed_in_at::text LIKE '2016-02-%'

-- Zadanie 10
-- SELECT name, ('2016-04-01' - programmers.signed_in_at) as count FROM programmers ORDER BY count ASC

-- Zadanie 11
-- SELECT DISTINCT label
-- FROM languages
-- RIGHT JOIN projects ON languages.id = projects.language_id;

-- Zadanie 12
-- SELECT DISTINCT label
-- FROM languages
-- RIGHT JOIN projects ON languages.id = projects.language_id
-- WHERE projects.created_at::text LIKE '2014-%';

-- Zadanie 13
-- SELECT *
-- FROM projects
-- RIGHT JOIN languages ON languages.id = projects.language_id
-- WHERE projects.language_id IN (1, 2);

-- Zadanie 14
-- SELECT programmers.name
-- FROM programmers
-- FULL JOIN projects_programmers ON programmers.id = projects_programmers.programmer_id
-- FULL JOIN projects ON projects_programmers.project_id = projects.id
-- FULL JOIN languages ON projects.language_id = languages.id
-- WHERE label = 'python';

-- Zadanie 15
-- SELECT * -- programmers.name
-- FROM programmers
-- FULL JOIN projects_programmers ON programmers.id = projects_programmers.programmer_id
-- FULL JOIN projects ON projects_programmers.project_id = projects.id
-- FULL JOIN languages ON projects.language_id = languages.id
-- WHERE owner = true; -- TODO