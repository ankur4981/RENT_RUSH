
-- =============================================================================
-- VEHICLE RENTAL SYSTEM USING ORACLE SQL AND PL/SQL
-- Author: Ankur Kumar Singh
-- UID: 26MCC20023
-- Chandigarh University
-- =============================================================================

SET SERVEROUTPUT ON;

-- =============================================================================
-- SECTION 1: DROP EXISTING OBJECTS
-- =============================================================================

BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER trg_rate_audit';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER trg_rate_guard';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER trg_rental_id';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE sp_issue_vehicle';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE sp_return_vehicle';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE sp_list_available';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE sp_branch_report';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE sp_revise_rates';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION fn_calc_rent';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION fn_loyalty_discount';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION fn_is_available';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE rate_audit CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE rental CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE customer CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE vehicle CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE branch CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_rental';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_audit';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- =============================================================================
-- SECTION 2: CREATE SEQUENCES
-- =============================================================================

CREATE SEQUENCE seq_rental
START WITH 5001
INCREMENT BY 1
NOCACHE;

CREATE SEQUENCE seq_audit
START WITH 1
INCREMENT BY 1
NOCACHE;

-- =============================================================================
-- SECTION 3: CREATE TABLES AND CONSTRAINTS
-- =============================================================================

CREATE TABLE branch (
    branch_id   NUMBER(3)
        CONSTRAINT pk_branch PRIMARY KEY,
    branch_name VARCHAR2(50) NOT NULL,
    city        VARCHAR2(30) NOT NULL
);

CREATE TABLE vehicle (
    vehicle_id    NUMBER(4)
        CONSTRAINT pk_vehicle PRIMARY KEY,
    reg_no        VARCHAR2(15) NOT NULL
        CONSTRAINT unq_vehicle_reg UNIQUE,
    model         VARCHAR2(50) NOT NULL,
    vehicle_type  VARCHAR2(10) NOT NULL
        CONSTRAINT chk_vehicle_type
        CHECK (vehicle_type IN ('BIKE', 'SCOOTER', 'CAR')),
    branch_id     NUMBER(3) NOT NULL
        CONSTRAINT fk_vehicle_branch REFERENCES branch(branch_id),
    rate_per_hour NUMBER(8,2) NOT NULL
        CONSTRAINT chk_rate_hour CHECK (rate_per_hour > 0),
    rate_per_day  NUMBER(8,2) NOT NULL
        CONSTRAINT chk_rate_day CHECK (rate_per_day > 0),
    status        VARCHAR2(12) DEFAULT 'AVAILABLE' NOT NULL
        CONSTRAINT chk_vehicle_status
        CHECK (status IN ('AVAILABLE', 'RENTED', 'MAINTENANCE'))
);

CREATE TABLE customer (
    cust_id    NUMBER(4)
        CONSTRAINT pk_customer PRIMARY KEY,
    cust_name  VARCHAR2(50) NOT NULL,
    phone      VARCHAR2(15) NOT NULL
        CONSTRAINT unq_cust_phone UNIQUE,
    license_no VARCHAR2(20) NOT NULL
        CONSTRAINT unq_cust_license UNIQUE,
    city       VARCHAR2(30) NOT NULL
);

CREATE TABLE rental (
    rental_id      NUMBER(6)
        CONSTRAINT pk_rental PRIMARY KEY,
    cust_id        NUMBER(4) NOT NULL
        CONSTRAINT fk_rental_cust REFERENCES customer(cust_id),
    vehicle_id     NUMBER(4) NOT NULL
        CONSTRAINT fk_rental_vehicle REFERENCES vehicle(vehicle_id),
    start_time     DATE DEFAULT SYSDATE NOT NULL,
    expected_hours NUMBER(4) NOT NULL
        CONSTRAINT chk_expected_hours CHECK (expected_hours > 0),
    end_time       DATE,
    hours_used     NUMBER(4),
    base_amount    NUMBER(8,2),
    late_fee       NUMBER(8,2),
    discount       NUMBER(8,2),
    total_amount   NUMBER(8,2),
    status         VARCHAR2(8) DEFAULT 'OPEN' NOT NULL
        CONSTRAINT chk_rental_status CHECK (status IN ('OPEN', 'CLOSED'))
);

