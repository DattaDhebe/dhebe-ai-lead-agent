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
$userId = (int) $user['id'];

$pdo->beginTransaction();

try {
    $reminderStmt = $pdo->prepare(
        'DELETE FROM reminders
         WHERE lead_id = :lead_id AND user_id = :user_id'
    );
    $reminderStmt->execute([
        'lead_id' => $leadId,
        'user_id' => $userId,
    ]);

    $stmt = $pdo->prepare(
        'DELETE FROM leads
         WHERE id = :id AND user_id = :user_id'
    );
    $stmt->execute([
        'id' => $leadId,
        'user_id' => $userId,
    ]);

    if ($stmt->rowCount() === 0) {
        $pdo->rollBack();
        Response::error('Lead not found.', 404);
    }

    $pdo->commit();
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }

    throw $exception;
}

Response::success('Lead deleted successfully.');
