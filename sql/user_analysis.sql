-- 电商用户行为分析 SQL 脚本
-- 适用场景：从数据库提取核心指标、用户分层

-- 1. 计算转化漏斗（用户维度）
WITH funnel AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN behavior_type = 1 THEN user_id END) AS view_users,
        COUNT(DISTINCT CASE WHEN behavior_type = 2 THEN user_id END) AS cart_users,
        COUNT(DISTINCT CASE WHEN behavior_type = 3 THEN user_id END) AS order_users,
        COUNT(DISTINCT CASE WHEN behavior_type = 4 THEN user_id END) AS pay_users
    FROM user_behavior
    WHERE time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
)
SELECT 
    view_users,
    cart_users,
    order_users,
    pay_users,
    ROUND(cart_users / view_users * 100, 2) AS cart_conversion,
    ROUND(order_users / cart_users * 100, 2) AS order_conversion,
    ROUND(pay_users / order_users * 100, 2) AS pay_conversion
FROM funnel;

-- 2. RFM 用户分层（精准识别高价值用户）
SELECT 
    user_id,
    -- R：最近消费天数
    DATEDIFF(NOW(), MAX(time)) AS recency_days,
    -- F：消费频次（下单次数）
    COUNT(*) AS frequency,
    -- M：消费金额
    SUM(price) AS monetary,
    -- 用户分层
    CASE 
        WHEN DATEDIFF(NOW(), MAX(time)) <= 7 AND COUNT(*) >= 3 AND SUM(price) >= 500 THEN '高价值用户'
        WHEN DATEDIFF(NOW(), MAX(time)) <= 30 AND COUNT(*) >= 1 THEN '中价值用户'
        ELSE '低价值用户'
    END AS user_segment
FROM user_behavior
WHERE behavior_type = 3 -- 仅统计下单用户
GROUP BY user_id
ORDER BY monetary DESC;

-- 3. 按小时统计用户活跃与转化
SELECT 
    HOUR(time) AS hour,
    COUNT(DISTINCT user_id) AS active_users,
    COUNT(CASE WHEN behavior_type = 3 THEN 1 END) AS order_count,
    ROUND(COUNT(CASE WHEN behavior_type = 3 THEN 1 END) / COUNT(DISTINCT user_id) * 100, 2) AS order_rate
FROM user_behavior
GROUP BY hour
ORDER BY active_users DESC;
