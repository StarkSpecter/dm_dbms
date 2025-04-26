CREATE TABLE "currencies" (
    "id" serial PRIMARY KEY,
    "abbreviation" char(3) NOT NULL,
    "full_name" bpchar NOT NULL
);


CREATE TABLE "citizenships" (
    "id" serial PRIMARY KEY,
    "name" char(50)
);


CREATE TABLE "vendors" (
    "id" serial PRIMARY KEY,
    "name" char(50)
);


CREATE TABLE "employee_roles" (
    "id" serial PRIMARY KEY,
    "name" char(50)
);


CREATE TABLE "interest_types" (
    "id" serial PRIMARY KEY,
    "type" char(50)
);


CREATE TABLE "card_types" (
    "id" serial PRIMARY KEY,
    "type" char(30)
);


CREATE TABLE "clients" (
  "id" serial PRIMARY KEY,
  "name" char(50) NOT NULL,
  "surname" char(50) NOT NULL,
  "middle_name" bpchar,
  "email" char(50),
  "phone_number" char(50) NOT NULL,
  "address" bpchar NOT NULL,
  "citizenship_id" integer REFERENCES "citizenships",
  "birthday" timestamp NOT NULL CHECK ( birthday < CURRENT_TIMESTAMP ),
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" timestamp,
  "comments" text
);


CREATE TABLE "accounts" (
  "id" serial PRIMARY KEY,
  "client_id" integer NOT NULL REFERENCES "clients",
  "balance" numeric(1000,970) NOT NULL DEFAULT 0 CHECK (balance > 0),
  "currency_id" integer NOT NULL REFERENCES "currencies",
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" timestamp,
  "comments" text
);


CREATE TABLE "transactions" (
  "id" serial PRIMARY KEY,
  "sender_account_id" integer NOT NULL REFERENCES "accounts",
  "recipient_account_id" integer NOT NULL REFERENCES "accounts",
  "amount" numeric(1000,970) NOT NULL CHECK ( amount > 0 ),
  "message" char(300),
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE "deposits" (
  "id" serial PRIMARY KEY,
  "client_id" integer NOT NULL REFERENCES "clients",
  "amount" numeric(1000,970) NOT NULL DEFAULT 0 CHECK ( amount > 0 ),
  "interest_amount" numeric(1000,970) NOT NULL DEFAULT 0 CHECK ( interest_amount > 0 ),
  "interest_percentage" real NOT NULL CHECK ( interest_percentage > 0 ),
  "interest_type" integer NOT NULL REFERENCES "interest_types",
  "early_availability" boolean NOT NULL,
  "end_date" timestamp NOT NULL,
  "currency_id" integer NOT NULL REFERENCES "currencies",
  "created_at" timestamp NOT NULL default CURRENT_TIMESTAMP,
  "closed_at" timestamp,
  "comments" text
);


CREATE TABLE "properties" (
  "id" serial PRIMARY KEY,
  "owner_id" integer NOT NULL references "clients",
  "type" bpchar NOT NULL,
  "currency_id" integer NOT NULL references "currencies",
  "estimated_worth" integer,
  "comments" text
);


CREATE TABLE "loans" (
  "id" serial PRIMARY KEY,
  "amount" numeric(1000,970) NOT NULL DEFAULT 0 CHECK ( amount > 0 ),
  "client_id" integer NOT NULL REFERENCES "clients",
  "interest_percentage" real NOT NULL check ( interest_percentage > 0 ),
  "interest_type" integer NOT NULL REFERENCES "interest_types",
  "amount_paid" numeric(1000,970) NOT NULL DEFAULT 0,
  "currency_id" integer NOT NULL REFERENCES "currencies",
  "collateral_id" integer REFERENCES "properties",
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "end_date" timestamp NOT NULL,
  "comments" text
);


CREATE TABLE "departments" (
  "id" serial PRIMARY KEY,
  "name" bpchar NOT NULL,
  "description" text
);


CREATE TABLE "employees" (
  "id" serial PRIMARY KEY,
  "department_id" integer REFERENCES "departments",
  "name" char(50) NOT NULL,
  "surname" char(50) NOT NULL,
  "middle_name" char(50),
  "email" char(50),
  "phone_number" char(50) NOT NULL,
  "address" bpchar NOT NULL,
  "citizenship_id" integer NOT NULL REFERENCES "citizenships",
  "birthday" timestamp NOT NULL,
  "role_id" integer NOT NULL REFERENCES "employee_roles",
  "salary" integer NOT NULL CHECK ( salary > 0 ),
  "rating" integer,
  "joined_at" timestamp NOT NULL default CURRENT_TIMESTAMP,
  "left_at" timestamp,
  "comments" text
);


CREATE TABLE "cards" (
  "id" serial PRIMARY KEY,
  "vendor_id" integer NOT NULL REFERENCES "vendors",
  "type" integer NOT NULL references "card_types",
  "account_id" integer NOT NULL REFERENCES "accounts",
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "lasts_until" timestamp NOT NULL
);


SELECT constraint_name, table_name, column_name, ordinal_position FROM information_schema.key_column_usage WHERE table_name = 'clients';


SELECT conname, contype
FROM pg_catalog.pg_constraint
         JOIN pg_class t ON t.oid = conrelid
WHERE t.relname ='clients';

ALTER TABLE "clients" ALTER COLUMN "citizenship_id" DROP NOT NULL;

-- ALTER TABLE "accounts" ADD FOREIGN KEY ("client_id") REFERENCES "clients" ("id");

-- ALTER TABLE "transactions" ADD FOREIGN KEY ("sender_account_id") REFERENCES "accounts" ("id");

-- ALTER TABLE "transactions" ADD FOREIGN KEY ("recepient_account_id") REFERENCES "accounts" ("id");

-- ALTER TABLE "deposits" ADD FOREIGN KEY ("client_id") REFERENCES "clients" ("id");

-- ALTER TABLE "loans" ADD FOREIGN KEY ("id") REFERENCES "clients" ("id");

-- ALTER TABLE "departments" ADD FOREIGN KEY ("head_id") REFERENCES "employees" ("id");

-- ALTER TABLE "cards" ADD FOREIGN KEY ("account_id") REFERENCES "accounts" ("id");

-- ALTER TABLE "loans" ADD FOREIGN KEY ("collateral_id") REFERENCES "properties" ("loan_assigned_at");

-- ALTER TABLE "properties" ADD FOREIGN KEY ("owner_id") REFERENCES "clients" ("id");

-- ALTER TABLE "deposits" ADD FOREIGN KEY ("currency_id") REFERENCES "currencies" ("id");

-- ALTER TABLE "loans" ADD FOREIGN KEY ("currency_id") REFERENCES "currencies" ("id");

-- ALTER TABLE "properties" ADD FOREIGN KEY ("currency_id") REFERENCES "currencies" ("id");

-- ALTER TABLE "accounts" ADD FOREIGN KEY ("currency_id") REFERENCES "currencies" ("id");

-- ALTER TABLE "employees" ADD FOREIGN KEY ("citizenship_id") REFERENCES "citizenships" ("id");

-- ALTER TABLE "clients" ADD FOREIGN KEY ("citizenship_id") REFERENCES "citizenships" ("id");

-- ALTER TABLE "cards" ADD FOREIGN KEY ("vendor_id") REFERENCES "vendors" ("id");

-- ALTER TABLE "employees" ADD FOREIGN KEY ("role_id") REFERENCES "employee_roles" ("id");
