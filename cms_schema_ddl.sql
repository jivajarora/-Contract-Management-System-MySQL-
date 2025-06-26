CREATE DATABASE IF NOT EXISTS contract_management_system;
USE contract_management_system;

DROP TABLE IF EXISTS Notifications;
DROP TABLE IF EXISTS ContractAmendments;
DROP TABLE IF EXISTS Documents;
DROP TABLE IF EXISTS AuditTrail;
DROP TABLE IF EXISTS ContractRenewals;
DROP TABLE IF EXISTS Contracts;
DROP TABLE IF EXISTS Users;

CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role ENUM('Admin', 'Creator', 'Approver', 'Viewer') NOT NULL DEFAULT 'Viewer',
    department VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_active (is_active)
) ENGINE=InnoDB;

CREATE TABLE Contracts (
    contract_id INT AUTO_INCREMENT PRIMARY KEY,
    contract_number VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    contract_type ENUM('Service', 'Purchase', 'Employment', 'Lease', 'NDA', 'Other') NOT NULL,
    party_a VARCHAR(200) NOT NULL,
    party_b VARCHAR(200) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    contract_value DECIMAL(15,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    status ENUM('Draft', 'Pending_Approval', 'Approved', 'Rejected', 'Active', 'Expired', 'Terminated') NOT NULL DEFAULT 'Draft',
    created_by INT NOT NULL,
    approved_by INT NULL,
    approved_at TIMESTAMP NULL,
    is_renewable BOOLEAN DEFAULT FALSE,
    auto_renew BOOLEAN DEFAULT FALSE,
    renewal_notice_days INT DEFAULT 30,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES Users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES Users(user_id) ON DELETE SET NULL,
    
    CONSTRAINT chk_dates CHECK (end_date > start_date),
    CONSTRAINT chk_contract_value CHECK (contract_value >= 0),
    CONSTRAINT chk_renewal_notice CHECK (renewal_notice_days >= 0),
    
    INDEX idx_contract_number (contract_number),
    INDEX idx_status (status),
    INDEX idx_dates (start_date, end_date),
    INDEX idx_created_by (created_by),
    INDEX idx_approved_by (approved_by),
    INDEX idx_contract_type (contract_type),
    INDEX idx_is_deleted (is_deleted),
    INDEX idx_end_date_status (end_date, status)
) ENGINE=InnoDB;

CREATE TABLE ContractRenewals (
    renewal_id INT AUTO_INCREMENT PRIMARY KEY,
    contract_id INT NOT NULL,
    renewal_number INT NOT NULL,
    previous_end_date DATE NOT NULL,
    new_end_date DATE NOT NULL,
    renewal_terms TEXT,
    new_contract_value DECIMAL(15,2),
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    requested_by INT NOT NULL,
    approved_by INT NULL,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP NULL,
    notes TEXT,
    
    FOREIGN KEY (contract_id) REFERENCES Contracts(contract_id) ON DELETE CASCADE,
    FOREIGN KEY (requested_by) REFERENCES Users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES Users(user_id) ON DELETE SET NULL,
    
    UNIQUE KEY uk_contract_renewal (contract_id, renewal_number),
    
    CONSTRAINT chk_renewal_dates CHECK (new_end_date > previous_end_date),
    CONSTRAINT chk_renewal_value CHECK (new_contract_value IS NULL OR new_contract_value >= 0),
    
    INDEX idx_contract_id (contract_id),
    INDEX idx_status_renewal (status),
    INDEX idx_requested_by (requested_by),
    INDEX idx_approved_by (approved_by)
) ENGINE=InnoDB;

CREATE TABLE AuditTrail (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    contract_id INT NOT NULL,
    action_type ENUM('Created', 'Updated', 'Approved', 'Rejected', 'Renewed', 'Terminated', 'Deleted', 'Restored') NOT NULL,
    old_values JSON,
    new_values JSON,
    performed_by INT NOT NULL,
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    notes TEXT,
    
    FOREIGN KEY (contract_id) REFERENCES Contracts(contract_id) ON DELETE CASCADE,
    FOREIGN KEY (performed_by) REFERENCES Users(user_id) ON DELETE RESTRICT,
    
    INDEX idx_contract_id_audit (contract_id),
    INDEX idx_action_type (action_type),
    INDEX idx_performed_by (performed_by),
    INDEX idx_performed_at (performed_at)
) ENGINE=InnoDB;

CREATE TABLE Documents (
    document_id INT AUTO_INCREMENT PRIMARY KEY,
    contract_id INT NOT NULL,
    document_name VARCHAR(255) NOT NULL,
    document_type ENUM('Contract', 'Amendment', 'Addendum', 'Certificate', 'Other') NOT NULL,
    file_path VARCHAR(500),
    file_url VARCHAR(500),
    file_size INT,
    mime_type VARCHAR(100),
    version_number INT DEFAULT 1,
    is_current_version BOOLEAN DEFAULT TRUE,
    uploaded_by INT NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    
    FOREIGN KEY (contract_id) REFERENCES Contracts(contract_id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES Users(user_id) ON DELETE RESTRICT,
    
    CONSTRAINT chk_file_location CHECK (file_path IS NOT NULL OR file_url IS NOT NULL),
    CONSTRAINT chk_file_size CHECK (file_size IS NULL OR file_size > 0),
    CONSTRAINT chk_version_number CHECK (version_number > 0),
    
    INDEX idx_contract_id_docs (contract_id),
    INDEX idx_document_type (document_type),
    INDEX idx_uploaded_by (uploaded_by),
    INDEX idx_current_version (is_current_version)
) ENGINE=InnoDB;

CREATE TABLE Notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    contract_id INT NOT NULL,
    user_id INT NOT NULL,
    notification_type ENUM('Expiry_Warning', 'Renewal_Due', 'Approval_Required', 'Status_Change', 'Document_Upload') NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    priority ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    is_read BOOLEAN DEFAULT FALSE,
    scheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (contract_id) REFERENCES Contracts(contract_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    
    INDEX idx_contract_id_notif (contract_id),
    INDEX idx_user_id_notif (user_id),
    INDEX idx_notification_type (notification_type),
    INDEX idx_is_read (is_read),
    INDEX idx_priority (priority),
    INDEX idx_scheduled_at (scheduled_at)
) ENGINE=InnoDB;

CREATE TABLE ContractAmendments (
    amendment_id INT AUTO_INCREMENT PRIMARY KEY,
    contract_id INT NOT NULL,
    amendment_number INT NOT NULL,
    amendment_title VARCHAR(200) NOT NULL,
    amendment_description TEXT NOT NULL,
    amendment_type ENUM('Value_Change', 'Date_Extension', 'Scope_Change', 'Terms_Change', 'Other') NOT NULL,
    original_value JSON,
    amended_value JSON,
    effective_date DATE NOT NULL,
    created_by INT NOT NULL,
    approved_by INT NULL,
    status ENUM('Draft', 'Pending_Approval', 'Approved', 'Rejected') DEFAULT 'Draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP NULL,
    notes TEXT,
    
    FOREIGN KEY (contract_id) REFERENCES Contracts(contract_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES Users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES Users(user_id) ON DELETE SET NULL,
    
    UNIQUE KEY uk_contract_amendment (contract_id, amendment_number),
    
    INDEX idx_contract_id_amend (contract_id),
    INDEX idx_amendment_type (amendment_type),
    INDEX idx_status_amend (status),
    INDEX idx_created_by_amend (created_by),
    INDEX idx_effective_date (effective_date)
) ENGINE=InnoDB;

-- Views
CREATE VIEW ActiveContracts AS
SELECT 
    c.contract_id, c.contract_number, c.title, c.contract_type,
    c.party_a, c.party_b, c.start_date, c.end_date,
    c.contract_value, c.currency, c.status,
    u.first_name AS created_by_name, u.last_name AS created_by_lastname,
    a.first_name AS approved_by_name, a.last_name AS approved_by_lastname,
    c.created_at, c.approved_at
FROM Contracts c
LEFT JOIN Users u ON c.created_by = u.user_id
LEFT JOIN Users a ON c.approved_by = a.user_id
WHERE c.is_deleted = FALSE AND c.status IN ('Active', 'Approved');

CREATE VIEW ContractsExpiringSoon AS
SELECT 
    c.contract_id, c.contract_number, c.title,
    c.party_a, c.party_b, c.end_date,
    DATEDIFF(c.end_date, CURDATE()) AS days_until_expiry,
    c.is_renewable, c.auto_renew, u.email AS created_by_email
FROM Contracts c
JOIN Users u ON c.created_by = u.user_id
WHERE c.is_deleted = FALSE AND c.status = 'Active'
AND c.end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY);

-- Triggers
DELIMITER //
CREATE TRIGGER prevent_contract_hard_delete
    BEFORE DELETE ON Contracts
    FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Hard delete not allowed. Use soft delete by setting is_deleted = TRUE';
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER contract_audit_trigger
    AFTER UPDATE ON Contracts
    FOR EACH ROW
BEGIN
    INSERT INTO AuditTrail (
        contract_id, action_type, old_values, new_values, 
        performed_by, notes
    ) VALUES (
        NEW.contract_id, 'Updated',
        JSON_OBJECT(
            'status', OLD.status,
            'contract_value', OLD.contract_value,
            'end_date', OLD.end_date,
            'is_deleted', OLD.is_deleted
        ),
        JSON_OBJECT(
            'status', NEW.status,
            'contract_value', NEW.contract_value,
            'end_date', NEW.end_date,
            'is_deleted', NEW.is_deleted
        ),
        NEW.created_by,
        CASE 
            WHEN OLD.is_deleted = FALSE AND NEW.is_deleted = TRUE THEN 'Contract soft deleted'
            WHEN OLD.is_deleted = TRUE AND NEW.is_deleted = FALSE THEN 'Contract restored'
            WHEN OLD.status != NEW.status THEN CONCAT('Status changed from ', OLD.status, ' to ', NEW.status)
            ELSE 'Contract updated'
        END
    );
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER contract_creation_audit
    AFTER INSERT ON Contracts
    FOR EACH ROW
BEGIN
    INSERT INTO AuditTrail (
        contract_id, action_type, new_values, performed_by, notes
    ) VALUES (
        NEW.contract_id, 'Created',
        JSON_OBJECT(
            'contract_number', NEW.contract_number,
            'title', NEW.title,
            'status', NEW.status,
            'contract_value', NEW.contract_value
        ),
        NEW.created_by, 'Contract created'
    );
END//
DELIMITER ;

-- Stored Procedures
DELIMITER //
CREATE PROCEDURE ApproveContract(
    IN p_contract_id INT,
    IN p_approver_id INT,
    IN p_action ENUM('APPROVE', 'REJECT'),
    IN p_notes TEXT
)
BEGIN
    DECLARE v_current_status VARCHAR(50);
    DECLARE v_error_message VARCHAR(255);
    
    START TRANSACTION;
    
    SELECT status INTO v_current_status 
    FROM Contracts WHERE contract_id = p_contract_id AND is_deleted = FALSE;
    
    IF v_current_status IS NULL THEN
        SET v_error_message = 'Contract not found or has been deleted';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;
    
    IF v_current_status NOT IN ('Draft', 'Pending_Approval') THEN
        SET v_error_message = CONCAT('Cannot approve/reject contract with status: ', v_current_status);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;
    
    IF p_action = 'APPROVE' THEN
        UPDATE Contracts 
        SET status = 'Approved', approved_by = p_approver_id, approved_at = CURRENT_TIMESTAMP
        WHERE contract_id = p_contract_id;
        
        INSERT INTO AuditTrail (contract_id, action_type, performed_by, notes)
        VALUES (p_contract_id, 'Approved', p_approver_id, COALESCE(p_notes, 'Contract approved'));
        
    ELSEIF p_action = 'REJECT' THEN
        UPDATE Contracts 
        SET status = 'Rejected', approved_by = p_approver_id, approved_at = CURRENT_TIMESTAMP
        WHERE contract_id = p_contract_id;
        
        INSERT INTO AuditTrail (contract_id, action_type, performed_by, notes)
        VALUES (p_contract_id, 'Rejected', p_approver_id, COALESCE(p_notes, 'Contract rejected'));
    END IF;
    
    COMMIT;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE SoftDeleteContract(
    IN p_contract_id INT,
    IN p_user_id INT,
    IN p_reason TEXT
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_exists 
    FROM Contracts WHERE contract_id = p_contract_id AND is_deleted = FALSE;
    
    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract not found or already deleted';
    END IF;
    
    UPDATE Contracts 
    SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP
    WHERE contract_id = p_contract_id;
    
    INSERT INTO AuditTrail (contract_id, action_type, performed_by, notes)
    VALUES (p_contract_id, 'Deleted', p_user_id, COALESCE(p_reason, 'Contract soft deleted'));
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE GenerateExpiryNotifications()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_contract_id INT;
    DECLARE v_created_by INT;
    DECLARE v_contract_number VARCHAR(50);
    DECLARE v_title VARCHAR(200);
    DECLARE v_end_date DATE;
    DECLARE v_days_until_expiry INT;
    
    DECLARE expiry_cursor CURSOR FOR
        SELECT contract_id, created_by, contract_number, title, end_date,
               DATEDIFF(end_date, CURDATE()) as days_until_expiry
        FROM Contracts
        WHERE is_deleted = FALSE AND status = 'Active'
        AND end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY);
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN expiry_cursor;
    
    read_loop: LOOP
        FETCH expiry_cursor INTO v_contract_id, v_created_by, v_contract_number, 
              v_title, v_end_date, v_days_until_expiry;
        
        IF done THEN LEAVE read_loop; END IF;
        
        INSERT IGNORE INTO Notifications (
            contract_id, user_id, notification_type, title, message, priority, scheduled_at
        ) VALUES (
            v_contract_id, v_created_by, 'Expiry_Warning',
            CONCAT('Contract Expiring Soon: ', v_contract_number),
            CONCAT('Contract "', v_title, '" will expire on ', v_end_date, ' (', v_days_until_expiry, ' days remaining)'),
            CASE 
                WHEN v_days_until_expiry <= 7 THEN 'Critical'
                WHEN v_days_until_expiry <= 15 THEN 'High'
                ELSE 'Medium'
            END,
            CURRENT_TIMESTAMP
        );
    END LOOP;
    
    CLOSE expiry_cursor;
END//
DELIMITER ;

DELIMITER ;

-- Additional performance indexes
CREATE INDEX idx_contracts_status_dates ON Contracts(status, end_date, is_deleted);
CREATE INDEX idx_contracts_created_by_status ON Contracts(created_by, status, is_deleted);
CREATE INDEX idx_audit_contract_action_date ON AuditTrail(contract_id, action_type, performed_at);
CREATE INDEX idx_notifications_user_read ON Notifications(user_id, is_read, scheduled_at);

SELECT 'Contract Management System schema created successfully!' AS Status;