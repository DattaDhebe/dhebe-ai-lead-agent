<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

Request::requireMethod('GET');

$pdo = Database::connect();
$user = AuthMiddleware::requireUser($pdo);

$startOfDay = new DateTimeImmutable('today');
$startOfTomorrow = $startOfDay->modify('+1 day');

$stmt = $pdo->prepare(
    'SELECT r.id, r.lead_id, r.title, r.reminder_at, r.status, r.notes, r.created_at, r.updated_at,
            l.name AS lead_name, l.phone AS lead_phone
     FROM reminders r
     LEFT JOIN leads l ON l.id = r.lead_id
     WHERE r.user_id = :user_id
       AND r.reminder_at >= :start_of_day
       AND r.reminder_at < :start_of_tomorrow
       AND r.status = "pending"
     ORDER BY r.reminder_at ASC'
);
$stmt->execute([
    'user_id' => (int) $user['id'],
    'start_of_day' => $startOfDay->format('Y-m-d H:i:s'),
    'start_of_tomorrow' => $startOfTomorrow->format('Y-m-d H:i:s'),
]);

Response::success('Today reminders fetched successfully.', [
    'reminders' => $stmt->fetchAll(),
]);
