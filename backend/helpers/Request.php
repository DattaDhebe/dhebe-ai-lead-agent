<?php

declare(strict_types=1);

final class Request
{
    public static function requireMethod(string $method): void
    {
        $actual = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

        if ($actual !== strtoupper($method)) {
            Response::error('Method not allowed.', 405);
        }
    }

    /**
     * @return array<string, mixed>
     */
    public static function json(): array
    {
        $raw = file_get_contents('php://input');

        if ($raw === false || trim($raw) === '') {
            return [];
        }

        $decoded = json_decode($raw, true);

        if (!is_array($decoded)) {
            Response::error('Invalid JSON payload.', 400);
        }

        return $decoded;
    }

    public static function query(string $key, ?string $default = null): ?string
    {
        if (!isset($_GET[$key])) {
            return $default;
        }

        return trim((string) $_GET[$key]);
    }
}
