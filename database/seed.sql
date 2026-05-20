-- Replace owner@dhebe.com with an email that exists in the users table.
-- The safest flow is:
-- 1. Register your account from the app or API.
-- 2. Update the email below if needed.
-- 3. Run this file to add sample business profile and lead data.

INSERT INTO business_profiles (
    user_id,
    business_name,
    owner_name,
    business_phone,
    business_email,
    website,
    address,
    services_text,
    faq_text,
    tone_notes,
    policy_notes
)
SELECT
    u.id,
    'Dhebe Services',
    u.name,
    u.phone,
    u.email,
    'https://dhebe.com',
    'Kolkata, India',
    'Website setup, lead follow-up support, basic business automation',
    'We reply during working hours. Pricing depends on project scope.',
    'Warm, professional, practical',
    'Do not promise discounts or same-day delivery unless confirmed.'
FROM users u
WHERE u.email = 'owner@dhebe.com'
  AND NOT EXISTS (
      SELECT 1
      FROM business_profiles bp
      WHERE bp.user_id = u.id
  )
LIMIT 1;

INSERT INTO leads (
    user_id,
    name,
    phone,
    email,
    source,
    service_interested,
    customer_message,
    status,
    next_follow_up_at,
    notes
)
SELECT
    u.id,
    'Rohit Sharma',
    '+919876543210',
    'rohit@example.com',
    'WhatsApp',
    'Website redesign',
    'Hi, I want to know the cost and timeline for redesigning my business website.',
    'new',
    DATE_ADD(NOW(), INTERVAL 1 DAY),
    'Interested in a quick estimate and delivery timeline.'
FROM users u
WHERE u.email = 'owner@dhebe.com'
LIMIT 1;

INSERT INTO reminders (
    user_id,
    lead_id,
    title,
    reminder_at,
    notes
)
SELECT
    l.user_id,
    l.id,
    CONCAT('Follow up with ', l.name),
    DATE_ADD(NOW(), INTERVAL 1 DAY),
    'Sample reminder from seed data.'
FROM leads l
INNER JOIN users u ON u.id = l.user_id
WHERE u.email = 'owner@dhebe.com'
ORDER BY l.id DESC
LIMIT 1;
