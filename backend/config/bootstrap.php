<?php

declare(strict_types=1);

require_once __DIR__ . '/../helpers/Env.php';
require_once __DIR__ . '/../helpers/Response.php';
require_once __DIR__ . '/../helpers/Request.php';
require_once __DIR__ . '/../helpers/Validator.php';
require_once __DIR__ . '/../helpers/JwtHelper.php';
require_once __DIR__ . '/Database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';

Env::load(dirname(__DIR__) . '/.env');

date_default_timezone_set(Env::get('APP_TIMEZONE', 'Asia/Kolkata'));

$allowedOrigin = Env::get('CORS_ALLOWED_ORIGIN', '*');

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: ' . $allowedOrigin);
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

set_exception_handler(static function (Throwable $exception): void {
    $debug = filter_var(Env::get('APP_DEBUG', 'false'), FILTER_VALIDATE_BOOLEAN);

    Response::error(
        $debug ? $exception->getMessage() : 'Unexpected server error.',
        500,
        $debug ? ['trace' => $exception->getTraceAsString()] : []
    );
});
