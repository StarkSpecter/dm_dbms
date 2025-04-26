# dm_dbms
# Александр Политанский 253505
### Информационная система для банка
***Описание:***
Информационная система для банка - это программное обеспечение, предназначенное для хранения и обработки данных, требующихся для обеспечения работы данных. Оно хранит все воможные данные и обеспечивает к ним доступ для чтения, изменения.

***Цель проекта:***
Получить опыть проектирования БД, написания sql запросов и применения их в прикладном приложении

![DataModels](data_diagram.png)

Table clients {
  id serial [PRIMARY KEY] // или идентификационный номер?
  name char(50) [not null] 
  surname char(50) [not null] 
  middle_name bpchar 
  status bpchar [not null]  // ordinary, premium, vip, employee
  email char(50) [not null] 
  phone_number char(50) [not null] 
  adress bpchar [not null] 
  citizenship char(50) [not null] 
  residency_status char(50) [not null] 
  birthday timestamp [not null] 
  comments text
  created_at timestamp [not null] 
  deleted_at timestamp
}

Table accounts {
  id serial [primary key]
  client_id integer [not null] // foreign key
  balance numeric(5030, 5000) [not null] 
  currency_id integer [not null]  // Foreign key
  type bpchar [not null]
  comments text
  created_at timestamp [not null]
}

Table transactions {
  id serial [primary key]
  sender_account_id integet [not null]  // Foreign key
  recepient_account_id integer [not null]  // Foreign key
  amount numeric(5030, 5000) [not null]
  created_at timestamp [not null]
}

Table deposits {
  id serial [primary key]
  client_id integer [not null]  // Foreign key
  amount numeric(5030, 5000) [not null]
  interest_amount numeric(5030, 5000) [not null] // default 0
  interest_percantage real [not null]
  interest_type enum ('Fixed', 'Varying') [not null]
  interest_stack_type enum('Simple', 'Compound') [not null]
  early_availability boolean [not null]
  end_date timestamp [not null] 
  currency_id integer [not null]  // Foreign key
  comments text
  created_at timestamp [not null]
}

Table loans {
  id serial [primary key]
  amount numeric(5030, 5000) [not null]
  client_id integer [not null]  // Foreign key
  interest_percentage real [not null]
  interest_type enum ('Fixed', 'Varying') [not null]
  amount_paid numeric(5030, 5000) [not null]
  end_date timestamp [not null]
  currency_id integer [not null]  // Foreign key
  collateral_id integer // Foreign key
  comments text
  created_at timestamp [not null]
}

Table departments {
  id serial [primary key]
  name bpchar [not null]
  head_id integer  // Foreign key
  description text 
}

Table employees {
  id serial [primary key]
  department_id integer  // Foreign key
  name char(50) [not null]
  surname char(50) [not null]
  middle_name char(50) 
  email char(50) [not null]
  phone_number char(50) [not null]
  adress bpchar [not null]
  citizenship char(50) [not null]
  residency_status char(50) [not null]
  birthday timestamp [not null]
  role char(50) [not null]
  salary integer [not null]
  rating integer 
  comments text
  joined_at timestamp [not null]
  left_at timestamp
}

Table cards {
  id serial [primary key]
  vendor char(30) [not null]
  status_type char(30) [not null]
  type enum('Credit', 'Debit') [not null]
  account_id integer [not null]  // Foreign key
  created_at timestamp [not null]
  lasts_until timestamp [not null]
}

table properties {
  id serial [primary key]
  owner_id integer [not null] // Foreign key
  type bpchar [not null]
  comments text
  currency_id integer [not null]  // Foreign key
  estimated_worth integer 
  loan_assigned_at integer 
}

Table currencies {
  id serial [primary key]
  abbreviation char(3) [not null]
  full_name bpchar [not null]
  issuer bpchar [not null]
}
