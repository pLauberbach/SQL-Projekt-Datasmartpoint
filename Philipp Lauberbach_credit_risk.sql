USE credit_risk;

CREATE TABLE credit_risk_data (
    person_age INT,
    person_income INT,
    person_home_ownership VARCHAR(255),
    person_emp_length DECIMAL(10, 2),
    loan_intent VARCHAR(255),
    loan_grade VARCHAR(255),
    loan_amnt INT,
    loan_int_rate DECIMAL(5, 2),
    loan_status BOOLEAN,
    loan_percent_income DECIMAL(5, 2),
    cb_person_default_on_file VARCHAR(50),
    cb_person_cred_hist_length INT
);

SHOW VARIABLES LIKE "secure_file_priv";

SET GLOBAL local_infile=1;
LOAD DATA INFILE 'credit_risk_dataset.csv'
INTO TABLE credit_risk_data
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(person_age,
 person_income,
 person_home_ownership,
 @person_emp_length,
 loan_intent,
 loan_grade,
 loan_amnt,
 @loan_int_rate,
 @loan_status,
 @loan_percent_income,
 cb_person_default_on_file,
 cb_person_cred_hist_length
)
SET
 person_emp_length = NULLIF(@person_emp_length, ''),
 loan_int_rate = NULLIF(@loan_int_rate, ''),
 loan_status = NULLIF(@loan_status, ''),
 loan_percent_income = NULLIF(@loan_percent_income, '');


SELECT * FROM credit_risk_data;

SELECT * FROM credit_risk_data 
WHERE person_emp_length IS NULL;

SELECT AVG(person_emp_length) FROM credit_risk_data;   -- Berechnung des Durchschnitts der Beschäftigungsdauer

SET SQL_SAFE_UPDATES = 1;

UPDATE credit_risk_data SET person_emp_length = 4.79 WHERE person_emp_length IS NULL; -- Vorher wurde der Durchschnitt von der Dauer der Beschäftigung ausgerechnet(4,79)


SELECT * FROM credit_risk_data 
WHERE loan_int_rate IS NULL;

SELECT AVG(loan_int_rate) FROM credit_risk_data;		-- Berechnung des Durchschnitts des Kreditzinssatzes
UPDATE credit_risk_data SET loan_int_rate = 11.01 WHERE loan_int_rate IS NULL; -- Der Durchschnitt wurde zuvor vom Kreditzinssatz ausgerechnet(11,01)

SELECT * FROM credit_risk_data 
WHERE loan_intent = "MEDICAL";

SELECT 
    *,
    CASE 
        WHEN risk_score >= 3 THEN 'high-risk'
        WHEN risk_score = 2 THEN 'medium-risk'
        ELSE 'low-risk'
    END AS risk_category
FROM 
	(SELECT 
		person_age,
		person_income,
		person_emp_length,
		loan_status,
		CASE  
			WHEN person_income < 50000 THEN 1 ELSE 0    -- Angestellte unter 50.000€ Einkommen bekommen einen Risikopunkt
		END + loan_status + CASE 
			WHEN person_emp_length < 6 THEN 1 ELSE 0 	-- Angestellte die unter 6 Jahren in dem Unternehmen arbeiten, bekommen einen Risikopunkt
		END AS risk_score
	FROM 
		credit_risk_data ) AS risk_score
	WHERE 														-- Nur Angestellte mit einem hohen Risiko werden angezeigt
		risk_score = 3;
	
        

SELECT 
    *,
    CASE 
        WHEN risk_score >= 3 THEN 'high-risk'
        WHEN risk_score = 2 THEN 'medium-risk'
        ELSE 'low-risk'
    END AS risk_category
FROM 
	(SELECT 
		person_age,
		person_income,
		person_emp_length,
		loan_status,
		CASE  
			WHEN person_income < 50000 THEN 1 ELSE 0    -- Angestellte unter 50.000€ Einkommen bekommen einen Risikopunkt
		END + loan_status + CASE 
			WHEN person_emp_length < 6 THEN 1 ELSE 0 	-- Angestellte die unter 6 Jahren in dem Unternehmen arbeiten, bekommen einen Risikopunkt
		END AS risk_score
	FROM 
		credit_risk_data ) AS risk_score
	WHERE 														
		risk_score <> 3;    							-- Nur Angestellte mit einem niedrigem oder mittlerem Risiko werden angezeigt




