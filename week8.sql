-- hospital_management.sql
-- Hospital Management System schema (MySQL, InnoDB)
-- Drop in reverse dependency order to avoid FK errors
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS invoice_item;
DROP TABLE IF EXISTS invoice;
DROP TABLE IF EXISTS admission;
DROP TABLE IF EXISTS room;
DROP TABLE IF EXISTS prescription_item;
DROP TABLE IF EXISTS prescription;
DROP TABLE IF EXISTS medication;
DROP TABLE IF EXISTS appointment;
DROP TABLE IF EXISTS doctor_specialty;
DROP TABLE IF EXISTS specialty;
DROP TABLE IF EXISTS doctor;
DROP TABLE IF EXISTS nurse;
DROP TABLE IF EXISTS department;
DROP TABLE IF EXISTS medical_record;
DROP TABLE IF EXISTS diagnosis;
DROP TABLE IF EXISTS lab_result;
DROP TABLE IF EXISTS lab_test;
DROP TABLE IF EXISTS allergy;
DROP TABLE IF EXISTS patient_allergy;
DROP TABLE IF EXISTS patient;
DROP TABLE IF EXISTS insurance_policy;
DROP TABLE IF EXISTS insurer;
DROP TABLE IF EXISTS user_role;
DROP TABLE IF EXISTS user_account;
DROP TABLE IF EXISTS role;

SET FOREIGN_KEY_CHECKS = 1;


