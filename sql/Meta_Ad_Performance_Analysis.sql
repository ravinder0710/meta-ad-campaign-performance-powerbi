-- =============================================================================
-- PROJECT      : META AD PERFORMANCE DASHBOARD (FACEBOOK & INSTAGRAM)
-- PROJECT TYPE : Digital Marketing Analytics & Performance BI
-- DATABASE     : PostgreSQL / MySQL Compatible
-- AUTHOR       : Ravinder Gupta
-- DESCRIPTION  : Comprehensive SQL Analytics validating 400,000+ ad event logs,
--                cross-platform (Facebook vs. Instagram) ROI, creative format efficiency,
--                funnel conversion rates, demographic cohorts, and hourly engagement.
-- =============================================================================

-- =============================================================================
-- SECTION 1 : SCHEMA DDL & DATA INTEGRITY
-- =============================================================================

DROP TABLE IF EXISTS ad_events;
DROP TABLE IF EXISTS ads;
DROP TABLE IF EXISTS campaigns;
DROP TABLE IF EXISTS users;

CREATE TABLE campaigns (
    campaign_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    start_date DATE,
    end_date DATE,
    duration_days INT,
    total_budget NUMERIC(14,2)
);

CREATE TABLE ads (
    ad_id INT PRIMARY KEY,
    campaign_id INT REFERENCES campaigns(campaign_id),
    ad_platform VARCHAR(50) NOT NULL,   -- 'Facebook', 'Instagram'
    ad_type VARCHAR(50) NOT NULL,       -- 'Video', 'Stories', 'Image', 'Carousel'
    target_gender VARCHAR(20),          -- 'Female', 'Male', 'All'
    target_age_group VARCHAR(50),
    target_interests VARCHAR(255)
);

CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    user_gender VARCHAR(20),
    user_age INT,
    age_group VARCHAR(50),
    country VARCHAR(100),
    location VARCHAR(100),
    interests VARCHAR(255)
);

CREATE TABLE ad_events (
    event_id INT PRIMARY KEY,
    ad_id INT REFERENCES ads(ad_id),
    user_id VARCHAR(50) REFERENCES users(user_id),
    timestamp TIMESTAMP,
    day_of_week VARCHAR(20),
    time_of_day VARCHAR(20),
    event_type VARCHAR(50)              -- 'Impression', 'Click', 'Share', 'Comment', 'Purchase', 'Like'
);

-- =============================================================================
-- SECTION 2 : CORE FUNNEL KPIS & PERFORMANCE METRICS
-- =============================================================================

