# MySQL Database Management System – Library Management Example

## Objective
This project is a **Complete Database Management System** designed using **MySQL** for a **Library Management System**.  
It contains table creation, constraints, and relationships that allow management of books, members, and borrowing transactions.

---

## Features
- Structured relational database design
- Proper constraints:
  - **Primary Keys (PK)**
  - **Foreign Keys (FK)**
  - **NOT NULL**
  - **UNIQUE**
- Relationship types:
  - One-to-One (e.g., Member → Membership Card)
  - One-to-Many (e.g., Category → Books)
  - Many-to-Many (e.g., Books ↔ Authors)

---

## Requirements
- MySQL Server (8.0+ recommended)
- MySQL Client (CLI, MySQL Workbench, or phpMyAdmin)
- (Optional) XAMPP/WAMP for local development

---

## Database Structure

### Tables
1. **members** – Stores library member details  
2. **membership_cards** – One-to-one with members  
3. **categories** – Book categories (Fiction, Science, etc.)  
4. **books** – Stores book details  
5. **authors** – Book authors  
6. **book_authors** – Junction table for many-to-many relationship between books & authors  
7. **borrow_transactions** – Tracks book borrowing and return

---

## SQL Script

```sql
-- Create Database
CREATE DATABASE library_db;
USE library_db;

-- Table: members
CREATE TABLE members (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    join_date DATE NOT NULL
);

-- Table: membership_cards (1-to-1 with members)
CREATE TABLE membership_cards (
    card_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT UNIQUE,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);

-- Table: categories
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(50) UNIQUE NOT NULL
);

-- Table: books
CREATE TABLE books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(150) NOT NULL,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    publish_year YEAR NOT NULL,
    category_id INT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Table: authors
CREATE TABLE authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL
);

-- Table: book_authors (Many-to-Many between books and authors)
CREATE TABLE book_authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
);

-- Table: borrow_transactions
CREATE TABLE borrow_transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    borrow_date DATE NOT NULL,
    return_date DATE,
    FOREIGN KEY (member_id) REFERENCES members(member_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
);
