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

$stmt = $pdo->prepare(
    'DELETE FROM leads
     WHERE id = :id AND user_id = :user_id'
);
$stmt->execute([
    'id' => (int) $data['id'],
    'user_id' => (int) $user['id'],
]);

if ($stmt->rowCount() === 0) {
    Response::error('Lead not found.', 404);
}

Response::success('Lead deleted successfully.');
