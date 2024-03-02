-- Potrebujem ziskat uzivatelov ktori komentovali prispevky ktore zalozil pouzivatel na vstupe.
-- 1. cast. Ziskat vsetky prispevky od pouzivatela
-- 2. cast. najst vsetkych userov ktory komentovali prispevky pouzivatela

-- Vypracujte zoznam diskutuj´ucich pre pouˇz´ıvateˇla user id, obsahuj´uci pouˇz´ıvateˇlov, ktor´ı komentovali pr´ıspevky,
-- ktor´e dan´y pouˇz´ıvateˇl zaloˇzil alebo na ktor´ych komentoval. Usporiadajte pouˇz´ıvateˇlov v z´avislosti od d´atumu ich
-- registr´acie, zaˇc´ınaj´uc s t´ymi, ktor´ı sa zaregistrovali ako prv´ı.
-- JSON sch´ema HTTP odpovede sa nach´adza v s´ubore schemas/users.json. Pr´ıklad odpovede pre pouˇz´ıvatela s
-- ID 1076348 sa nach´adza v bloku 2.
-- 3

-- Previous query
SELECT *
FROM users -- Vyber userov
WHERE id IN (
    SELECT userid
    FROM comments
    WHERE postid IN ( -- Ktory komentovali
        SELECT id
        FROM posts
        WHERE posts.owneruserid = 1076348 -- Na poste vytvorenym userom s ID (parentid)
    )
    GROUP BY userid
    -- ORDER BY MAX(creationdate) DESC -- TODO I guess this is useless
)
ORDER BY users.creationdate
