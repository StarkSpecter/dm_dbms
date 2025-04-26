SELECT * FROM clients -- * плохо но клиент очень большой
WHERE id IN (
    SELECT client_id FROM accounts
    WHERE balance > 5000
);

SELECT * FROM clients
WHERE citizenship_id = (
    SELECT id FROM citizenships WHERE name = 'Russia'
);


WITH friedrich_accounts AS (
    SELECT id
    FROM accounts
    WHERE client_id = (
        SELECT id
        FROM clients
        WHERE name = 'Friedrich'
    )
)
SELECT *
FROM transactions
WHERE sender_account_id IN (SELECT id FROM friedrich_accounts)
   OR recipient_account_id IN (SELECT id FROM friedrich_accounts);


SELECT AVG(balance) AS average_balance FROM accounts;


SELECT SUM(amount) AS total_deposits FROM deposits;


SELECT COUNT(*) AS total_clients FROM clients;


SELECT id, balance, balance * 2 AS double_balance
FROM accounts;


SELECT MIN(end_date - created_at) AS min_duration
FROM deposits;


SELECT
    MIN(balance) AS min_balance,
    MAX(balance) AS max_balance,
    AVG(balance) AS average_balance,
    SUM(balance) AS total_balance
FROM accounts;


SELECT *
FROM deposits
WHERE closed_at IS NULL;


SELECT * FROM clients
WHERE id IN (SELECT client_id FROM deposits);


SELECT clients.id, clients.name, surname, birthday, vendor_id, type, lasts_until from clients CROSS JOIN cards;


SELECT * FROM vendors INNER JOIN loans on loans.amount < 25000 order by loans.id;

-- клиенты беларусы с аккаунтами и вкладами
SELECT c.*
FROM clients c
WHERE c.citizenship_id = (SELECT id FROM citizenships WHERE name = 'Belarus')
  AND EXISTS (
    SELECT 1 FROM accounts a
    WHERE a.client_id = c.id AND a.balance > 5000
)
  AND EXISTS (
    SELECT 1 FROM deposits d
    WHERE d.client_id = c.id
);

-- сотруднички с зп больше среднего
SELECT e.*
FROM employees e
WHERE e.department_id = (SELECT id FROM departments WHERE name = 'IT')
  AND e.salary > (
    SELECT AVG(salary)
    FROM employees
    WHERE department_id = e.department_id
);

-- Клиенты + их счета + валюта счета
SELECT c.name, c.surname, a.id AS account_id, a.balance, curr.abbreviation
FROM clients c
         INNER JOIN accounts a ON c.id = a.client_id
         INNER JOIN currencies curr ON a.currency_id = curr.id;

-- Клиенты (все) + депозиты
SELECT c.name, c.surname, d.amount, d.interest_percentage
FROM clients c
         LEFT OUTER JOIN deposits d ON c.id = d.client_id;

-- перемешка )
SELECT c.name, c.surname, curr.abbreviation
FROM clients c
         CROSS JOIN currencies curr;

-- средний баланс по валютам
SELECT curr.abbreviation, AVG(a.balance) AS average_balance
FROM accounts a
         JOIN currencies curr ON a.currency_id = curr.id
GROUP BY curr.abbreviation;


-- количество по гражданствам
SELECT ctz.name AS citizenship, COUNT(c.id) AS client_count
FROM clients c
         JOIN citizenships ctz ON c.citizenship_id = ctz.id
GROUP BY ctz.name;

-- валюты со средним баланос больше 5000
SELECT curr.abbreviation, AVG(a.balance) AS average_balance
FROM accounts a
         JOIN currencies curr ON a.currency_id = curr.id
GROUP BY curr.abbreviation
HAVING AVG(a.balance) > 5000;


--список людей (клиентов и работяг)
SELECT name, surname, email, phone_number
FROM clients
UNION
SELECT name, surname, email, phone_number
FROM employees;


-- вытянуть валюты из депозитов и счетов
SELECT abbreviation AS currency_type
FROM currencies
WHERE id IN (SELECT currency_id FROM accounts)
UNION
SELECT abbreviation AS currency_type
FROM currencies
WHERE id IN (SELECT currency_id FROM deposits);

-- найти клиентов со счетами + картами
SELECT c.*
FROM clients c
WHERE EXISTS (
    SELECT 1 FROM accounts a WHERE a.client_id = c.id
)
  AND EXISTS (
    SELECT 1 FROM cards cr WHERE cr.account_id IN (SELECT id FROM accounts WHERE client_id = c.id)
);


-- Создание резервной таблицы
-- CREATE TABLE clients_backup AS TABLE clients WITH NO DATA;

-- Вставка данных
-- INSERT INTO clients_backup (name, surname, middle_name, email, phone_number, address, citizenship_id, birthday, created_at, deleted_at, comments)
-- SELECT name, surname, middle_name, email, phone_number, address, citizenship_id, birthday, created_at, deleted_at, comments
-- FROM clients;


EXPLAIN
WITH friedrich_accounts AS (
    SELECT id
    FROM accounts
    WHERE client_id = (
        SELECT id
        FROM clients
        WHERE name = 'Friedrich'
    )
)
SELECT *
FROM transactions
WHERE sender_account_id IN (SELECT id FROM friedrich_accounts)
   OR recipient_account_id IN (SELECT id FROM friedrich_accounts);

-- представление для транзакций клиентика
CREATE VIEW friedrich_transactions AS
WITH friedrich_accounts AS (
    SELECT id
    FROM accounts
    WHERE client_id = (
        SELECT id
        FROM clients
        WHERE name = 'Friedrich'
    )
)
SELECT *
FROM transactions
WHERE sender_account_id IN (SELECT id FROM friedrich_accounts)
   OR recipient_account_id IN (SELECT id FROM friedrich_accounts);

-- топ 3 баланса по клиенту
SELECT *
FROM (
         SELECT c.name, c.surname, a.balance,
                ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY a.balance DESC) AS rn
         FROM clients c
                  JOIN accounts a ON c.id = a.client_id
     ) sub;



