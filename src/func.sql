-- Функция триггера для обновления балансов
CREATE OR REPLACE FUNCTION update_account_balances()
    RETURNS TRIGGER AS $$
BEGIN
    -- Вычесть сумму из отправителя
    UPDATE accounts
    SET balance = balance - NEW.amount
    WHERE id = NEW.sender_account_id;

    -- Добавить сумму получателю
    UPDATE accounts
    SET balance = balance + NEW.amount
    WHERE id = NEW.recipient_account_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера, который срабатывает после вставки новой транзакции
CREATE TRIGGER trg_update_balances
    AFTER INSERT ON transactions
    FOR EACH ROW
EXECUTE FUNCTION update_account_balances();


-- Функция триггера для проверки баланса
CREATE OR REPLACE FUNCTION check_sender_balance()
    RETURNS TRIGGER AS $$
DECLARE
    sender_balance numeric;
BEGIN
    -- Получить текущий баланс отправителя
    SELECT balance INTO sender_balance
    FROM accounts
    WHERE id = NEW.sender_account_id;

    -- Проверить, достаточно ли средств
    IF sender_balance < NEW.amount THEN
        RAISE EXCEPTION 'Недостаточно средств на счёте отправителя (ID: %). Баланс: %, Требуется: %',
            NEW.sender_account_id, sender_balance, NEW.amount;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера, который срабатывает перед вставкой новой транзакции
CREATE TRIGGER trg_check_balance
    BEFORE INSERT ON transactions
    FOR EACH ROW
EXECUTE FUNCTION check_sender_balance();


-- Функция триггера для создания основной учетной записи клиента
CREATE OR REPLACE FUNCTION create_default_account()
    RETURNS TRIGGER AS $$
BEGIN
    -- Вставить основной счет для нового клиента
    INSERT INTO accounts (client_id, balance, currency_id, comments)
    VALUES (NEW.id, 0, (SELECT id FROM currencies WHERE abbreviation = 'USD'), 'Основной счет');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера, который срабатывает после вставки нового клиента
CREATE TRIGGER trg_create_default_account
    AFTER INSERT ON clients
    FOR EACH ROW
EXECUTE FUNCTION create_default_account();


-- Функция триггера для пометки счетов клиента как удаленных
CREATE OR REPLACE FUNCTION mark_accounts_as_deleted()
    RETURNS TRIGGER AS $$
BEGIN
    -- Обновить поле deleted_at у всех счетов клиента
    UPDATE accounts
    SET deleted_at = CURRENT_TIMESTAMP
    WHERE client_id = NEW.id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера, который срабатывает перед обновлением клиента
CREATE TRIGGER trg_mark_accounts_deleted
    BEFORE UPDATE OF deleted_at ON clients
    FOR EACH ROW
    WHEN (NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL)
EXECUTE FUNCTION mark_accounts_as_deleted();


-- Хранимая процедура для перевода средств
CREATE OR REPLACE PROCEDURE transfer_funds(
    p_sender_account_id integer,
    p_recipient_account_id integer,
    p_amount numeric,
    p_message bpchar
)
    LANGUAGE plpgsql
AS $$
BEGIN
    -- Начало транзакции
    BEGIN
        -- Проверка достаточности средств
        IF (SELECT balance FROM accounts WHERE id = p_sender_account_id) < p_amount THEN
            RAISE EXCEPTION 'Недостаточно средств на счёте отправителя (ID: %).', p_sender_account_id;
        END IF;

        -- Вычесть сумму из отправителя
        UPDATE accounts
        SET balance = balance - p_amount
        WHERE id = p_sender_account_id;

        -- Добавить сумму получателю
        UPDATE accounts
        SET balance = balance + p_amount
        WHERE id = p_recipient_account_id;

        -- Вставить запись о транзакции
        INSERT INTO transactions (sender_account_id, recipient_account_id, amount, message)
        VALUES (p_sender_account_id, p_recipient_account_id, p_amount, p_message);

        -- Завершение транзакции
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            -- Откат транзакции в случае ошибки
            ROLLBACK;
            RAISE;
    END;
