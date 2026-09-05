-- LPHU Level 2 database. All entries are fictional CTF data.
DROP TABLE IF EXISTS audit_credentials;
DROP TABLE IF EXISTS internal_records;
DROP TABLE IF EXISTS incident_tickets;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS courses;

CREATE TABLE students (id SERIAL PRIMARY KEY, name TEXT NOT NULL, department TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'Active', enrolled_year INT);
CREATE TABLE staff (id SERIAL PRIMARY KEY, name TEXT NOT NULL, department TEXT NOT NULL, role TEXT NOT NULL);
CREATE TABLE courses (id SERIAL PRIMARY KEY, code TEXT NOT NULL, title TEXT NOT NULL, department TEXT NOT NULL, credits INT);
CREATE TABLE incident_tickets (id SERIAL PRIMARY KEY, ticket_ref TEXT NOT NULL, summary TEXT NOT NULL, state TEXT NOT NULL, analyst_note TEXT NOT NULL);
CREATE TABLE internal_records (id SERIAL PRIMARY KEY, type TEXT NOT NULL, classification TEXT NOT NULL, content TEXT NOT NULL);
CREATE TABLE audit_credentials (id SERIAL PRIMARY KEY, account_hint TEXT NOT NULL, credential_blob TEXT NOT NULL, note TEXT NOT NULL);

-- Deliberately broad read access for the CTF SQLi path. The role has no write,
-- ownership, superuser, database-creation, or OS-level privileges.
DROP ROLE IF EXISTS lphu_webapp;
CREATE ROLE lphu_webapp WITH LOGIN PASSWORD 'W3bApp_R34d0nly_2026' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;
GRANT CONNECT ON DATABASE lphu_records TO lphu_webapp;
GRANT USAGE ON SCHEMA public TO lphu_webapp;
GRANT SELECT ON students, staff, courses, incident_tickets, internal_records, audit_credentials TO lphu_webapp;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO lphu_webapp;
