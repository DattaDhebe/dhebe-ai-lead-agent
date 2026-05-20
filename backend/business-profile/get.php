<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

Request::requireMethod('GET');

$pdo = Database::connect();
$user = AuthMiddleware::requireUser($pdo);

$stmt = $pdo->prepare(
    'SELECT business_name, owner_name, business_phone, business_email, website, address,
            services_text, faq_text, tone_notes, policy_notes, created_at, updated_at
     FROM business_profiles
     WHERE user_id = :user_id
     LIMIT 1'
);
$stmt->execute(['user_id' => (int) $user['id']]);
$profile = $stmt->fetch();

if ($profile === false) {
    $profile = [
        'business_name' => $user['business_name'] ?? '',
        'owner_name' => $user['name'] ?? '',
        'business_phone' => $user['phone'] ?? '',
        'business_email' => $user['email'] ?? '',
        'website' => '',
        'address' => '',
        'services_text' => '',
        'faq_text' => '',
        'tone_notes' => '',
        'policy_notes' => '',
        'created_at' => null,
        'updated_at' => null,
    ];
}

Response::success('Business profile fetched successfully.', [
    'profile' => $profile,
]);