END;
$$;


-- Хранимая процедура для добавления депозита
CREATE OR REPLACE PROCEDURE add_deposit(
    p_client_id integer,
    p_amount numeric,
    p_interest_percentage real,
    p_interest_type integer,
    p_early_availability boolean,
    p_currency_id integer,
    p_duration_months integer, -- длительность вклада в месяцах
    p_comments text
)
    LANGUAGE plpgsql
AS $$
DECLARE
    deposit_end_date timestamp;
BEGIN
    -- Начало транзакции
    BEGIN
        -- Вычислить дату окончания вклада
        deposit_end_date := CURRENT_TIMESTAMP + INTERVAL '1 month' * p_duration_months;

        -- Вставить новый депозит
        INSERT INTO deposits (
            client_id,
            amount,
            interest_percentage,
            interest_type,
            early_availability,
            end_date,
            currency_id,
            comments
        )
        VALUES (
                   p_client_id,
                   p_amount,
                   p_interest_percentage,
                   p_interest_type,
                   p_early_availability,
                   deposit_end_date,
                   p_currency_id,
                   p_comments
               );

        -- Завершение транзакции
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            -- Откат транзакции в случае ошибки
            ROLLBACK;
            RAISE;
    END;
END;
$$;


-- Хранимая процедура для одобрения займа
CREATE OR REPLACE PROCEDURE approve_loan(
    p_loan_id integer
)
    LANGUAGE plpgsql
AS $$
DECLARE
    collateral_exists boolean;
BEGIN
    -- Проверить наличие залога
    SELECT EXISTS (
        SELECT 1 FROM loans WHERE id = p_loan_id AND collateral_id IS NOT NULL
    ) INTO collateral_exists;

    IF NOT collateral_exists THEN
        RAISE EXCEPTION 'Займ (ID: %) не имеет залога и не может быть одобрен.', p_loan_id;
    END IF;

    -- Обновить статус займа на "Одобрен"
    UPDATE loans
    SET comments = 'Одобрен'
    WHERE id = p_loan_id;

    -- Завершение процедуры
    COMMIT;
END;
$$;


-- Хранимая процедура для получения финансового отчета клиента
CREATE OR REPLACE PROCEDURE get_client_financial_report(
    p_client_id integer,
    OUT total_balance numeric,
    OUT total_deposits numeric,
    OUT total_loans numeric
)
    LANGUAGE plpgsql
AS $$
BEGIN
    -- Получить общий баланс по счетам
    SELECT SUM(balance) INTO total_balance
    FROM accounts
    WHERE client_id = p_client_id;

    -- Получить общую сумму депозитов
    SELECT SUM(amount) INTO total_deposits
    FROM deposits
    WHERE client_id = p_client_id;

    -- Получить общую сумму займов
    SELECT SUM(amount) INTO total_loans
    FROM loans
    WHERE client_id = p_client_id;

    -- Завершение процедуры
END;
$$;


-- Хранимая процедура для получения активных клиентов
CREATE OR REPLACE PROCEDURE get_active_clients()
    LANGUAGE plpgsql
AS $$
BEGIN
    SELECT *
    FROM clients
    WHERE deleted_at IS NULL;
END;
$$;

CREATE OR REPLACE FUNCTION view_account_balance(p_client_id integer)
    RETURNS TABLE(
                     balance numeric,
                     currency char(3),
                     comments text
                 ) AS $$
BEGIN
    RETURN QUERY
        SELECT
            COALESCE(a.balance, 0.00) AS balance,
            c.abbreviation AS currency,
            a.comments
        FROM
            accounts a
                JOIN
            currencies c ON a.currency_id = c.id
        WHERE
            a.client_id = p_client_id
          AND a.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE create_transaction(
    p_sender_account_id integer,
    p_recipient_account_id integer,
    p_amount numeric,
    p_message char(300)
)
    LANGUAGE plpgsql
