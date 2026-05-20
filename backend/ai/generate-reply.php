<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/../services/AIService.php';

Request::requireMethod('POST');

$pdo = Database::connect();
$user = AuthMiddleware::requireUser($pdo);
$data = Request::json();

$service = new AIService();
$result = $service->generateLeadReply($pdo, (int) $user['id'], $data);

Response::success('Reply generated successfully.', $result);