-- Q1. Global Executive KPIs (Impressions, Clicks, Shares, Comments, Purchases, Engagements)
SELECT
    COUNT(*) AS total_event_records,
    COUNT(CASE WHEN event_type = 'Impression' THEN 1 END) AS total_impressions,
    COUNT(CASE WHEN event_type = 'Click' THEN 1 END) AS total_clicks,
    COUNT(CASE WHEN event_type = 'Share' THEN 1 END) AS total_shares,
    COUNT(CASE WHEN event_type = 'Comment' THEN 1 END) AS total_comments,
    COUNT(CASE WHEN event_type = 'Purchase' THEN 1 END) AS total_purchases,
    -- Engagements = Clicks + Shares + Comments
    COUNT(CASE WHEN event_type IN ('Click', 'Share', 'Comment') THEN 1 END) AS total_engagements,
    -- Click-Through Rate (CTR) = Clicks / Impressions * 100
    ROUND(
        COUNT(CASE WHEN event_type = 'Click' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS click_through_rate_pct,
    -- Engagement Rate (ER) = Engagements / Impressions * 100
    ROUND(
        COUNT(CASE WHEN event_type IN ('Click', 'Share', 'Comment') THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS engagement_rate_pct,
    -- Conversion Rate (CR) = Purchases / Clicks * 100
    ROUND(
        COUNT(CASE WHEN event_type = 'Purchase' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN event_type = 'Click' THEN 1 END), 0) * 100, 2
    ) AS conversion_rate_pct,
    -- Purchase Rate (PR) = Purchases / Impressions * 100
    ROUND(
        COUNT(CASE WHEN event_type = 'Purchase' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS purchase_rate_pct
FROM ad_events;

-- =============================================================================
-- SECTION 3 : CROSS-PLATFORM COMPARISON (FACEBOOK VS. INSTAGRAM)
-- =============================================================================

-- Q2. Cross-Platform Performance Breakdown & Funnel Velocity
SELECT
    a.ad_platform,
    COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END) AS impressions,
    COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END) AS clicks,
    COUNT(CASE WHEN e.event_type = 'Share' THEN 1 END) AS shares,
    COUNT(CASE WHEN e.event_type = 'Comment' THEN 1 END) AS comments,
    COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END) AS purchases,
    COUNT(CASE WHEN e.event_type IN ('Click', 'Share', 'Comment') THEN 1 END) AS engagements,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS ctr_pct,
    ROUND(
        COUNT(CASE WHEN e.event_type IN ('Click', 'Share', 'Comment') THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS engagement_rate_pct,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END), 0) * 100, 2
    ) AS conversion_rate_pct,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS purchase_rate_pct
FROM ad_events e
JOIN ads a ON a.ad_id = e.ad_id
GROUP BY a.ad_platform
ORDER BY impressions DESC;

-- =============================================================================
-- SECTION 4 : CREATIVE FORMAT ANALYSIS (AD TYPE EFFICIENCY)
-- =============================================================================

-- Q3. Ad Type Performance Matrix (Carousel vs. Stories vs. Image vs. Video)
SELECT
    a.ad_type,
    COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END) AS impressions,
    COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END) AS clicks,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS ctr_pct,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS purchase_rate_pct,
    ROUND(
        COUNT(CASE WHEN e.event_type IN ('Click', 'Share', 'Comment') THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS engagement_rate_pct,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END), 0) * 100, 2
    ) AS conversion_rate_pct
FROM ad_events e
JOIN ads a ON a.ad_id = e.ad_id
GROUP BY a.ad_type
ORDER BY impressions DESC;

-- =============================================================================
-- SECTION 5 : DEMOGRAPHIC TARGETING & AUDIENCE SEGMENTATION
-- =============================================================================

-- Q4. Performance by Target Gender
SELECT
    COALESCE(u.user_gender, 'Unknown') AS gender,
    COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END) AS impressions,
    COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END) AS clicks,
    COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END) AS purchases,
    COUNT(CASE WHEN e.event_type IN ('Click', 'Share', 'Comment') THEN 1 END) AS engagements,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS ctr_pct,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END), 0) * 100, 2
    ) AS conversion_rate_pct
FROM ad_events e
LEFT JOIN users u ON u.user_id = e.user_id
GROUP BY u.user_gender
ORDER BY impressions DESC;

-- Q5. Age Group Distribution & Responsiveness
SELECT
    u.age_group,
    COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END) AS impressions,
    COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END) AS clicks,
    COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END) AS purchases,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS ctr_pct,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END), 0) * 100, 2
    ) AS conversion_rate_pct
FROM ad_events e
LEFT JOIN users u ON u.user_id = e.user_id
WHERE u.age_group IS NOT NULL
GROUP BY u.age_group
ORDER BY impressions DESC;

-- =============================================================================
-- SECTION 6 : GEOGRAPHIC MARKET ANALYSIS
-- =============================================================================

-- Q6. Top 10 Countries by Reach and Conversions
SELECT
    COALESCE(u.country, 'Unknown') AS country,
    COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END) AS impressions,
    COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END) AS clicks,
    COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END) AS purchases,
    COUNT(CASE WHEN e.event_type IN ('Click', 'Share', 'Comment') THEN 1 END) AS engagements,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS ctr_pct,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END), 0) * 100, 2
    ) AS conversion_rate_pct
FROM ad_events e
LEFT JOIN users u ON u.user_id = e.user_id
GROUP BY u.country
ORDER BY impressions DESC
LIMIT 10;