AS $$
BEGIN
    CALL transfer_funds(p_sender_account_id, p_recipient_account_id, p_amount, p_message);
END;
$$;

CREATE OR REPLACE FUNCTION get_statistics()
    RETURNS TABLE(
                     total_clients integer,
                     total_accounts integer,
                     total_transactions numeric,
                     total_deposits numeric,
                     total_loans numeric
                 ) AS $$
BEGIN
    RETURN QUERY
        SELECT
            (SELECT COUNT(*) FROM clients WHERE deleted_at IS NULL),
            (SELECT COUNT(*) FROM accounts WHERE deleted_at IS NULL),
            (SELECT COALESCE(SUM(amount), 0) FROM transactions),
            (SELECT COALESCE(SUM(amount), 0) FROM deposits WHERE closed_at IS NULL),
            (SELECT COALESCE(SUM(amount), 0) FROM loans WHERE comments != 'Выплачен');
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE take_loan(
    p_client_id integer,
    p_amount numeric,
    p_interest_percentage real,
    p_collateral_id integer, -- Предполагается, что залог хранится в отдельной таблице
    p_comments text
)
    LANGUAGE plpgsql
AS $$
BEGIN
    -- Вставить новый займ
    INSERT INTO loans (
        client_id,
        amount,
        interest_percentage,
        created_at,
        collateral_id,
        comments
    )
    VALUES (
               p_client_id,
               p_amount,
               p_interest_percentage,
               'В процессе',
               CURRENT_TIMESTAMP,
               p_collateral_id,
               p_comments
           );

    COMMIT;
END;
$$;


CREATE OR REPLACE PROCEDURE open_deposit(
    p_client_id integer,
    p_amount numeric,
    p_interest_percentage real,
    p_interest_type integer, -- Предполагается, что типы процентов определены в отдельной таблице
    p_early_availability boolean,
    p_currency_id integer,
    p_duration_months integer, -- Длительность вклада в месяцах
    p_comments text
)
    LANGUAGE plpgsql
AS $$
DECLARE
    deposit_end_date timestamp;
BEGIN
    -- Вычислить дату окончания депозита
    deposit_end_date := CURRENT_TIMESTAMP + INTERVAL '1 month' * p_duration_months;

    -- Вставить новый депозит
    INSERT INTO deposits (
        client_id,
        amount,
        interest_percentage,
        interest_type,
        early_availability,
        end_date,
        currency_id,
        created_at,
        comments
    )
    VALUES (
               p_client_id,
               p_amount,
               p_interest_percentage,
               p_interest_type,
               p_early_availability,
               deposit_end_date,
               p_currency_id,
               CURRENT_TIMESTAMP,
               p_comments
           );

    COMMIT;
END;
$$;


CREATE OR REPLACE FUNCTION view_account_balance(p_client_id integer)
    RETURNS TABLE(
                     balance numeric,
                     currency char(3),
                     comments text
                 ) AS $$
BEGIN
    RETURN QUERY
        SELECT a.balance, c.abbreviation, a.comments
        FROM accounts a
                 JOIN currencies c ON a.currency_id = c.id
        WHERE a.client_id = p_client_id AND a.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_statistics()
    RETURNS TABLE(
                     total_clients integer,
                     total_accounts integer,
                     total_transactions numeric,
                     total_deposits numeric,
                     total_loans numeric
                 ) AS $$
BEGIN
    RETURN QUERY
        SELECT
            (SELECT COUNT(*) FROM clients WHERE deleted_at IS NULL),
            (SELECT COUNT(*) FROM accounts WHERE deleted_at IS NULL),
            (SELECT COALESCE(SUM(amount), 0) FROM transactions),
            (SELECT COALESCE(SUM(amount), 0) FROM deposits WHERE closed_at IS NULL),
            (SELECT COALESCE(SUM(amount), 0) FROM loans WHERE comments != 'Выплачен');
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION view_deposits(p_client_id integer)
    RETURNS TABLE(
                     amount numeric,
                     interest_percentage real,
                     interest_type integer,
                     early_availability boolean,
                     end_date timestamp,
                     currency_id integer,
                     created_at timestamp,
                     comments text
                 ) AS $$