-- Users & Roles (for system login & audit)
CREATE TABLE role (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE user_account (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  role_id INT NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_role FOREIGN KEY (role_id) REFERENCES role(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE user_role (
  user_id INT NOT NULL,
  role_id INT NOT NULL,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES user_account(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Departments
CREATE TABLE department (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE,
  code VARCHAR(20) NOT NULL UNIQUE,
  location VARCHAR(255),
  phone VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- Doctors, Nurses
CREATE TABLE doctor (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_number VARCHAR(50) NOT NULL UNIQUE,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(50),
  department_id INT,
  hire_date DATE,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_doctor_dept FOREIGN KEY (department_id) REFERENCES department(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE nurse (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_number VARCHAR(50) NOT NULL UNIQUE,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(50),
  department_id INT,
  hire_date DATE,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_nurse_dept FOREIGN KEY (department_id) REFERENCES department(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Doctor specialties (Many-to-Many)
CREATE TABLE specialty (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE,
  description VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE doctor_specialty (
  doctor_id INT NOT NULL,
  specialty_id INT NOT NULL,
  PRIMARY KEY (doctor_id, specialty_id),
  CONSTRAINT fk_ds_doctor FOREIGN KEY (doctor_id) REFERENCES doctor(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ds_specialty FOREIGN KEY (specialty_id) REFERENCES specialty(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Insurer & Policies
CREATE TABLE insurer (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  contact_phone VARCHAR(50),
  contact_email VARCHAR(255),
  address VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE insurance_policy (
  id INT AUTO_INCREMENT PRIMARY KEY,
  insurer_id INT NOT NULL,
  policy_number VARCHAR(100) NOT NULL UNIQUE,
  holder_name VARCHAR(255) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  coverage_details TEXT,
  CONSTRAINT fk_policy_insurer FOREIGN KEY (insurer_id) REFERENCES insurer(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Patients
CREATE TABLE patient (
  id INT AUTO_INCREMENT PRIMARY KEY,
  hospital_number VARCHAR(100) NOT NULL UNIQUE, -- MRN
  first_name VARCHAR(150) NOT NULL,
  last_name VARCHAR(150) NOT NULL,
  gender ENUM('Male','Female','Other') NOT NULL,
  birth_date DATE,
  phone VARCHAR(50),
  email VARCHAR(255),
  address VARCHAR(255),
  emergency_contact_name VARCHAR(255),
  emergency_contact_phone VARCHAR(50),
  insurance_policy_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_patient_insurance FOREIGN KEY (insurance_policy_id) REFERENCES insurance_policy(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Allergies (Many-to-Many: patient_allergy)
CREATE TABLE allergy (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description VARCHAR(255),
  UNIQUE KEY uq_allergy_name (name)
) ENGINE=InnoDB;

CREATE TABLE patient_allergy (
  patient_id INT NOT NULL,
  allergy_id INT NOT NULL,
  reaction VARCHAR(255),
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (patient_id, allergy_id),
  CONSTRAINT fk_pa_patient FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pa_allergy FOREIGN KEY (allergy_id) REFERENCES allergy(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Appointments (1-M: doctor -> appointment, patient -> appointment)
CREATE TABLE appointment (
  id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_ref VARCHAR(100) NOT NULL UNIQUE,
  patient_id INT NOT NULL,
  doctor_id INT,
  scheduled_start DATETIME NOT NULL,
  scheduled_end DATETIME,
  status ENUM('Scheduled','Checked-in','Cancelled','Completed','No-Show') NOT NULL DEFAULT 'Scheduled',
  reason TEXT,
  created_by INT, -- user_account who created
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_appointment_patient FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_appointment_doctor FOREIGN KEY (doctor_id) REFERENCES doctor(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_appointment_creator FOREIGN KEY (created_by) REFERENCES user_account(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Medical Records (1-M: patient -> medical_record)
CREATE TABLE medical_record (
  id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  record_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by INT, -- user id (doctor/nurse)
  notes TEXT,
  vitals JSON, -- optional structured vitals (bp, hr, temp, etc.)
  visibility ENUM('Private','Team','Public') DEFAULT 'Team',
  CONSTRAINT fk_mr_patient FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_mr_creator FOREIGN KEY (created_by) REFERENCES user_account(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Diagnoses (1-M: medical_record -> diagnosis)
CREATE TABLE diagnosis (
  id INT AUTO_INCREMENT PRIMARY KEY,
  medical_record_id INT NOT NULL,
  diagnosis_code VARCHAR(50), -- e.g ICD-10 code
  description VARCHAR(255) NOT NULL,
  diagnosed_by INT,
  diagnosed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_diag_mr FOREIGN KEY (medical_record_id) REFERENCES medical_record(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_diag_by FOREIGN KEY (diagnosed_by) REFERENCES user_account(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Lab tests & results
CREATE TABLE lab_test (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(100) UNIQUE,
  description VARCHAR(255),
  typical_turnaround_hours INT DEFAULT 24
) ENGINE=InnoDB;

CREATE TABLE lab_result (
  id INT AUTO_INCREMENT PRIMARY KEY,
  lab_test_id INT NOT NULL,
  patient_id INT NOT NULL,
  ordered_by INT, -- user id
  requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  result_data JSON, -- structured results
  result_text TEXT,
  result_date TIMESTAMP,
  status ENUM('Pending','Completed','Cancelled') DEFAULT 'Pending',
  CONSTRAINT fk_lr_test FOREIGN KEY (lab_test_id) REFERENCES lab_test(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_lr_patient FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_lr_ordered_by FOREIGN KEY (ordered_by) REFERENCES user_account(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Medications & Prescriptions (Prescription -> M-M -> medication via prescription_item)
CREATE TABLE medication (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  brand VARCHAR(255),
  strength VARCHAR(100), -- e.g. "500 mg"
  form VARCHAR(100), -- tablet, syrup, injection
  UNIQUE KEY uq_med_name_strength (name, strength, form)
) ENGINE=InnoDB;

CREATE TABLE prescription (
  id INT AUTO_INCREMENT PRIMARY KEY,
  prescription_ref VARCHAR(100) NOT NULL UNIQUE,
  patient_id INT NOT NULL,
  prescriber_id INT, -- typically a doctor (user_account or doctor mapping)
  issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  notes TEXT,
  status ENUM('Active','Completed','Cancelled') DEFAULT 'Active',
  CONSTRAINT fk_pres_patient FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pres_prescriber FOREIGN KEY (prescriber_id) REFERENCES user_account(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE prescription_item (
  prescription_id INT NOT NULL,
  medication_id INT NOT NULL,
  dosage VARCHAR(100) NOT NULL, -- "1 tablet", "5 ml"
  frequency VARCHAR(100), -- "twice daily"
  duration_days INT,
  instructions TEXT,
  PRIMARY KEY (prescription_id, medication_id),
  CONSTRAINT fk_pi_pres FOREIGN KEY (prescription_id) REFERENCES prescription(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pi_med FOREIGN KEY (medication_id) REFERENCES medication(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Admissions & Rooms (1-M: room has many admissions)
CREATE TABLE room (
  id INT AUTO_INCREMENT PRIMARY KEY,
  room_number VARCHAR(50) NOT NULL UNIQUE,
  type ENUM('General','Private','ICU','Operating','Maternity') NOT NULL DEFAULT 'General',
  floor VARCHAR(50),
  status ENUM('Available','Occupied','Maintenance') DEFAULT 'Available'
) ENGINE=InnoDB;

CREATE TABLE admission (
  id INT AUTO_INCREMENT PRIMARY KEY,
  admission_ref VARCHAR(100) NOT NULL UNIQUE,
  patient_id INT NOT NULL,
  admitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  discharged_at TIMESTAMP NULL,
  admitting_doctor_id INT,
  assigned_room_id INT,
  reason TEXT,
  status ENUM('Active','Discharged','Transferred') DEFAULT 'Active',
  CONSTRAINT fk_adm_patient FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_adm_doc FOREIGN KEY (admitting_doctor_id) REFERENCES doctor(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_adm_room FOREIGN KEY (assigned_room_id) REFERENCES room(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Billing: Invoice, Invoice items, Payment
CREATE TABLE invoice (
  id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_number VARCHAR(100) NOT NULL UNIQUE,
  patient_id INT NOT NULL,
  admission_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  due_date DATE,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status ENUM('Open','Paid','Partially Paid','Cancelled') DEFAULT 'Open',
  CONSTRAINT fk_invoice_patient FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_invoice_admission FOREIGN KEY (admission_id) REFERENCES admission(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE invoice_item (
  id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  description VARCHAR(255) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  unit_price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_price DECIMAL(12,2) AS (quantity * unit_price) STORED,
  CONSTRAINT fk_ii_invoice FOREIGN KEY (invoice_id) REFERENCES invoice(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE payment (
  id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  paid_by VARCHAR(255),
  amount DECIMAL(12,2) NOT NULL,
  method ENUM('Cash','Card','Insurance','Mobile Money','Cheque','Other') NOT NULL,
  paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  reference VARCHAR(255),
  CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES invoice(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Audit logs (basic)
CREATE TABLE audit_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  action VARCHAR(100) NOT NULL,
  entity VARCHAR(100),
  entity_id VARCHAR(100),
  details JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES user_account(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Useful indexes / constraints
ALTER TABLE appointment ADD INDEX idx_appointment_patient (patient_id);
ALTER TABLE appointment ADD INDEX idx_appointment_doctor (doctor_id);
ALTER TABLE medical_record ADD INDEX idx_mr_patient (patient_id);
ALTER TABLE lab_result ADD INDEX idx_lr_patient (patient_id);
ALTER TABLE prescription ADD INDEX idx_pres_patient (patient_id);
ALTER TABLE admission ADD INDEX idx_adm_patient (patient_id);
ALTER TABLE invoice ADD INDEX idx_invoice_patient (patient_id);


-- Example seed roles (optional)
INSERT INTO role (name, description) VALUES
  ('admin','System administrator with full privileges'),
  ('doctor','Medical doctor / prescriber'),
  ('nurse','Nursing staff'),
  ('reception','Front desk / receptionist'),
  ('billing','Billing clerk');

-- End of schema