-- =============================================================================
-- SECTION 7 : TEMPORAL & HOURLY BEHAVIORAL ENGAGEMENT
-- =============================================================================

-- Q7. Hourly Engagement Patterns (Peak Active Hours)
SELECT
    EXTRACT(HOUR FROM e.timestamp) AS hour_of_day,
    COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END) AS impressions,
    COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END) AS clicks,
    COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END) AS purchases,
    COUNT(CASE WHEN e.event_type IN ('Click', 'Share', 'Comment') THEN 1 END) AS engagements
FROM ad_events e
GROUP BY EXTRACT(HOUR FROM e.timestamp)
ORDER BY hour_of_day;

-- Q8. Day of Week Engagement Breakdown
SELECT
    e.day_of_week,
    COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END) AS impressions,
    COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END) AS clicks,
    COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END) AS purchases,
    ROUND(
        COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END), 0) * 100, 2
    ) AS ctr_pct
FROM ad_events e
GROUP BY e.day_of_week
ORDER BY impressions DESC;

-- =============================================================================
-- SECTION 8 : CAMPAIGN BUDGET & ROI EFFICIENCY
-- =============================================================================

-- Q9. Campaign Level Spend & Unit Economics (Cost per Click & Cost per Purchase)
WITH campaign_events AS (
    SELECT
        a.campaign_id,
        COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END) AS impressions,
        COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END) AS clicks,
        COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END) AS purchases
    FROM ad_events e
    JOIN ads a ON a.ad_id = e.ad_id
    GROUP BY a.campaign_id
)
SELECT
    c.campaign_id,
    c.name AS campaign_name,
    c.total_budget,
    c.duration_days,
    COALESCE(ce.impressions, 0) AS impressions,
    COALESCE(ce.clicks, 0) AS clicks,
    COALESCE(ce.purchases, 0) AS purchases,
    -- Cost Per Thousand Impressions (CPM)
    ROUND(
        c.total_budget / NULLIF(ce.impressions / 1000.0, 0), 2
    ) AS cpm,
    -- Cost Per Click (CPC)
    ROUND(
        c.total_budget / NULLIF(ce.clicks, 0), 2
    ) AS cpc,
    -- Cost Per Acquisition / Purchase (CPA)
    ROUND(
        c.total_budget / NULLIF(ce.purchases, 0), 2
    ) AS cpa
FROM campaigns c
LEFT JOIN campaign_events ce ON ce.campaign_id = c.campaign_id
ORDER BY c.total_budget DESC
LIMIT 10;

-- Q10. Week-over-Week Performance Velocity via Window Functions
WITH weekly_performance AS (
    SELECT
        DATE_TRUNC('week', e.timestamp)::DATE AS week_start,
        COUNT(CASE WHEN e.event_type = 'Impression' THEN 1 END) AS weekly_impressions,
        COUNT(CASE WHEN e.event_type = 'Click' THEN 1 END) AS weekly_clicks,
        COUNT(CASE WHEN e.event_type = 'Purchase' THEN 1 END) AS weekly_purchases
    FROM ad_events e
    GROUP BY DATE_TRUNC('week', e.timestamp)::DATE
), weekly_lagged AS (
    SELECT
        week_start,
        weekly_impressions,
        weekly_clicks,
        weekly_purchases,
        LAG(weekly_impressions) OVER (ORDER BY week_start) AS prev_week_impressions,
        LAG(weekly_clicks) OVER (ORDER BY week_start) AS prev_week_clicks,
        LAG(weekly_purchases) OVER (ORDER BY week_start) AS prev_week_purchases
    FROM weekly_performance
)
SELECT
    week_start,
    weekly_impressions,
    prev_week_impressions,
    ROUND(
        ((weekly_impressions - prev_week_impressions)::NUMERIC /
         NULLIF(prev_week_impressions, 0)) * 100, 2
    ) AS impressions_wow_growth_pct,
    weekly_clicks,
    weekly_purchases
FROM weekly_lagged
ORDER BY week_start;