BEGIN
    RETURN QUERY
        SELECT
            d.amount,
            d.interest_percentage,
            d.interest_type,
            d.early_availability,
            d.end_date,
            d.currency_id,
            d.created_at,
            d.comments
        FROM
            deposits d
        WHERE
            d.client_id = p_client_id
          AND d.closed_at IS NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_loans(p_client_id integer)
    RETURNS TABLE(
                     amount numeric,
                     interest_percentage real,
                     status varchar(20),
                     created_at timestamp,
                     closed_at timestamp,
                     comments text
                 ) AS $$
BEGIN
    RETURN QUERY
        SELECT
            l.amount,
            l.interest_percentage,
            'abobus',
            l.created_at,
            l.end_date,
            l.comments
        FROM
            loans l
        WHERE
            l.client_id = p_client_id
          AND l.comments != 'Выплачен';
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION view_cards(p_client_id integer)
    RETURNS TABLE(
                     card_type varchar(50),
                     vendor_name varchar(100),
                     balance numeric,
                     created_at timestamp,
                     lasts_until timestamp
                 ) AS $$
BEGIN
    RETURN QUERY
        SELECT
            ct.type AS card_type,
            v.name AS vendor_name,
            a.balance,
            c.created_at,
            c.lasts_until
        FROM
            cards c
                JOIN
            card_types ct ON c.type = ct.id
                JOIN
            vendors v ON c.vendor_id = v.id
                JOIN
            accounts a ON c.account_id = a.id
        WHERE
            a.client_id = p_client_id
          AND a.deleted_at IS NULL
          AND c.lasts_until > CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION create_transaction(
    p_sender_account_id integer,
    p_recipient_account_id integer,
    p_amount numeric,
    p_message text
)
    RETURNS void AS $$
BEGIN
    -- Проверка достаточности средств на счёте отправителя
    IF (SELECT balance FROM accounts WHERE id = p_sender_account_id) < p_amount THEN
        RAISE EXCEPTION 'Недостаточно средств на счёте отправителя.';
    END IF;

    -- Дебетирование счета отправителя
    UPDATE accounts
    SET balance = balance - p_amount
    WHERE id = p_sender_account_id;

    -- Кредитирование счета получателя
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE id = p_recipient_account_id;

    -- Вставка записи о транзакции
    INSERT INTO transactions (sender_account_id, recipient_account_id, amount, message, created_at)
    VALUES (p_sender_account_id, p_recipient_account_id, p_amount, p_message, CURRENT_TIMESTAMP);
END;
$$ LANGUAGE plpgsql;

-- Обновлённая функция open_deposit без p_duration_months
CREATE OR REPLACE FUNCTION open_deposit(
    p_client_id integer,
    p_amount numeric,
    p_interest_percentage numeric,
    p_interest_type integer,
    p_early_availability boolean,
    p_currency_id integer,
    p_comments text
)
    RETURNS void AS $$
BEGIN
    -- Вставка нового депозита без duration_months
    INSERT INTO deposits (
        client_id,
        amount,
        interest_percentage,
        interest_type,
        early_availability,
        currency_id,
        comments,
        created_at,
        closed_at,
                          end_date
    ) VALUES (
                 p_client_id,
                 p_amount,
                 p_interest_percentage,
                 p_interest_type,
                 p_early_availability,
                 p_currency_id,
                 p_comments,
                 CURRENT_TIMESTAMP,
                 CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
             );

    -- Дополнительные действия при необходимости
    -- Например, логирование, уведомления и т.д.
END;
$$ LANGUAGE plpgsql;

