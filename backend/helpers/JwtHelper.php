<?php

declare(strict_types=1);

final class JwtHelper
{
    /**
     * @param array<string, mixed> $payload
     */
    public static function encode(array $payload, string $secret): string
    {
        $header = ['alg' => 'HS256', 'typ' => 'JWT'];

        $headerPart = self::base64UrlEncode(json_encode($header, JSON_UNESCAPED_SLASHES));
        $payloadPart = self::base64UrlEncode(json_encode($payload, JSON_UNESCAPED_SLASHES));
        $signature = hash_hmac('sha256', $headerPart . '.' . $payloadPart, $secret, true);
        $signaturePart = self::base64UrlEncode($signature);

        return $headerPart . '.' . $payloadPart . '.' . $signaturePart;
    }

    /**
     * @return array<string, mixed>|null
     */
    public static function decode(string $token, string $secret): ?array
    {
        $parts = explode('.', $token);

        if (count($parts) !== 3) {
            return null;
        }

        [$headerPart, $payloadPart, $signaturePart] = $parts;

        $expectedSignature = self::base64UrlEncode(
            hash_hmac('sha256', $headerPart . '.' . $payloadPart, $secret, true)
        );

        if (!hash_equals($expectedSignature, $signaturePart)) {
            return null;
        }

        $payload = json_decode(self::base64UrlDecode($payloadPart), true);

        if (!is_array($payload)) {
            return null;
        }

        $expiresAt = (int) ($payload['exp'] ?? 0);

        if ($expiresAt !== 0 && $expiresAt < time()) {
            return null;
        }

        return $payload;
    }

    /**
     * @param array<string, mixed> $user
     */
    public static function issueToken(array $user): string
    {
        $secret = Env::get('JWT_SECRET', '');

        if ($secret === '') {
            Response::error('JWT secret is not configured.', 500);
        }

        $now = time();
        $ttl = (int) Env::get('JWT_TTL_SECONDS', '604800');

        return self::encode([
            'sub' => (int) $user['id'],
            'email' => (string) $user['email'],
            'name' => (string) $user['name'],
            'iat' => $now,
            'exp' => $now + $ttl,
        ], $secret);
    }

    public static function getBearerToken(): ?string
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';

        if ($header === '' && function_exists('getallheaders')) {
            $headers = getallheaders();
            $header = $headers['Authorization'] ?? $headers['authorization'] ?? '';
        }

        if (!preg_match('/Bearer\s+(.+)/i', $header, $matches)) {
            return null;
        }

        return trim($matches[1]);
    }

    private static function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private static function base64UrlDecode(string $value): string
    {
        $padding = strlen($value) % 4;

        if ($padding > 0) {
            $value .= str_repeat('=', 4 - $padding);
        }

        return (string) base64_decode(strtr($value, '-_', '+/'));
    }
}
