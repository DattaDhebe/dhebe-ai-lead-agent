<?php

declare(strict_types=1);

final class AuthMiddleware
{
    /**
     * @return array<string, mixed>
     */
    public static function requireUser(PDO $pdo): array
    {
        $token = JwtHelper::getBearerToken();

        if ($token === null) {
            Response::error('Authentication token is required.', 401);
        }

        $secret = Env::get('JWT_SECRET', '');
        $payload = JwtHelper::decode($token, $secret);

        if ($payload === null) {
            Response::error('Invalid or expired authentication token.', 401);
        }

        $userId = (int) ($payload['sub'] ?? 0);

        $stmt = $pdo->prepare(
            'SELECT id, name, email, phone, business_name, created_at
             FROM users
             WHERE id = :id
             LIMIT 1'
        );
        $stmt->execute(['id' => $userId]);
        $user = $stmt->fetch();

        if ($user === false) {
            Response::error('User not found.', 401);
        }

        return $user;
    }
}
