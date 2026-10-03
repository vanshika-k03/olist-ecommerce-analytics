--1. Monthly GMV, Orders and AOV
SELECT
	DATE_TRUNC('month',o.order_purchase_timestamp) AS month,
	ROUND(SUM(oi.price)::numeric,2) AS GMV,
	COUNT(DISTINCT o.order_id) AS orders,
	ROUND(SUM(oi.price):: numeric/NULLIF(COUNT (DISTINCT o.order_id),0),2) AS AOV
FROM orders AS o
JOIN order_items AS oi
ON o.order_id=oi.order_id
GROUP by 1
ORDER by 1


--MoM GMV, Orders and AOV Growth
WITH monthly_stats AS (
	SELECT
		DATE_TRUNC('month',o.order_purchase_timestamp) AS month,
		ROUND(SUM(oi.price)::numeric,2) AS GMV,
		COUNT(DISTINCT o.order_id) AS orders,
		ROUND(SUM(oi.price):: numeric/NULLIF(COUNT (DISTINCT o.order_id),0),2) AS AOV
	FROM orders AS o
	JOIN order_items AS oi
	ON o.order_id=oi.order_id
	GROUP by 1
    )
SELECT 
month,
ROUND(100.0* (GMV-LAG(GMV)OVER (order by month ))/NULLIF(LAG(GMV)OVER (order by month ),0),2)AS GMV_MOM,
ROUND(100.0* (orders-LAG(orders)OVER (order by month ))/NULLIF(LAG(orders)OVER (order by month ),0),2) AS orders_MOM,
ROUND(100.0* (AOV- LAG(AOV)OVER(order by month))/NULLIF(LAG(AOV)OVER (order by month),0),2)AS AOV_MOM	
FROM monthly_stats
ORDER BY month

--3. Category GMV, Orders and AOV
SELECT
    COALESCE(ct.product_category_name_english, 'Unknown') AS category,
    SUM(oi.price) AS gmv,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(
        SUM(oi.price):: numeric / NULLIF(COUNT(DISTINCT oi.order_id), 0),
        2
    ) AS aov,
    ROUND(
        100.0 * SUM(oi.price)::numeric
        / SUM(SUM(oi.price)) OVER ()::numeric, 2
    ) AS gmv_contribution_pct
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY 1
ORDER BY gmv DESC;

