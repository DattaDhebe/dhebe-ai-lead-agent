<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

Request::requireMethod('GET');

$pdo = Database::connect();
$user = AuthMiddleware::requireUser($pdo);

$leadId = Request::query('id');

if ($idError = Validator::integer($leadId, 'id', true)) {
    Response::error('Validation failed.', 422, ['id' => $idError]);
}

$stmt = $pdo->prepare(
    'SELECT id, name, phone, email, source, service_interested, customer_message, status,
            next_follow_up_at, notes, created_at, updated_at
     FROM leads
     WHERE id = :id AND user_id = :user_id
     LIMIT 1'
);
$stmt->execute([
    'id' => (int) $leadId,
    'user_id' => (int) $user['id'],
]);
$lead = $stmt->fetch();

if ($lead === false) {
    Response::error('Lead not found.', 404);
}

$notesStmt = $pdo->prepare(
    'SELECT id, note, created_at
     FROM lead_notes
     WHERE lead_id = :lead_id AND user_id = :user_id
     ORDER BY created_at DESC'
);
$notesStmt->execute([
    'lead_id' => (int) $leadId,
    'user_id' => (int) $user['id'],
]);

$repliesStmt = $pdo->prepare(
    'SELECT id, customer_message, generated_reply, provider, model_name, created_at
     FROM ai_generated_replies
     WHERE lead_id = :lead_id AND user_id = :user_id
     ORDER BY created_at DESC
     LIMIT 10'
);
$repliesStmt->execute([
    'lead_id' => (int) $leadId,
    'user_id' => (int) $user['id'],
]);

Response::success('Lead fetched successfully.', [
    'lead' => $lead,
    'notes_history' => $notesStmt->fetchAll(),
    'generated_replies' => $repliesStmt->fetchAll(),
]);