SELECT 
    risk_category,
    COUNT(*) AS employee_count
FROM 
    (SELECT 
        *,
        CASE 
            WHEN risk_score >= 3 THEN 'high-risk'
            WHEN risk_score = 2 THEN 'medium-risk'
            ELSE 'low-risk'
        END AS risk_category
    FROM 
        (SELECT 
            person_age,
            person_income,
            person_emp_length,
            loan_status,
            CASE  
                WHEN person_income < 50000 THEN 1 ELSE 0		-- Angestellte unter 50.000€ Einkommen bekommen einen Risikopunkt
            END + loan_status + CASE 
                WHEN person_emp_length < 6 THEN 1 ELSE 0		-- Angestellte die unter 6 Jahren in dem Unternehmen arbeiten, bekommen einen Risikopunkt
            END AS risk_score
        FROM 
            credit_risk_data) AS risk_score) AS risk_categories
GROUP BY 
    risk_category;												-- Gruppiert alle Angestellten in Gruppen und zeigt an welche Angestellten zu welcher Kategorie gehören


SELECT 
    loan_intent,
    COUNT(*) AS employee_count					-- Zählen welche Angestellte den Kredit für bestimmte Dinge benutzen
FROM 
    credit_risk_data
GROUP BY 
    loan_intent;



SELECT 
    loan_intent,
    risk_category,
    COUNT(*) AS employee_count
FROM 
    (SELECT 
        *,
        CASE 
            WHEN risk_score >= 3 THEN 'high-risk'
            WHEN risk_score = 2 THEN 'medium-risk'
            ELSE 'low-risk'
        END AS risk_category
    FROM 
        (SELECT 
            person_age,
            person_income,
            person_emp_length,
            loan_status,
            -- Risikopunkte berechnen
            CASE  
                WHEN person_income < 50000 THEN 1 ELSE 0
            END + loan_status + CASE 
                WHEN person_emp_length < 6 THEN 1 ELSE 0
            END AS risk_score,
            loan_intent
        FROM 
            credit_risk_data) AS risk_score) AS risk_categories
GROUP BY 
    loan_intent, risk_category;


-- Korrelation zwischen Einkommen und Kreditstatus

SELECT 
    AVG(person_income) AS avg_person_income,
    loan_status
FROM 
    credit_risk_data
GROUP BY 
    loan_status;


-- Korrelation zwischen Beschäftigungsdauer und Kreditwürdigkeit

SELECT 
    AVG(person_emp_length) AS person_emp_length,
    loan_status
FROM 
    credit_risk_data
GROUP BY 
    loan_status;


-- Korrelation zwischen Kreditzweck und Zinssatz

SELECT 
    loan_intent,
    AVG(loan_int_rate) AS loan_int_rate
FROM 
    credit_risk_data
GROUP BY 
    loan_intent;
    
    
 -- Korrelation zwischen Wohnsitzstatus und Kreditausfall   

SELECT 
    person_home_ownership,
    loan_status,
    COUNT(*) AS count
FROM 
    credit_risk_data
GROUP BY 
    person_home_ownership, loan_status;


-- Korrelation zwischen Kredithistorienlänge und Kreditmerkmalen

SELECT 
    cb_person_cred_hist_length AS credit_historie,
    loan_status,
    AVG(loan_amnt) AS avg_loan_amount,
    AVG(loan_int_rate) AS avg_loan_rate
FROM 
    credit_risk_data
GROUP BY 
    cb_person_cred_hist_length, loan_status;



-- Korrelation zwischen dem Einkommen, der für den Kredit aufgewendet wird, und dem Kreditstatus

SELECT 
    loan_status,
    AVG(loan_percent_income) AS loan_percent_income
FROM 
    credit_risk_data
GROUP BY 
    loan_status;