--4. One-Time vs Repeat Customers
CREATE OR REPLACE VIEW vw_customer_type_performance AS
WITH customer_orders AS (
SELECT
c.customer_unique_id,
SUM(oi.price) AS gmv,
COUNT(DISTINCT o.order_id) AS order_count
FROM orders o
JOIN order_items oi
ON o.order_id=oi.order_id
LEFT JOIN customers c
ON c.customer_id=o.customer_id
GROUP BY 1
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_type,
    COUNT(*) AS customers,
        1.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS customer_pct,
    ROUND(SUM(gmv)::numeric,2) AS gmv,
    ROUND(AVG(gmv)::numeric, 2) AS avg_customer_gmv,
    ROUND(AVG(order_count)::numeric, 2) AS avg_orders_per_customer,
    ROUND(
        AVG(gmv/ NULLIF(order_count, 0))::numeric, 2
    ) AS avg_customer_aov,
    1.0 * SUM(gmv) / SUM(SUM(gmv)) OVER () AS gmv_contribution_pct
FROM customer_orders
GROUP BY 1
ORDER BY 1;


--5.REPEAT PURCHASE RATE
WITH customer_orders AS(
select 
c.customer_unique_id ,
COUNT(o.order_id) AS order_count
FROM orders o
LEFT JOIN customers c
ON o.customer_id=c.customer_id
GROUP BY c.customer_unique_id
)
SELECT 
COUNT(*) AS total_customers,
COUNT (*) FILTER (WHERE order_count>1) AS repeat_customers,
ROUND(100.0* COUNT (*) FILTER (WHERE order_count>1)/NULLIF(COUNT(*),0),2) AS repeat_customer_rate
FROM customer_orders


--6. Category Mix Among Repeat Customer
WITH repeat_customers AS(
SELECT
	c.customer_unique_id,
	COUNT(o.order_id) AS order_count
	FROM orders o
JOIN customers c
ON c.customer_id=o.customer_id
GROUP BY c.customer_unique_id
HAVING (COUNT(o.order_id)) >1 
)
SELECT 
COALESCE(ct.product_category_name_english,'unknown'),
COUNT(DISTINCT o.order_id)AS total_orders,
COUNT(DISTINCT c.customer_unique_id) AS repeat_customers,
ROUND(SUM(oi.price)::numeric,2) AS gmv
FROM repeat_customers rc
JOIN customers c
on c.customer_unique_id = rc.customer_unique_id
JOIN orders o
on o.customer_id=c.customer_id
JOIN order_items oi
ON oi.order_id=o.order_id
JOIN products p
on oi.product_id = p.product_id
JOIN category_translation ct
on ct.product_category_name=p.product_category_name
GROUP BY 1
ORDER BY gmv DESC


--7. RFM Base Table
CREATE OR REPLACE VIEW vw_customer_rfm_base AS

SELECT
    c.customer_unique_id,

    (
        (SELECT MAX(order_purchase_timestamp::date)
         FROM orders)
        + 1
        - MAX(o.order_purchase_timestamp::date)
    ) AS recency,

    COUNT(DISTINCT o.order_id) AS frequency,

    SUM(oi.price) AS monetary

FROM customers c

JOIN orders o
    ON c.customer_id = o.customer_id

JOIN order_items oi
    ON o.order_id = oi.order_id

GROUP BY c.customer_unique_id;


--8. RFM Scores 
CREATE OR REPLACE VIEW vw_customer_rfm_scores AS

SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,

    -- R score
    NTILE(5) OVER (
        ORDER BY recency DESC
    ) AS r_score,

    -- F score
    CASE
        WHEN frequency = 2 THEN 1
        WHEN frequency = 3 THEN 2
        WHEN frequency = 4 THEN 3
        WHEN frequency = 5 THEN 4
        WHEN frequency >= 6 THEN 5
    END AS f_score,

    -- M score
    NTILE(5) OVER (
        ORDER BY monetary
    ) AS m_score

FROM vw_customer_rfm_base

WHERE frequency >= 2;

--RFM segments 

DROP VIEW IF EXISTS vw_customer_rfm_segments;

CREATE VIEW vw_customer_rfm_segments AS

SELECT
    *,
    
    CASE

        -- Highest-value, recent, frequent customers
        WHEN r_score >= 4
         AND f_score >= 4
         AND m_score >= 4
            THEN 'Champions'

        -- Strong repeat customers
        WHEN r_score >= 3
         AND f_score >= 2
         AND m_score >= 3
            THEN 'Loyal Customers'

        -- Recent customers with reasonable monetary value
        WHEN r_score >= 4
         AND m_score >= 2
            THEN 'Potential Loyalists'

        -- Older but valuable repeat customers
        WHEN r_score <= 2
         AND f_score >= 2
         AND m_score >= 3
            THEN 'At Risk'

        -- Older, lower-frequency customers
        WHEN r_score <= 2
         AND f_score = 1
            THEN 'Hibernating'

        -- Remaining repeat customers
        ELSE 'Occasional Repeaters'

    END AS rfm_segment

FROM vw_customer_rfm_scores;



SELECT
    rfm_segment,
    COUNT(*) AS customers,
    ROUND(AVG(recency)::numeric, 1) AS avg_recency,
    ROUND(AVG(frequency)::numeric, 2) AS avg_frequency,
    ROUND(AVG(monetary)::numeric, 2) AS avg_monetary,
    ROUND(SUM(monetary)::numeric, 2) AS total_gmv
FROM vw_customer_rfm_segments
GROUP BY rfm_segment
ORDER BY total_gmv DESC;



--9. RFM Segment Size and GMV Contribution
SELECT
    rfm_segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary)::numeric,2)
	AS gmv,
    ROUND(
        100.0 * SUM(monetary)::numeric
        / SUM(SUM(monetary)) OVER ()::numeric, 2
    ) AS gmv_contribution_pct,
    ROUND(AVG(monetary)::numeric, 2) AS avg_customer_gmv,
    ROUND(AVG(frequency)::numeric, 2) AS avg_frequency,
    ROUND(AVG(recency)::numeric, 1) AS avg_recency_days
FROM vw_customer_rfm_segments
GROUP BY rfm_segment
ORDER BY gmv DESC;

WITH customer_metrics AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS frequency
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)

SELECT
    frequency,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_pct
FROM customer_metrics
GROUP BY frequency
ORDER BY frequency;

--10. High-Value Inactive Customers
SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    rfm_segment
FROM vw_customer_rfm_segments
WHERE monetary >= (
    SELECT PERCENTILE_CONT(0.75)
           WITHIN GROUP (ORDER BY monetary)
    FROM vw_customer_rfm_segments
)
AND recency >= (
    SELECT PERCENTILE_CONT(0.75)
           WITHIN GROUP (ORDER BY recency)
    FROM vw_customer_rfm_segments
)
ORDER BY monetary DESC;

