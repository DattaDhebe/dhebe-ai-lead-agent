<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

Request::requireMethod('POST');

$pdo = Database::connect();
$data = Request::json();

$errors = Validator::requireFields($data, ['email', 'password']);

if ($emailError = Validator::email(isset($data['email']) ? (string) $data['email'] : null, 'email', true)) {
    $errors['email'] = $emailError;
}

if ($errors !== []) {
    Response::error('Validation failed.', 422, $errors);
}

$stmt = $pdo->prepare(
    'SELECT id, name, email, phone, business_name, password_hash
     FROM users
     WHERE email = :email
     LIMIT 1'
);
$stmt->execute(['email' => trim((string) $data['email'])]);
$user = $stmt->fetch();

if ($user === false || !password_verify((string) $data['password'], (string) $user['password_hash'])) {
    Response::error('Invalid email or password.', 401);
}

$token = JwtHelper::issueToken($user);
unset($user['password_hash']);

Response::success('Login successful.', [
    'token' => $token,
    'user' => $user,
]);
