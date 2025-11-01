-- ============================================
-- ORACLE FINANCIAL REPORTS
-- Finance Tracker Application
-- ============================================

-- ===== REPORT 1: MONTHLY EXPENDITURE SUMMARY =====

CREATE OR REPLACE PROCEDURE report_monthly_expenditure(
    p_user_id IN NUMBER,
    p_month IN VARCHAR2
) AS
    CURSOR monthly_cursor IS
        SELECT
            TRUNC(expense_date, 'MM') AS month,
            category,
            SUM(amount) AS total_amount,
            COUNT(*) AS transaction_count,
            AVG(amount) AS avg_amount
        FROM expense
        WHERE user_id = p_user_id
        AND TO_CHAR(expense_date, 'YYYY-MM') = p_month
        GROUP BY TRUNC(expense_date, 'MM'), category
        ORDER BY total_amount DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== MONTHLY EXPENDITURE SUMMARY =====');
    DBMS_OUTPUT.PUT_LINE('User ID: ' || p_user_id || ' | Month: ' || p_month);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');

    FOR rec IN monthly_cursor LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Category: ' || rec.category ||
            ' | Total: ' || TO_CHAR(rec.total_amount, '99999.99') ||
            ' | Count: ' || rec.transaction_count ||
            ' | Avg: ' || TO_CHAR(rec.avg_amount, '9999.99')
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END report_monthly_expenditure;
/

-- ===== REPORT 2: BUDGET ADHERENCE ANALYSIS =====

CREATE OR REPLACE PROCEDURE report_budget_adherence(
    p_user_id IN NUMBER
) AS
    CURSOR budget_cursor IS
        SELECT
            b.id,
            b.category,
            b.budget_amount,
            NVL(SUM(e.amount), 0) AS actual_spent,
            ROUND((NVL(SUM(e.amount), 0) / b.budget_amount) * 100, 2) AS percentage_used,
            b.budget_amount - NVL(SUM(e.amount), 0) AS remaining_budget,
            CASE
                WHEN (NVL(SUM(e.amount), 0) / b.budget_amount) * 100 >= 100 THEN 'EXCEEDED'
                WHEN (NVL(SUM(e.amount), 0) / b.budget_amount) * 100 >= 80 THEN 'WARNING'
                ELSE 'SAFE'
            END AS status
        FROM budgets b
        LEFT JOIN expense e ON b.user_id = e.user_id AND b.category = e.category
        WHERE b.user_id = p_user_id
        GROUP BY b.id, b.category, b.budget_amount
        ORDER BY percentage_used DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== BUDGET ADHERENCE ANALYSIS =====');
    DBMS_OUTPUT.PUT_LINE('User ID: ' || p_user_id);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');

    FOR rec IN budget_cursor LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Category: ' || rec.category ||
            ' | Budget: ' || TO_CHAR(rec.budget_amount, '99999.99') ||
            ' | Spent: ' || TO_CHAR(rec.actual_spent, '99999.99') ||
            ' | Used: ' || rec.percentage_used || '%' ||
            ' | Status: ' || rec.status
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END report_budget_adherence;
/

-- ===== REPORT 3: SAVINGS GOAL PROGRESS =====

CREATE OR REPLACE PROCEDURE report_savings_progress(
    p_user_id IN NUMBER
) AS
    CURSOR savings_cursor IS
        SELECT
            id,
            goal_name,
            target_amount,
            current_amount,
            ROUND((current_amount / target_amount) * 100, 2) AS progress_percentage,
            target_amount - current_amount AS remaining_amount,
            ROUND(MONTHS_BETWEEN(end_date, SYSDATE), 1) AS months_remaining,
            CASE
                WHEN current_amount >= target_amount THEN 'COMPLETED'
                WHEN (current_amount / target_amount) * 100 >= 75 THEN 'ON TRACK'
                WHEN (current_amount / target_amount) * 100 >= 50 THEN 'MIDWAY'
                ELSE 'STARTING'
            END AS goal_status
        FROM savings
        WHERE user_id = p_user_id
        ORDER BY progress_percentage DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== SAVINGS GOAL PROGRESS REPORT =====');
    DBMS_OUTPUT.PUT_LINE('User ID: ' || p_user_id);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');

    FOR rec IN savings_cursor LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Goal: ' || rec.goal_name ||
            ' | Target: ' || TO_CHAR(rec.target_amount, '99999.99') ||
            ' | Current: ' || TO_CHAR(rec.current_amount, '99999.99') ||
            ' | Progress: ' || rec.progress_percentage || '%' ||
            ' | Status: ' || rec.goal_status
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END report_savings_progress;
/

