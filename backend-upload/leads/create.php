<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

Request::requireMethod('POST');

$pdo = Database::connect();
$user = AuthMiddleware::requireUser($pdo);
$data = Request::json();

$errors = Validator::requireFields($data, ['name', 'phone', 'source', 'service_interested', 'customer_message']);

if ($phoneError = Validator::phone(isset($data['phone']) ? (string) $data['phone'] : null, 'phone')) {
    $errors['phone'] = $phoneError;
}

if ($emailError = Validator::email(isset($data['email']) ? (string) $data['email'] : null, 'email')) {
    $errors['email'] = $emailError;
}

$status = trim((string) ($data['status'] ?? 'new'));

if ($statusError = Validator::enum($status, 'status', ['new', 'contacted', 'interested', 'converted', 'lost'])) {
    $errors['status'] = $statusError;
}

$nextFollowUpAt = isset($data['next_follow_up_at']) ? trim((string) $data['next_follow_up_at']) : null;

if ($dateTimeError = Validator::dateTime($nextFollowUpAt, 'next_follow_up_at')) {
    $errors['next_follow_up_at'] = $dateTimeError;
}

if ($errors !== []) {
    Response::error('Validation failed.', 422, $errors);
}

$notes = trim((string) ($data['notes'] ?? ''));

$pdo->beginTransaction();

try {
    $stmt = $pdo->prepare(
        'INSERT INTO leads
            (user_id, name, phone, email, source, service_interested, customer_message, status, next_follow_up_at, notes)
         VALUES
            (:user_id, :name, :phone, :email, :source, :service_interested, :customer_message, :status, :next_follow_up_at, :notes)'
    );
    $stmt->execute([
        'user_id' => (int) $user['id'],
        'name' => trim((string) $data['name']),
        'phone' => trim((string) $data['phone']),
        'email' => trim((string) ($data['email'] ?? '')) ?: null,
        'source' => trim((string) $data['source']),
        'service_interested' => trim((string) $data['service_interested']),
        'customer_message' => trim((string) $data['customer_message']),
        'status' => $status,
        'next_follow_up_at' => $nextFollowUpAt !== '' ? $nextFollowUpAt : null,
        'notes' => $notes !== '' ? $notes : null,
    ]);

    $leadId = (int) $pdo->lastInsertId();

    if ($notes !== '') {
        $noteStmt = $pdo->prepare(
            'INSERT INTO lead_notes (lead_id, user_id, note)
             VALUES (:lead_id, :user_id, :note)'
        );
        $noteStmt->execute([
            'lead_id' => $leadId,
            'user_id' => (int) $user['id'],
            'note' => $notes,
        ]);
    }

    if ($nextFollowUpAt !== null && $nextFollowUpAt !== '') {
        $reminderStmt = $pdo->prepare(
            'INSERT INTO reminders (user_id, lead_id, title, reminder_at, notes)
             VALUES (:user_id, :lead_id, :title, :reminder_at, :notes)'
        );
        $reminderStmt->execute([
            'user_id' => (int) $user['id'],
            'lead_id' => $leadId,
            'title' => 'Follow up with ' . trim((string) $data['name']),
            'reminder_at' => $nextFollowUpAt,
            'notes' => 'Auto-created from lead follow-up date.',
        ]);
    }

    $pdo->commit();
} catch (Throwable $exception) {
    $pdo->rollBack();
    throw $exception;
}

Response::success('Lead created successfully.', [
    'lead' => [
        'id' => $leadId,
        'name' => trim((string) $data['name']),
        'phone' => trim((string) $data['phone']),
        'email' => trim((string) ($data['email'] ?? '')),
        'source' => trim((string) $data['source']),
        'service_interested' => trim((string) $data['service_interested']),
        'customer_message' => trim((string) $data['customer_message']),
        'status' => $status,
        'next_follow_up_at' => $nextFollowUpAt,
        'notes' => $notes,
    ],
], 201);