--11. Customer GMV Concentration
CREATE OR REPLACE VIEW vw_customer_revenue_concentration AS

WITH customer_gmv AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS gmv
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),

ranked AS (
    SELECT
        *,
        NTILE(10) OVER (ORDER BY gmv DESC) AS decile
    FROM customer_gmv
),

decile_summary AS (
    SELECT
        decile,
        COUNT(*) AS customers,
        ROUND(SUM(gmv)::numeric, 2) AS gmv,
        ROUND(
            SUM(gmv)::numeric/ SUM(SUM(gmv)) OVER ()::numeric,
            4
        ) AS percent_contribution
    FROM ranked
    GROUP BY decile
)

SELECT
    decile,
    customers,
    gmv,
    percent_contribution,

    ROUND(
        SUM(percent_contribution) OVER (
            ORDER BY decile
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )::numeric,
        4
    ) AS cumulative_contribution_pct

FROM decile_summary
ORDER BY decile;


--12. Seller Performance
WITH seller_performance AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id) AS orders,
        SUM(oi.price) AS gmv,
        SUM(oi.price)::numeric
            / NULLIF(COUNT(DISTINCT oi.order_id), 0) AS aov
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    GROUP BY oi.seller_id
)

SELECT
    seller_id,
    orders,
    ROUND(gmv::numeric, 2) AS gmv,
    ROUND(aov ::numeric, 2) AS aov,
    ROUND(
        100.0 * gmv::numeric
        / SUM(gmv) OVER ()::numeric,
        2
    ) AS gmv_contribution_pct,
    RANK() OVER (ORDER BY gmv DESC) AS gmv_rank
FROM seller_performance
WHERE orders >= 20
ORDER BY gmv DESC;

--13. Seller Delivery Performance
SELECT
    oi.seller_id,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_delivered_customer_date >
              o.order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date >
                  o.order_estimated_delivery_date
        )
        / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS late_rate
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT o.order_id) >= 20
ORDER BY late_rate DESC;

--14. High-GMV + High-Late Sellers
WITH seller_metrics AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT o.order_id) AS orders,
        ROUND(SUM(oi.price)::numeric,2) AS gmv,
        ROUND(
            100.0 * COUNT(DISTINCT o.order_id) FILTER (
                WHERE o.order_delivered_customer_date >
                      o.order_estimated_delivery_date
            )
            / NULLIF(
                COUNT(DISTINCT o.order_id) FILTER (
                    WHERE o.order_delivered_customer_date IS NOT NULL
                ), 0
            ), 2
        ) AS late_rate
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    GROUP BY oi.seller_id
)
SELECT *
FROM seller_metrics
WHERE orders >= 20
ORDER BY gmv DESC;

--15. Delivery Status
SELECT
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'On Time'
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
        ELSE 'Not Delivered'
    END AS delivery_status,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2
    ) AS pct_of_orders
FROM orders
GROUP BY 1
ORDER BY orders DESC;

--16.Late Delivery vs Review Score
SELECT
    CASE
        WHEN o.order_delivered_customer_date <=
             o.order_estimated_delivery_date
            THEN 'On Time'
        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date
            THEN 'Late'
    END AS delivery_status,
    COUNT(DISTINCT r.order_id) AS reviewed_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
JOIN reviews r
    ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY 1;

--17. Category: GMV + Late Rate + Review Score

WITH order_reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
)

SELECT
    COALESCE(ct.product_category_name_english, 'Unknown') AS category,
    SUM(oi.price) AS gmv,
    COUNT(DISTINCT o.order_id) AS delivered_orders,

    ROUND(
        100.0 * COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date >
                  o.order_estimated_delivery_date
        )
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS late_rate,

    ROUND(AVG(orv.avg_review_score), 2) AS avg_review_score

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name

LEFT JOIN order_reviews orv
    ON o.order_id = orv.order_id

WHERE o.order_delivered_customer_date IS NOT NULL

GROUP BY 1
ORDER BY gmv DESC;

--18. Category Freight Burden
SELECT
    COALESCE(ct.product_category_name_english, 'Unknown') AS category,
    ROUND(SUM(oi.price)::numeric,2)AS product_value,
    ROUND(SUM(oi.freight_value)::numeric,2) AS freight_value,
    ROUND(
        100.0 * SUM(oi.freight_value)::numeric
        / NULLIF(SUM(oi.price)::numeric, 0), 2
    ) AS freight_to_price_pct
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY 1
ORDER BY freight_to_price_pct DESC;

