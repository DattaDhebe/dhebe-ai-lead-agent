<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

Request::requireMethod('POST');

$pdo = Database::connect();
$user = AuthMiddleware::requireUser($pdo);
$data = Request::json();

if ($idError = Validator::integer($data['id'] ?? null, 'id', true)) {
    Response::error('Validation failed.', 422, ['id' => $idError]);
}

$leadId = (int) $data['id'];

$existingStmt = $pdo->prepare(
    'SELECT *
     FROM leads
     WHERE id = :id AND user_id = :user_id
     LIMIT 1'
);
$existingStmt->execute([
    'id' => $leadId,
    'user_id' => (int) $user['id'],
]);
$existing = $existingStmt->fetch();

if ($existing === false) {
    Response::error('Lead not found.', 404);
}

$merged = [
    'name' => trim((string) ($data['name'] ?? $existing['name'])),
    'phone' => trim((string) ($data['phone'] ?? $existing['phone'])),
    'email' => trim((string) ($data['email'] ?? ($existing['email'] ?? ''))),
    'source' => trim((string) ($data['source'] ?? $existing['source'])),
    'service_interested' => trim((string) ($data['service_interested'] ?? $existing['service_interested'])),
    'customer_message' => trim((string) ($data['customer_message'] ?? $existing['customer_message'])),
    'status' => trim((string) ($data['status'] ?? $existing['status'])),
    'next_follow_up_at' => array_key_exists('next_follow_up_at', $data)
        ? trim((string) ($data['next_follow_up_at'] ?? ''))
        : (string) ($existing['next_follow_up_at'] ?? ''),
    'notes' => array_key_exists('notes', $data)
        ? trim((string) ($data['notes'] ?? ''))
        : trim((string) ($existing['notes'] ?? '')),
];

$errors = Validator::requireFields($merged, ['name', 'phone', 'source', 'service_interested', 'customer_message']);

if ($phoneError = Validator::phone($merged['phone'], 'phone')) {
    $errors['phone'] = $phoneError;
}

if ($emailError = Validator::email($merged['email'], 'email')) {
    $errors['email'] = $emailError;
}

if ($statusError = Validator::enum($merged['status'], 'status', ['new', 'contacted', 'interested', 'converted', 'lost'])) {
    $errors['status'] = $statusError;
}

$followUpValue = $merged['next_follow_up_at'] !== '' ? $merged['next_follow_up_at'] : null;

if ($dateTimeError = Validator::dateTime($followUpValue, 'next_follow_up_at')) {
    $errors['next_follow_up_at'] = $dateTimeError;
}

if ($errors !== []) {
    Response::error('Validation failed.', 422, $errors);
}

$newNote = trim((string) ($data['new_note'] ?? ''));

if ($newNote !== '') {
    $merged['notes'] = trim($merged['notes'] . PHP_EOL . $newNote);
}

$pdo->beginTransaction();

try {
    $updateStmt = $pdo->prepare(
        'UPDATE leads
         SET name = :name,
             phone = :phone,
             email = :email,
             source = :source,
             service_interested = :service_interested,
             customer_message = :customer_message,
             status = :status,
             next_follow_up_at = :next_follow_up_at,
             notes = :notes
         WHERE id = :id AND user_id = :user_id'
    );
    $updateStmt->execute([
        'id' => $leadId,
        'user_id' => (int) $user['id'],
        'name' => $merged['name'],
        'phone' => $merged['phone'],
        'email' => $merged['email'] !== '' ? $merged['email'] : null,
        'source' => $merged['source'],
        'service_interested' => $merged['service_interested'],
        'customer_message' => $merged['customer_message'],
        'status' => $merged['status'],
        'next_follow_up_at' => $followUpValue,
        'notes' => $merged['notes'] !== '' ? $merged['notes'] : null,
    ]);

    if ($newNote !== '') {
        $noteStmt = $pdo->prepare(
            'INSERT INTO lead_notes (lead_id, user_id, note)
             VALUES (:lead_id, :user_id, :note)'
        );
        $noteStmt->execute([
            'lead_id' => $leadId,
            'user_id' => (int) $user['id'],
            'note' => $newNote,
        ]);
    }

    $pdo->commit();
} catch (Throwable $exception) {
    $pdo->rollBack();
    throw $exception;
}

Response::success('Lead updated successfully.', [
    'lead' => array_merge($merged, [
        'id' => $leadId,
        'next_follow_up_at' => $followUpValue,
    ]),
]);
