<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

Request::requireMethod('POST');

$pdo = Database::connect();
$user = AuthMiddleware::requireUser($pdo);
$data = Request::json();

$errors = Validator::requireFields($data, ['message']);

if ($ratingError = Validator::integer($data['rating'] ?? null, 'rating')) {
    $errors['rating'] = $ratingError;
}

$rating = isset($data['rating']) && $data['rating'] !== '' ? (int) $data['rating'] : null;

if ($rating !== null && ($rating < 1 || $rating > 5)) {
    $errors['rating'] = 'Rating must be between 1 and 5.';
}

if ($errors !== []) {
    Response::error('Validation failed.', 422, $errors);
}

$stmt = $pdo->prepare(
    'INSERT INTO app_feedback (user_id, rating, message)
     VALUES (:user_id, :rating, :message)'
);
$stmt->execute([
    'user_id' => (int) $user['id'],
    'rating' => $rating,
    'message' => trim((string) $data['message']),
]);

Response::success('Feedback submitted successfully.', [
    'feedback_id' => (int) $pdo->lastInsertId(),
], 201);
