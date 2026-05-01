-- =========================
-- 1. SCHEMA / TABLES
-- =========================

CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE sellers (
    seller_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    rating NUMERIC(2,1) CHECK (rating BETWEEN 0 AND 5),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    registration_date TIMESTAMP DEFAULT NOW()
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    price NUMERIC(10,2),
    stock INT,
    category_id INT REFERENCES categories(category_id),
    seller_id INT REFERENCES sellers(seller_id)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date TIMESTAMP DEFAULT NOW(),
    total_amount NUMERIC(10,2)
);

CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    item_price NUMERIC(10,2)
);

-- =========================
-- 2. SAMPLE DATA
-- =========================

INSERT INTO categories(name, description)
VALUES 
('Cars', 'Car category'),
('Phones', 'Mobile phones'),
('Laptops', 'Computers');

INSERT INTO sellers(name, email, phone, address, rating)
VALUES
('Aidos', 'aidos@mail.com', '87011111111', 'Almaty', 4.9),
('Dias', 'dias@mail.com', '87022222222', 'Astana', 4.7);

INSERT INTO customers(name, email, phone, address)
VALUES
('Arman', 'arman@mail.com', '87770000001', 'Almaty'),
('Dana', 'dana@mail.com', '87770000002', 'Astana');

INSERT INTO products(product_name, price, stock, category_id, seller_id)
VALUES
('Toyota Camry', 15000000, 2, 1, 1),
('iPhone 15', 650000, 10, 2, 2),
('MacBook Air', 850000, 5, 3, 2);

INSERT INTO orders(customer_id, total_amount)
VALUES
(1, 650000),
(2, 15000000);

INSERT INTO order_items(order_id, product_id, quantity, item_price)
VALUES
(1, 2, 1, 650000),
(2, 1, 1, 15000000);

-- =========================
-- 3. PROCEDURES
-- =========================

CREATE OR REPLACE PROCEDURE add_product(
    p_name VARCHAR,
    p_price NUMERIC,
    p_stock INT,
    p_category INT,
    p_seller INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO products(product_name, price, stock, category_id, seller_id)
    VALUES(p_name, p_price, p_stock, p_category, p_seller);
END;
$$;

CREATE OR REPLACE PROCEDURE update_price(
    p_id INT,
    p_price NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET price = p_price
    WHERE product_id = p_id;
END;
$$;

CREATE OR REPLACE PROCEDURE reduce_stock(
    p_id INT,
    p_qty INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET stock = stock - p_qty
    WHERE product_id = p_id;
END;
$$;

-- =========================
-- 4. FUNCTIONS
-- =========================

CREATE OR REPLACE FUNCTION total_products()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE total INT;
BEGIN
    SELECT COUNT(*) INTO total FROM products;
    RETURN total;
END;
$$;

CREATE OR REPLACE FUNCTION total_orders()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE total INT;
BEGIN
    SELECT COUNT(*) INTO total FROM orders;
    RETURN total;
END;
$$;

CREATE OR REPLACE FUNCTION avg_rating()
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE avg_r NUMERIC;
BEGIN
    SELECT AVG(rating) INTO avg_r FROM sellers;
    RETURN avg_r;
END;
$$;

CREATE OR REPLACE FUNCTION check_stock(p_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE qty INT;
BEGIN
    SELECT stock INTO qty FROM products WHERE product_id = p_id;
    RETURN qty;
END;
$$;

-- =========================
-- 5. TRIGGERS
-- =========================

-- LOG TABLE
CREATE TABLE product_logs (
    log_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    action_type VARCHAR(20),
    action_time TIMESTAMP DEFAULT NOW()
);

-- LOG TRIGGER
CREATE OR REPLACE FUNCTION log_product()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO product_logs(product_name, action_type)
    VALUES(NEW.product_name, 'INSERT');
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_log
AFTER INSERT ON products
FOR EACH ROW
EXECUTE FUNCTION log_product();

-- STOCK CHECK TRIGGER
CREATE OR REPLACE FUNCTION check_negative_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.stock < 0 THEN
        RAISE EXCEPTION 'Stock cannot be negative';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_stock
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION check_negative_stock();

-- FIX VERSION (OPTIONAL)
CREATE OR REPLACE FUNCTION fix_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.stock < 0 THEN
        NEW.stock := 0;
    END IF;
    RETURN NEW;
END;
$$;

-- =========================
-- 6. TRANSACTIONS EXAMPLES
-- =========================

-- COMMIT
BEGIN;
UPDATE products SET stock = stock - 1 WHERE product_id = 1;
COMMIT;

-- ROLLBACK
BEGIN;
UPDATE products SET stock = stock - 100 WHERE product_id = 1;
ROLLBACK;

-- SAVEPOINT
BEGIN;
UPDATE products SET stock = stock - 1 WHERE product_id = 1;
SAVEPOINT sp1;
UPDATE products SET stock = stock - 100 WHERE product_id = 1;
ROLLBACK TO sp1;
COMMIT;
