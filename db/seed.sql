-- Fictional data for BUGATHON 2026 Level 2.
INSERT INTO students (name, department, status, enrolled_year) VALUES
('Jesse P.', 'Chemistry', 'Active', 2023), ('Walter W.', 'Chemistry', 'Active', 2022),
('Skyler W.', 'Business', 'Active', 2023), ('Badger M.', 'Computer Science', 'Suspended', 2021),
('Combo R.', 'Computer Science', 'Active', 2024), ('Jane M.', 'Fine Arts', 'Graduated', 2020),
('Todd A.', 'Chemistry', 'Active', 2024), ('Andrea C.', 'Education', 'Active', 2023),
('Huell B.', 'Physical Education', 'Active', 2022), ('Skinny P.', 'Business', 'Active', 2024);
INSERT INTO students (id, name, department, status, enrolled_year) VALUES
(1023, 'Marion Q.', 'Computer Science', 'Active', 2023);

INSERT INTO staff (name, department, role) VALUES
('Gustavo F.', 'Administration', 'Chancellor'), ('Mike E.', 'Campus Security', 'Director'),
('Saul G.', 'Legal Affairs', 'Counsel'), ('Lydia R.', 'Logistics', 'Operations Lead');
INSERT INTO courses (code, title, department, credits) VALUES
('CHM501', 'Organic Chemical Synthesis', 'Chemistry', 4), ('CSE503', 'Secure Enterprise Architecture', 'Computer Science', 4),
('LOG401', 'Supply Chain & Distribution Logistics', 'Management', 3), ('CYB509', 'Industrial Cyber Threat Analysis', 'Computer Science', 3);

-- This is not available through normal portal functionality. UNION access proves
-- control of the query and yields checkpoint four.
INSERT INTO incident_tickets (ticket_ref, summary, state, analyst_note) VALUES
('ITOPS-4488', 'Registrar lookup parameterization review', 'Deferred', 'Developer review checkpoint: FLAG2_04{qu3ry_c0ntr0l_9a71ce}');

INSERT INTO internal_records (type, classification, content) VALUES
('Maintenance', 'Internal', 'HVAC inspection scheduled for Building C, Q3 2026.'),
('Policy', 'Internal', 'Updated parking permit rates effective Fall semester.'),
('Meeting Notes', 'Internal', 'Faculty senate budget review pending.');
INSERT INTO internal_records (id, type, classification, content) VALUES
(501, 'Investigation', 'Internal', 'RE: Unaccounted lab reagent shipments — Superlab, Lot #74-B. Registrar review checkpoint: FLAG2_06{r3c0rd_501_2f8cad}. Auditor access is temporarily provisioned at /audit/ pending review sign-off.');

-- Base64 is intentionally an interpretation step. Decoding produces the audit
-- credential and checkpoint eight; spaces in the token are not significant.
INSERT INTO audit_credentials (account_hint, credential_blob, note) VALUES
('temporary Superlab reviewer', 'YXVkaXRvcjpBdWQxdF9SM3YxM3dfMjAyNiF8RkxBRzJfMDh7ZDNjMGQzZF80Y2Mz c3NfMTVlZjkyfQ==', 'Stored as a transport-safe review token; whitespace is not significant.');

COMMENT ON TABLE audit_credentials IS 'Schema enumeration checkpoint: FLAG2_05{sch3m4_tr4c3_6b4e18}';
SELECT setval('students_id_seq', (SELECT MAX(id) FROM students));
SELECT setval('internal_records_id_seq', (SELECT MAX(id) FROM internal_records));
