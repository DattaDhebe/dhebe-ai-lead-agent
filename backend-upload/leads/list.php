<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

Request::requireMethod('GET');

$pdo = Database::connect();
$user = AuthMiddleware::requireUser($pdo);

$status = Request::query('status');

if ($statusError = Validator::enum($status, 'status', ['new', 'contacted', 'interested', 'converted', 'lost'])) {
    Response::error('Validation failed.', 422, ['status' => $statusError]);
}

$query = 'SELECT id, name, phone, email, source, service_interested, customer_message, status,
                 next_follow_up_at, notes, created_at, updated_at
          FROM leads
          WHERE user_id = :user_id';

$params = ['user_id' => (int) $user['id']];

if ($status !== null && $status !== '') {
    $query .= ' AND status = :status';
    $params['status'] = $status;
}

$query .= ' ORDER BY next_follow_up_at IS NULL ASC, next_follow_up_at ASC, created_at DESC';

$stmt = $pdo->prepare($query);
$stmt->execute($params);
$leads = $stmt->fetchAll();

$countStmt = $pdo->prepare(
    'SELECT status, COUNT(*) AS total
     FROM leads
     WHERE user_id = :user_id
     GROUP BY status'
);
$countStmt->execute(['user_id' => (int) $user['id']]);
$countRows = $countStmt->fetchAll();

$counts = [
    'new' => 0,
    'contacted' => 0,
    'interested' => 0,
    'converted' => 0,
    'lost' => 0,
];

foreach ($countRows as $row) {
    $counts[(string) $row['status']] = (int) $row['total'];
}

Response::success('Leads fetched successfully.', [
    'leads' => $leads,
    'counts' => $counts,
]);
