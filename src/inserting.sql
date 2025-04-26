INSERT INTO currencies (abbreviation, full_name) VALUES
    ('USD', 'US Dollar'),
    ('EUR', 'Euro'),
    ('GBP', 'British Pound'),
    ('CHF', 'Swiss Frank'),
    ('BYN', 'Belarusian ruble'),
    ('JPY', 'Japanese Yen');


INSERT INTO citizenships (name) VALUES
    ('Russia'),
    ('Belarus'),
    ('Germany'),
    ('USA'),
    ('UK'),
    ('France'),
    ('Poland');


INSERT INTO vendors (name) VALUES
    ('Visa'),
    ('MasterCard'),
    ('MIR'),
    ('Discover');


INSERT INTO employee_roles (name) VALUES
    ('Manager'),
    ('Analyst'),
    ('Software engineer'),
    ('QA');


INSERT INTO interest_types (type) VALUES
    ('Simple'),
    ('Compound');


INSERT INTO card_types (type) VALUES
    ('Debit'),
    ('Credit');


INSERT INTO departments (name, description) VALUES
    ('Sales', 'Client facing operations'),
    ('IT', 'Development of software'),
    ('HR', 'Personnel management'),
    ('Security', 'Security overseeing');


INSERT INTO clients (name, surname, middle_name, email, phone_number, address, citizenship_id, birthday, comments) VALUES
    ('Franklin', 'Roosevelt', 'Delano', 'fdr@example.com', '+7-912-345-67-89', 'something something', 4, '1890-05-20', 'great policies'),
    ('Maria', 'Cаrey', NULL, 'maria@example.com', '+7-913-456-78-90', 'пр. Мира, д. 10', 4, '1980-08-15', NULL),
    ('Friedrich', 'Nietzsche', NULL, 'nihilism@example.com', '+ 1 123 123 1231', 'strasse', 3, '1980-08-15', NULL),
    ('Alexander', 'Fleming', 'Sir', 'penecilin@example.com', '+ 40 123 123 123', 'londen', 5, '1881-09-06', NULL),
    ('Francisak', 'Bahusevic', NULL, 'matsei@example.com', '+ 375 25 72 52 386', 'Minsk', 2, '1840-03-28', NULL),
    ('John', 'Doe', NULL, 'johndoe@example.com', '+1-202-555-0173', '123 Elm Street, NY', 4, '1975-12-30', 'International client');


INSERT INTO accounts (client_id, balance, currency_id, comments) VALUES
    (1, 1000.00, 1, 'Main cc'),
    (2, 50000.00, 1, NULL),
    (3, 10.00, 2, 'Main cc'),
    (4, 7000.00, 3, NULL),
    (5, 1.00, 5, 'Main cc'),
    (6, 1000.00, 1, 'Main cc');


INSERT INTO transactions (sender_account_id, recipient_account_id, amount, message) VALUES
    (1, 2, 1500.00, 'For new generations'),
    (6, 3, 2000.00, '<3'),
    (4, 5, 500.00, 'great poetry my friend');


INSERT INTO deposits (client_id, amount, interest_amount, interest_percentage, interest_type, early_availability, end_date, currency_id, comments) VALUES
    (1, 5000.00, 250.00, 3.0, 2, TRUE, '2025-05-20', 1, NULL),
    (2, 3000.00, 150.00, 7.0, 2, FALSE, '2024-08-15', 2, NULL);


INSERT INTO properties (owner_id, type, currency_id, estimated_worth, comments) VALUES
    (1, 'Apartment', 1, 1000000, 'Apartment in the city centre'),
    (3, 'Car', 1, 30000, 'Tesla Model 3');


INSERT INTO loans (amount, client_id, interest_percentage, interest_type, amount_paid, currency_id, collateral_id, end_date, comments) VALUES
    (20000.00, 5, 7.5, 1, 5000.00, 1, 1, '2026-05-20', NULL),
    (15000.00, 6, 25.0, 1, 3000.00, 5, 2, '2025-12-30', NULL);


INSERT INTO employees (department_id, name, surname, middle_name, email, phone_number, address, citizenship_id, birthday, role_id, salary, rating, joined_at, comments) VALUES
    (1, 'Michael', 'Freedman', NULL, 'mishka@example.com', '+7-914-567-89-01', 'ул. Пушкина, д. 5', 1, '1951-04-21', 2, 60000, 5, '2020-01-15', NULL),
    (2, 'Olivia', 'Brown', NULL, 'olivia.brown@example.com', '+1-303-555-0147', '456 Oak Avenue, CA', 4, '1992-07-22', 3, 80000, 4, '2021-06-01', 'Remote employee'),
    (3, 'Sean', 'Diddler', 'John', 'party@example.com', '+7-915-678-90-12', '456 Oak Avenue, CA', 4, '1969-11-04', 1, 55000, 0, '2019-09-30', '-_-');


INSERT INTO cards (vendor_id, type, account_id, lasts_until) VALUES
    (1, 1, 1, '2026-12-31'),
    (2, 2, 2, '2025-06-30'),
    (3, 1, 3, '2027-03-31');