CREATE TABLE rate_audit (
    audit_id   NUMBER
        CONSTRAINT pk_rate_audit PRIMARY KEY,
    vehicle_id NUMBER(4) NOT NULL
        CONSTRAINT fk_audit_vehicle REFERENCES vehicle(vehicle_id),
    old_rate   NUMBER(8,2) NOT NULL,
    new_rate   NUMBER(8,2) NOT NULL,
    changed_on DATE DEFAULT SYSDATE NOT NULL,
    changed_by VARCHAR2(30) DEFAULT USER NOT NULL
);

-- =============================================================================
-- SECTION 4: INSERT SAMPLE DATA
-- =============================================================================

-- Branches

INSERT INTO branch
VALUES (10, 'Sector 17 Hub', 'Chandigarh');

INSERT INTO branch
VALUES (20, 'Phase 7 Hub', 'Mohali');

INSERT INTO branch
VALUES (30, 'CU Hub', 'Gharuan');

-- Vehicles

INSERT INTO vehicle
VALUES (201, 'CH01AB1234', 'Royal Enfield Classic 350',
        'BIKE', 10, 120.00, 900.00, 'AVAILABLE');

INSERT INTO vehicle
VALUES (202, 'PB65CD5678', 'Activa 6G',
        'SCOOTER', 20, 60.00, 450.00, 'AVAILABLE');

INSERT INTO vehicle
VALUES (203, 'PB65EF9012', 'Pulsar N250',
        'BIKE', 20, 80.00, 600.00, 'AVAILABLE');

INSERT INTO vehicle
VALUES (204, 'CH01GH3456', 'Thar 4x4',
        'CAR', 10, 300.00, 2200.00, 'MAINTENANCE');

INSERT INTO vehicle
VALUES (205, 'PB65IJ7890', 'TVS Jupiter',
        'SCOOTER', 20, 50.00, 400.00, 'AVAILABLE');

INSERT INTO vehicle
VALUES (206, 'HR03KL1234', 'KTM Duke 200',
        'BIKE', 30, 100.00, 750.00, 'AVAILABLE');

INSERT INTO vehicle
VALUES (207, 'CH01MN5678', 'Hyundai Creta',
        'CAR', 10, 250.00, 1800.00, 'AVAILABLE');

INSERT INTO vehicle
VALUES (208, 'PB65OP9012', 'Hero Splendor+',
        'BIKE', 30, 50.00, 350.00, 'AVAILABLE');

-- Customers

INSERT INTO customer
VALUES (301, 'Rahul Verma', '9876543210',
        'DL0120120001234', 'Chandigarh');

INSERT INTO customer
VALUES (302, 'Simran Kaur', '9876543211',
        'PB6520150005678', 'Mohali');

INSERT INTO customer
VALUES (303, 'Aman Gupta', '9876543212',
        'CH0120180009012', 'Chandigarh');

INSERT INTO customer
VALUES (304, 'Neha Singh', '9876543213',
        'HR0320190003456', 'Panchkula');

INSERT INTO customer
VALUES (305, 'Karan Mehta', '9876543214',
        'DL0220200007890', 'Delhi');

-- Historical closed rentals for customer 301

