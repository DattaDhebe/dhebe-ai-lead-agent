<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

echo json_encode([
    'success' => true,
    'message' => 'Dhebe AI Lead Agent API is running.',
    'docs' => [
        'login' => '/api/auth/login.php',
        'register' => '/api/auth/register.php',
        'leads' => '/api/leads/list.php',
    ],
], JSON_UNESCAPED_SLASHES);
