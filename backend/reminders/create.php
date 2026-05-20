<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

Request::requireMethod('POST');

$pdo = Database::connect();
$user = AuthMiddleware::requireUser($pdo);
$data = Request::json();

$errors = Validator::requireFields($data, ['title', 'reminder_at']);

if ($dateTimeError = Validator::dateTime(isset($data['reminder_at']) ? (string) $data['reminder_at'] : null, 'reminder_at', true)) {
    $errors['reminder_at'] = $dateTimeError;
}

if ($leadIdError = Validator::integer($data['lead_id'] ?? null, 'lead_id')) {
    $errors['lead_id'] = $leadIdError;
}

if ($errors !== []) {
    Response::error('Validation failed.', 422, $errors);
}

$leadId = isset($data['lead_id']) && $data['lead_id'] !== '' ? (int) $data['lead_id'] : null;

if ($leadId !== null) {
    $leadStmt = $pdo->prepare(
        'SELECT id
         FROM leads
         WHERE id = :id AND user_id = :user_id
         LIMIT 1'
    );
    $leadStmt->execute([
        'id' => $leadId,
        'user_id' => (int) $user['id'],
    ]);

    if ($leadStmt->fetch() === false) {
        Response::error('Lead not found.', 404);
    }
}

$stmt = $pdo->prepare(
    'INSERT INTO reminders (user_id, lead_id, title, reminder_at, notes)
     VALUES (:user_id, :lead_id, :title, :reminder_at, :notes)'
);
$stmt->execute([
    'user_id' => (int) $user['id'],
    'lead_id' => $leadId,
    'title' => trim((string) $data['title']),
    'reminder_at' => trim((string) $data['reminder_at']),
    'notes' => trim((string) ($data['notes'] ?? '')) ?: null,
]);

Response::success('Reminder created successfully.', [
    'reminder_id' => (int) $pdo->lastInsertId(),
], 201);