INSERT INTO rental (
    rental_id, cust_id, vehicle_id, start_time, expected_hours,
    end_time, hours_used, base_amount, late_fee,
    discount, total_amount, status
)
VALUES (
    seq_rental.NEXTVAL, 301, 201,
    TO_DATE('2026-10-01 09:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    5,
    TO_DATE('2026-10-01 14:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    5, 600.00, 0.00, 0.00, 600.00, 'CLOSED'
);

INSERT INTO rental (
    rental_id, cust_id, vehicle_id, start_time, expected_hours,
    end_time, hours_used, base_amount, late_fee,
    discount, total_amount, status
)
VALUES (
    seq_rental.NEXTVAL, 301, 203,
    TO_DATE('2026-10-05 10:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    6,
    TO_DATE('2026-10-05 16:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    6, 480.00, 0.00, 0.00, 480.00, 'CLOSED'
);

COMMIT;

-- =============================================================================
-- SECTION 5: FUNCTIONS
-- =============================================================================

-- 5.1 Calculate Rent Function

CREATE OR REPLACE FUNCTION fn_calc_rent (
    p_vehicle_id IN NUMBER,
    p_hours      IN NUMBER
)
RETURN NUMBER
IS
    v_rate_hour vehicle.rate_per_hour%TYPE;
    v_rate_day  vehicle.rate_per_day%TYPE;
    v_full_days NUMBER;
    v_rem_hours NUMBER;
    v_base_rent NUMBER;
BEGIN
    IF p_hours IS NULL OR p_hours <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20011,
            'Rental hours must be greater than zero.'
        );
    END IF;

    SELECT rate_per_hour, rate_per_day
    INTO v_rate_hour, v_rate_day
    FROM vehicle
    WHERE vehicle_id = p_vehicle_id;

    v_full_days := FLOOR(p_hours / 24);
    v_rem_hours := MOD(p_hours, 24);

    v_base_rent :=
        (v_full_days * v_rate_day)
        + LEAST(v_rem_hours * v_rate_hour, v_rate_day);

    RETURN v_base_rent;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Vehicle ID not found for rent calculation.'
        );
END fn_calc_rent;
/

-- 5.2 Loyalty Discount Function

CREATE OR REPLACE FUNCTION fn_loyalty_discount (
    p_cust_id IN NUMBER
)
RETURN NUMBER
IS
    v_closed_count NUMBER := 0;
    v_discount_pct NUMBER := 0;
BEGIN
    SELECT COUNT(*)
    INTO v_closed_count
    FROM rental
    WHERE cust_id = p_cust_id
      AND status = 'CLOSED';

    IF v_closed_count >= 4 THEN
        v_discount_pct := 10;
    ELSIF v_closed_count >= 2 THEN
        v_discount_pct := 5;
    ELSE
        v_discount_pct := 0;
    END IF;

    RETURN v_discount_pct;
END fn_loyalty_discount;
/

-- 5.3 Availability Function

CREATE OR REPLACE FUNCTION fn_is_available (
    p_vehicle_id IN NUMBER
)
RETURN VARCHAR2
IS
    v_status vehicle.status%TYPE;
BEGIN
    SELECT status
    INTO v_status
    FROM vehicle
    WHERE vehicle_id = p_vehicle_id;

    IF v_status = 'AVAILABLE' THEN
        RETURN 'Y';
    ELSE
        RETURN 'N';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'N';
END fn_is_available;
/

-- =============================================================================
-- SECTION 6: TRIGGERS
-- =============================================================================

-- 6.1 Automatic Rental ID Trigger

CREATE OR REPLACE TRIGGER trg_rental_id
BEFORE INSERT ON rental
FOR EACH ROW
BEGIN
    IF :NEW.rental_id IS NULL THEN
        :NEW.rental_id := seq_rental.NEXTVAL;
    END IF;
END trg_rental_id;
/

-- 6.2 Rate Protection Trigger

CREATE OR REPLACE TRIGGER trg_rate_guard
BEFORE UPDATE OF rate_per_hour ON vehicle
FOR EACH ROW
BEGIN
    IF :NEW.rate_per_hour <= 0
       OR :NEW.rate_per_hour > (:OLD.rate_per_hour * 2)
    THEN
        RAISE_APPLICATION_ERROR(
            -20010,
            'Hourly rate must be positive and at most double the old rate.'
        );
    END IF;
END trg_rate_guard;
/

-- 6.3 Rate Audit Logging Trigger

CREATE OR REPLACE TRIGGER trg_rate_audit
AFTER UPDATE OF rate_per_hour ON vehicle
FOR EACH ROW
BEGIN
    INSERT INTO rate_audit (
        audit_id,
        vehicle_id,
        old_rate,
        new_rate,
        changed_on,
        changed_by
    )
    VALUES (
        seq_audit.NEXTVAL,
        :OLD.vehicle_id,
        :OLD.rate_per_hour,
        :NEW.rate_per_hour,
        SYSDATE,
        USER
    );
END trg_rate_audit;
/

-- =============================================================================
-- SECTION 7: STORED PROCEDURES
-- =============================================================================

-- 7.1 Issue Vehicle Procedure

CREATE OR REPLACE PROCEDURE sp_issue_vehicle (
    p_cust_id        IN NUMBER,
    p_vehicle_id     IN NUMBER,
    p_expected_hours IN NUMBER,
    p_rental_id      OUT NUMBER
)
IS
    v_cust_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_cust_exists
    FROM customer
    WHERE cust_id = p_cust_id;

    IF v_cust_exists = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20020,
            'Customer ID ' || p_cust_id || ' does not exist.'
        );
    END IF;

    IF fn_is_available(p_vehicle_id) = 'N' THEN
        RAISE_APPLICATION_ERROR(
            -20021,
            'Vehicle does not exist or is not available.'
        );
    END IF;

    INSERT INTO rental (
        cust_id,
        vehicle_id,
        start_time,
        expected_hours,
        status
    )
    VALUES (
        p_cust_id,
        p_vehicle_id,
        SYSDATE,
        p_expected_hours,
        'OPEN'
    )
    RETURNING rental_id INTO p_rental_id;

    UPDATE vehicle
    SET status = 'RENTED'
    WHERE vehicle_id = p_vehicle_id;

    DBMS_OUTPUT.PUT_LINE(
        'Vehicle ' || p_vehicle_id ||
        ' issued to Customer ' || p_cust_id ||
        '. Rental ID: ' || p_rental_id
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END sp_issue_vehicle;
/

-- 7.2 Return Vehicle Procedure

CREATE OR REPLACE PROCEDURE sp_return_vehicle (
    p_rental_id IN NUMBER,
    p_end_time  IN DATE DEFAULT SYSDATE
)
IS
    v_rec        rental%ROWTYPE;
    v_rate_hour  vehicle.rate_per_hour%TYPE;
    v_hours_used NUMBER;
    v_base_rent  NUMBER;
    v_late_fee   NUMBER := 0;
    v_disc_pct   NUMBER := 0;
    v_discount   NUMBER := 0;
    v_total      NUMBER := 0;
BEGIN
    SELECT *
    INTO v_rec
    FROM rental
    WHERE rental_id = p_rental_id
    FOR UPDATE;

    IF v_rec.status = 'CLOSED' THEN
        RAISE_APPLICATION_ERROR(
            -20022,
            'This rental has already been closed.'
        );
    END IF;

    IF p_end_time < v_rec.start_time THEN
        RAISE_APPLICATION_ERROR(
            -20023,
            'Return time cannot be before rental start time.'
        );
    END IF;

    v_hours_used := GREATEST(
        CEIL((p_end_time - v_rec.start_time) * 24),
        1
    );

    v_base_rent := fn_calc_rent(
        v_rec.vehicle_id,
        v_hours_used
    );

    SELECT rate_per_hour
    INTO v_rate_hour
    FROM vehicle
    WHERE vehicle_id = v_rec.vehicle_id;

    IF v_hours_used > v_rec.expected_hours THEN
        v_late_fee :=
            (v_hours_used - v_rec.expected_hours)
            * v_rate_hour * 0.50;
    END IF;

    v_disc_pct := fn_loyalty_discount(v_rec.cust_id);
    v_discount := (v_base_rent * v_disc_pct) / 100;

    v_total := v_base_rent + v_late_fee - v_discount;

    UPDATE rental
    SET end_time     = p_end_time,
        hours_used   = v_hours_used,
        base_amount  = v_base_rent,
        late_fee     = v_late_fee,
        discount     = v_discount,
        total_amount = v_total,
        status       = 'CLOSED'
    WHERE rental_id = p_rental_id;

    UPDATE vehicle
    SET status = 'AVAILABLE'
    WHERE vehicle_id = v_rec.vehicle_id;

    DBMS_OUTPUT.PUT_LINE(
        'Rental ' || p_rental_id ||
        ' closed. Hours: ' || v_hours_used ||
        ' | Base: ' || TO_CHAR(v_base_rent, 'FM9999990.00') ||
        ' | Late: ' || TO_CHAR(v_late_fee, 'FM9999990.00') ||
        ' | Discount: ' || TO_CHAR(v_discount, 'FM9999990.00') ||
        ' | Total: ' || TO_CHAR(v_total, 'FM9999990.00')
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20024,
            'Rental ID ' || p_rental_id || ' not found.'
        );
END sp_return_vehicle;
/

-- 7.3 List Available Vehicles

CREATE OR REPLACE PROCEDURE sp_list_available (
    p_branch_id IN NUMBER
)
IS
    CURSOR c_avail (p_b_id NUMBER) IS
        SELECT vehicle_id, model, vehicle_type,
               rate_per_hour, rate_per_day
        FROM vehicle
        WHERE branch_id = p_b_id
          AND status = 'AVAILABLE';

    v_found BOOLEAN := FALSE;
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        '--- Available Vehicles for Branch: ' || p_branch_id || ' ---'
    );

    FOR r IN c_avail(p_branch_id) LOOP
        v_found := TRUE;

        DBMS_OUTPUT.PUT_LINE(
            'ID: ' || r.vehicle_id ||
            ' | Model: ' || r.model ||
            ' | Type: ' || r.vehicle_type ||
            ' | Rate/Hr: ' || r.rate_per_hour ||
            ' | Rate/Day: ' || r.rate_per_day
        );
    END LOOP;

    IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE(
            'No available vehicles found for this branch.'
        );
    END IF;
END sp_list_available;
/

-- 7.4 Branch Summary Report Procedure

CREATE OR REPLACE PROCEDURE sp_branch_report
IS
    CURSOR c_branches IS
        SELECT branch_id, branch_name
        FROM branch
        ORDER BY branch_id;

    CURSOR c_summary (p_b_id NUMBER) IS
        SELECT
            COUNT(v.vehicle_id) AS total_fleet,
            COUNT(
                CASE WHEN v.status = 'RENTED'
                     THEN v.vehicle_id
                END
            ) AS currently_rented,
            NVL(SUM(r.total_trips), 0) AS total_trips,
            NVL(SUM(r.total_revenue), 0) AS total_revenue
        FROM vehicle v
        LEFT JOIN (
            SELECT
                vehicle_id,
                COUNT(*) AS total_trips,
                SUM(total_amount) AS total_revenue
            FROM rental
            WHERE status = 'CLOSED'
            GROUP BY vehicle_id
        ) r
            ON r.vehicle_id = v.vehicle_id
        WHERE v.branch_id = p_b_id;

    v_fleet     NUMBER;
    v_rented    NUMBER;
    v_trips     NUMBER;
    v_rev       NUMBER;
    v_grand_rev NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        '===================================================================='
    );
    DBMS_OUTPUT.PUT_LINE(
        '                 BRANCH REVENUE AND FLEET REPORT'
    );
    DBMS_OUTPUT.PUT_LINE(
        '===================================================================='
    );

    FOR b IN c_branches LOOP
        OPEN c_summary(b.branch_id);

        FETCH c_summary
        INTO v_fleet, v_rented, v_trips, v_rev;

        CLOSE c_summary;

        DBMS_OUTPUT.PUT_LINE(
            'Branch: ' || RPAD(b.branch_name, 20) ||
            ' Fleet: ' || LPAD(v_fleet, 2) ||
            ' | Rented: ' || LPAD(v_rented, 2) ||
            ' | Closed Trips: ' || LPAD(v_trips, 2) ||
            ' | Revenue: Rs.' ||
            TO_CHAR(v_rev, 'FM999,999,990.00')
        );

        v_grand_rev := v_grand_rev + v_rev;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(
        '--------------------------------------------------------------------'
    );

    DBMS_OUTPUT.PUT_LINE(
        'GRAND TOTAL REVENUE: Rs.' ||
        TO_CHAR(v_grand_rev, 'FM999,999,990.00')
    );

    DBMS_OUTPUT.PUT_LINE(
        '===================================================================='
    );
