<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

Request::requireMethod('POST');

$pdo = Database::connect();
$user = AuthMiddleware::requireUser($pdo);
$data = Request::json();

if ($emailError = Validator::email(isset($data['business_email']) ? (string) $data['business_email'] : null, 'business_email')) {
    Response::error('Validation failed.', 422, ['business_email' => $emailError]);
}

$payload = [
    'business_name' => trim((string) ($data['business_name'] ?? '')),
    'owner_name' => trim((string) ($data['owner_name'] ?? '')),
    'business_phone' => trim((string) ($data['business_phone'] ?? '')),
    'business_email' => trim((string) ($data['business_email'] ?? '')),
    'website' => trim((string) ($data['website'] ?? '')),
    'address' => trim((string) ($data['address'] ?? '')),
    'services_text' => trim((string) ($data['services_text'] ?? '')),
    'faq_text' => trim((string) ($data['faq_text'] ?? '')),
    'tone_notes' => trim((string) ($data['tone_notes'] ?? '')),
    'policy_notes' => trim((string) ($data['policy_notes'] ?? '')),
];

$checkStmt = $pdo->prepare(
    'SELECT id
     FROM business_profiles
     WHERE user_id = :user_id
     LIMIT 1'
);
$checkStmt->execute(['user_id' => (int) $user['id']]);
$existing = $checkStmt->fetch();

if ($existing === false) {
    $stmt = $pdo->prepare(
        'INSERT INTO business_profiles
            (user_id, business_name, owner_name, business_phone, business_email, website, address, services_text, faq_text, tone_notes, policy_notes)
         VALUES
            (:user_id, :business_name, :owner_name, :business_phone, :business_email, :website, :address, :services_text, :faq_text, :tone_notes, :policy_notes)'
    );
    $stmt->execute(array_merge($payload, [
        'user_id' => (int) $user['id'],
    ]));
} else {
    $stmt = $pdo->prepare(
        'UPDATE business_profiles
         SET business_name = :business_name,
             owner_name = :owner_name,
             business_phone = :business_phone,
             business_email = :business_email,
             website = :website,
             address = :address,
             services_text = :services_text,
             faq_text = :faq_text,
             tone_notes = :tone_notes,
             policy_notes = :policy_notes
         WHERE user_id = :user_id'
    );
    $stmt->execute(array_merge($payload, [
        'user_id' => (int) $user['id'],
    ]));
}

$userStmt = $pdo->prepare(
    'UPDATE users
     SET business_name = :business_name
     WHERE id = :id'
);
$userStmt->execute([
    'business_name' => $payload['business_name'] !== '' ? $payload['business_name'] : null,
    'id' => (int) $user['id'],
]);

Response::success('Business profile saved successfully.', [
    'profile' => $payload,
]);
