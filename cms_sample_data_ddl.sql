INSERT INTO Users (username, email, password_hash, first_name, last_name, role, department, is_active) VALUES
('admin', 'admin@company.com', SHA2('admin123', 256), 'John', 'Admin', 'Admin', 'IT', TRUE),
('alice.creator', 'alice@company.com', SHA2('alice123', 256), 'Alice', 'Johnson', 'Creator', 'Legal', TRUE),
('bob.approver', 'bob@company.com', SHA2('bob123', 256), 'Bob', 'Smith', 'Approver', 'Legal', TRUE),
('carol.creator', 'carol@company.com', SHA2('carol123', 256), 'Carol', 'Williams', 'Creator', 'Procurement', TRUE),
('david.approver', 'david@company.com', SHA2('david123', 256), 'David', 'Brown', 'Approver', 'Procurement', TRUE);