END sp_branch_report;
/

-- 7.5 Revise Vehicle Rates Procedure

CREATE OR REPLACE PROCEDURE sp_revise_rates (
    p_vehicle_type IN VARCHAR2,
    p_pct          IN NUMBER
)
IS
    CURSOR c_rates IS
        SELECT vehicle_id, rate_per_hour
        FROM vehicle
        WHERE vehicle_type = UPPER(p_vehicle_type)
        FOR UPDATE OF rate_per_hour;

    v_new_rate NUMBER;
BEGIN
    IF p_pct IS NULL OR p_pct < 1 OR p_pct > 25 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Rate change percentage must be between 1 and 25.'
        );
    END IF;

    FOR r IN c_rates LOOP
        v_new_rate := ROUND(
            r.rate_per_hour * (1 + p_pct / 100),
            2
        );

        UPDATE vehicle
        SET rate_per_hour = v_new_rate
        WHERE CURRENT OF c_rates;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(
        'Hourly rates revised for ' ||
        UPPER(p_vehicle_type) ||
        ' vehicles by ' || p_pct || '%.'
    );
END sp_revise_rates;
/

-- =============================================================================
-- SECTION 8: EXECUTION AND TEST CASES
-- =============================================================================

-- Display available vehicles

BEGIN
    sp_list_available(20);