-- ===== REPORT 4: CATEGORY-WISE EXPENSE DISTRIBUTION =====

CREATE OR REPLACE PROCEDURE report_expense_distribution(
    p_user_id IN NUMBER
) AS
    v_total_expenses NUMBER(10,2) := 0;
    CURSOR category_cursor IS
        SELECT
            category,
            SUM(amount) AS category_total,
            COUNT(*) AS transaction_count,
            AVG(amount) AS avg_amount,
            MAX(amount) AS max_amount,
            MIN(amount) AS min_amount
        FROM expense
        WHERE user_id = p_user_id
        GROUP BY category
        ORDER BY category_total DESC;
BEGIN
    -- Calculate total expenses
    SELECT SUM(amount) INTO v_total_expenses FROM expense WHERE user_id = p_user_id;

    DBMS_OUTPUT.PUT_LINE('===== EXPENSE DISTRIBUTION BY CATEGORY =====');
    DBMS_OUTPUT.PUT_LINE('User ID: ' || p_user_id);
    DBMS_OUTPUT.PUT_LINE('Total Expenses: ' || TO_CHAR(v_total_expenses, '99999.99'));
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');

    FOR rec IN category_cursor LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Category: ' || rec.category ||
            ' | Total: ' || TO_CHAR(rec.category_total, '99999.99') ||
            ' | % of Total: ' || ROUND((rec.category_total / v_total_expenses) * 100, 2) || '%' ||
            ' | Count: ' || rec.transaction_count ||
            ' | Avg: ' || TO_CHAR(rec.avg_amount, '9999.99')
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END report_expense_distribution;
/

-- ===== REPORT 5: EXPENSE TREND & FORECAST =====

CREATE OR REPLACE PROCEDURE report_expense_trends(
    p_user_id IN NUMBER
) AS
    v_avg_daily_spending NUMBER(10,2);
    v_projected_monthly NUMBER(10,2);
    v_current_month_spent NUMBER(10,2);
    v_days_passed NUMBER;
    v_days_remaining NUMBER;

    CURSOR daily_cursor IS
        SELECT
            TRUNC(expense_date) AS expense_day,
            SUM(amount) AS daily_total,
            COUNT(*) AS transaction_count
        FROM expense
        WHERE user_id = p_user_id
        AND expense_date >= TRUNC(SYSDATE, 'MM')
        GROUP BY TRUNC(expense_date)
        ORDER BY TRUNC(expense_date);
BEGIN
    -- Calculate statistics
    SELECT AVG(daily_total) INTO v_avg_daily_spending FROM (
        SELECT SUM(amount) AS daily_total
        FROM expense
        WHERE user_id = p_user_id
        GROUP BY TRUNC(expense_date)
    );

    SELECT SUM(amount) INTO v_current_month_spent FROM expense
    WHERE user_id = p_user_id
    AND expense_date >= TRUNC(SYSDATE, 'MM')
    AND expense_date < TRUNC(SYSDATE, 'MM') + 31;

    v_days_passed := TRUNC(SYSDATE) - TRUNC(SYSDATE, 'MM');
    v_days_remaining := 31 - v_days_passed;
    v_projected_monthly := v_current_month_spent + (v_avg_daily_spending * v_days_remaining);

    DBMS_OUTPUT.PUT_LINE('===== EXPENSE TREND & FORECAST REPORT =====');
    DBMS_OUTPUT.PUT_LINE('User ID: ' || p_user_id);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Average Daily Spending: ' || TO_CHAR(v_avg_daily_spending, '9999.99'));
    DBMS_OUTPUT.PUT_LINE('Current Month Spent: ' || TO_CHAR(v_current_month_spent, '99999.99'));
    DBMS_OUTPUT.PUT_LINE('Days Passed: ' || v_days_passed);
    DBMS_OUTPUT.PUT_LINE('Days Remaining: ' || v_days_remaining);
    DBMS_OUTPUT.PUT_LINE('Projected Monthly Total: ' || TO_CHAR(v_projected_monthly, '99999.99'));
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('DAILY BREAKDOWN:');

    FOR rec IN daily_cursor LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Date: ' || rec.expense_day ||
            ' | Daily Total: ' || TO_CHAR(rec.daily_total, '99999.99') ||
            ' | Transactions: ' || rec.transaction_count
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END report_expense_trends;
/




-- Test Report 1
EXEC report_monthly_expenditure(1, '2025-11');

-- Test Report 2
EXEC report_budget_adherence(1);

-- Test Report 3
EXEC report_savings_progress(1);

-- Test Report 4
EXEC report_expense_distribution(1);

-- Test Report 5
EXEC report_expense_trends(1);