--19. Category GMV + Volume Diagnosis
WITH category_metrics AS (
    SELECT
        COALESCE(ct.product_category_name_english, 'Unknown') AS category,
        SUM(oi.price)::numeric AS gmv,
        COUNT(DISTINCT oi.order_id) AS orders
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    GROUP BY 1
)
SELECT
    category,
    gmv,
    orders,
    ROUND(gmv::numeric / NULLIF(orders, 0), 2) AS category_aov,
    ROUND(
        100.0 * gmv::numeric / SUM(gmv) OVER ()::numeric, 2
    ) AS gmv_contribution_pct
FROM category_metrics
ORDER BY gmv DESC;


---views----
--monthly sales view
CREATE OR REPLACE VIEW vw_monthly_sales AS
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
    ROUND(SUM(oi.price)::numeric, 2) AS gmv,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT c.customer_unique_id) AS customers,
    ROUND(
        SUM(oi.price)::numeric
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS aov
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN customers c
    ON c.customer_id = o.customer_id
GROUP BY 1
ORDER BY 1;

--category performance view
CREATE OR REPLACE VIEW vw_category_performance AS
WITH category_metrics AS (
    SELECT
        COALESCE(
            ct.product_category_name_english,
            'Unknown'
        ) AS category,
        SUM(oi.price)::numeric AS gmv,
        COUNT(DISTINCT oi.order_id) AS orders
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    GROUP BY 1
)
SELECT
    category,
    ROUND(gmv, 2) AS gmv,
    orders,
    ROUND(
        gmv / NULLIF(orders, 0),
        2
    ) AS category_aov,
    ROUND(
        100.0 * gmv
        / NULLIF(SUM(gmv) OVER (), 0),
        2
    ) AS gmv_contribution_pct
FROM category_metrics
ORDER BY gmv DESC;

--customer summary view 
CREATE OR REPLACE VIEW vw_customer_summary AS
WITH customer_metrics AS (
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp)::date AS first_purchase_date,
        MAX(o.order_purchase_timestamp)::date AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS order_count,
        ROUND(SUM(oi.price)::numeric, 2) AS gmv
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    first_purchase_date,
    last_purchase_date,
    order_count,
    gmv,
    ROUND(
        gmv / NULLIF(order_count, 0),
        2
    ) AS customer_aov,
    CASE
        WHEN order_count = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_type
FROM customer_metrics;

--seller  performance view 
CREATE OR REPLACE VIEW vw_seller_performance AS
SELECT
    oi.seller_id,

    COUNT(DISTINCT o.order_id) AS orders,

    ROUND(
        SUM(oi.price)::numeric,
        2
    ) AS gmv,

    ROUND(
        SUM(oi.price)::numeric
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS aov,

    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_delivered_customer_date IS NOT NULL
    ) AS delivered_orders,

    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_delivered_customer_date >
              o.order_estimated_delivery_date
    ) AS late_orders,

    ROUND(
        100.0 *
        COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date >
                  o.order_estimated_delivery_date
        )
        /
        NULLIF(
            COUNT(DISTINCT o.order_id) FILTER (
                WHERE o.order_delivered_customer_date IS NOT NULL
            ),
            0
        ),
        2
    ) AS late_rate

FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
GROUP BY oi.seller_id;

--delivery analysis view 
CREATE OR REPLACE VIEW vw_delivery_analysis AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp::date AS purchase_date,
    o.order_delivered_customer_date::date AS delivered_date,
    o.order_estimated_delivery_date::date AS estimated_delivery_date,

    CASE
        WHEN o.order_delivered_customer_date IS NULL
            THEN 'Not Delivered'

        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
            THEN 'On Time'

        ELSE 'Late'
    END AS delivery_status,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN ROUND(
            (
                EXTRACT(
                    EPOCH FROM (
                        o.order_delivered_customer_date
                        - o.order_purchase_timestamp
                    )
                ) / 86400
            )::numeric,
            2
        )
    END AS delivery_days,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN (
            o.order_delivered_customer_date::date
            - o.order_estimated_delivery_date
        )
    END AS delay_days

FROM orders o;

--state view 
CREATE OR REPLACE VIEW vw_customer_state_performance AS
SELECT
    c.customer_state,

    COUNT(DISTINCT c.customer_unique_id) AS customers,

    COUNT(DISTINCT o.order_id) AS orders,

    ROUND(
        SUM(oi.price)::numeric,
        2
    ) AS gmv,

    ROUND(
        SUM(oi.price)::nMumeric
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS aov

FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_state;


SELECT 
SUM(price)
from order_items