END;
/

-- Increase scooter hourly rates by 10%

BEGIN
    sp_revise_rates('SCOOTER', 10);
END;
/

-- TEST CASE 1: RENTAL CYCLE AND BILLING

DECLARE
    v_r1  NUMBER;
    v_r2  NUMBER;
    v_r3  NUMBER;
    v_r4  NUMBER;
    v_r5  NUMBER;
    v_now DATE := SYSDATE;
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        '--- TEST CASE 1: ISSUE AND RETURN VEHICLES ---'
    );

    -- Issue five rentals

    sp_issue_vehicle(301, 201, 5, v_r1);
    sp_issue_vehicle(302, 203, 6, v_r2);
    sp_issue_vehicle(303, 205, 30, v_r3);
    sp_issue_vehicle(304, 207, 48, v_r4);
    sp_issue_vehicle(305, 206, 12, v_r5);

    -- Return four rentals

    sp_return_vehicle(v_r1, v_now + (7 / 24));
    sp_return_vehicle(v_r2, v_now + (6 / 24));
    sp_return_vehicle(v_r3, v_now + (36 / 24));
    sp_return_vehicle(v_r4, v_now + (48 / 24));

    DBMS_OUTPUT.PUT_LINE(
        'Rental ' || v_r5 || ' remains OPEN for testing.'
    );
