<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

Request::requireMethod('POST');

$pdo = Database::connect();
$data = Request::json();

$errors = Validator::requireFields($data, ['name', 'email', 'phone', 'password']);

if ($emailError = Validator::email(isset($data['email']) ? (string) $data['email'] : null, 'email', true)) {
    $errors['email'] = $emailError;
}

if ($phoneError = Validator::phone(isset($data['phone']) ? (string) $data['phone'] : null, 'phone')) {
    $errors['phone'] = $phoneError;
}

if ($passwordError = Validator::minLength(isset($data['password']) ? (string) $data['password'] : null, 'password', 8)) {
    $errors['password'] = $passwordError;
}

if ($errors !== []) {
    Response::error('Validation failed.', 422, $errors);
}

$email = trim((string) $data['email']);
$name = trim((string) $data['name']);
$phone = trim((string) $data['phone']);
$password = (string) $data['password'];
$businessName = trim((string) ($data['business_name'] ?? ''));

$checkStmt = $pdo->prepare('SELECT id FROM users WHERE email = :email LIMIT 1');
$checkStmt->execute(['email' => $email]);

if ($checkStmt->fetch() !== false) {
    Response::error('An account with this email already exists.', 409);
}

$passwordHash = password_hash($password, PASSWORD_DEFAULT);

$pdo->beginTransaction();

try {
    $userStmt = $pdo->prepare(
        'INSERT INTO users (name, business_name, phone, email, password_hash)
         VALUES (:name, :business_name, :phone, :email, :password_hash)'
    );
    $userStmt->execute([
        'name' => $name,
        'business_name' => $businessName !== '' ? $businessName : null,
        'phone' => $phone,
        'email' => $email,
        'password_hash' => $passwordHash,
    ]);

    $userId = (int) $pdo->lastInsertId();

    $profileStmt = $pdo->prepare(
        'INSERT INTO business_profiles
            (user_id, business_name, owner_name, business_phone, business_email)
         VALUES
            (:user_id, :business_name, :owner_name, :business_phone, :business_email)'
    );
    $profileStmt->execute([
        'user_id' => $userId,
        'business_name' => $businessName !== '' ? $businessName : null,
        'owner_name' => $name,
        'business_phone' => $phone,
        'business_email' => $email,
    ]);

    $pdo->commit();
} catch (Throwable $exception) {
    $pdo->rollBack();
    throw $exception;
}

$user = [
    'id' => $userId,
    'name' => $name,
    'email' => $email,
    'phone' => $phone,
    'business_name' => $businessName,
];

$token = JwtHelper::issueToken($user);

Response::success('Registration successful.', [
    'token' => $token,
    'user' => $user,
], 201);