END;
/

-- Generate branch report

BEGIN
    sp_branch_report;
END;
/

-- TEST CASE 2: INVALID REQUESTS AND TRIGGERS

-- 1. Attempt to issue a maintenance vehicle

DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Testing: Issue maintenance vehicle'
    );

    BEGIN
        sp_issue_vehicle(301, 204, 5, v_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
    END;
END;
/

-- 2. Attempt to issue an already rented vehicle

DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Testing: Issue already rented vehicle'
    );

    BEGIN
        sp_issue_vehicle(302, 206, 5, v_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
    END;
END;
/

-- 3. Attempt to return an already closed rental

BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Testing: Return already closed rental'
    );

    BEGIN
        sp_return_vehicle(5003);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
    END;
END;
/

-- 4. Attempt invalid rate revision

BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Testing: Invalid rate revision percentage'
    );

    BEGIN
        sp_revise_rates('BIKE', 50);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
    END;
END;
/

-- 5. Attempt to increase a vehicle rate beyond double its old rate

BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Testing: Rate guard trigger violation'
    );

    BEGIN
        UPDATE vehicle
        SET rate_per_hour = 500
        WHERE vehicle_id = 201;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
    END;
END;
/

-- =============================================================================
-- SECTION 9: FINAL VERIFICATION
-- =============================================================================

-- Display rental records

SELECT *
FROM rental
ORDER BY rental_id;

-- Display vehicle records

SELECT *
FROM vehicle
ORDER BY vehicle_id;

-- Display branch report

BEGIN
    sp_branch_report;
END;
/

-- Display rate audit log

SELECT *
FROM rate_audit
ORDER BY audit_id;

-- Display stored-object compilation errors

SELECT name, type, line, position, text
FROM user_errors
ORDER BY name, sequence;

-- Display invalid objects

SELECT object_name, object_type, status
FROM user_objects
WHERE status = 'INVALID'
ORDER BY object_type, object_name;

COMMIT;

-- =============================================================================
-- END OF VEHICLE RENTAL SYSTEM
-- =============================================================================
