<?php

declare(strict_types=1);

final class GeminiService
{
    /**
     * @return array<string, string>
     */
    public function generateReply(string $prompt): array
    {
        $apiKey = Env::get('GEMINI_API_KEY', '');
        $model = Env::get('GEMINI_MODEL', 'gemini-2.0-flash');

        if ($apiKey === '') {
            Response::error('Gemini API key is not configured.', 500);
        }

        $url = sprintf(
            'https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s',
            rawurlencode($model),
            rawurlencode($apiKey)
        );

        $payload = [
            'contents' => [[
                'role' => 'user',
                'parts' => [[
                    'text' => $prompt,
                ]],
            ]],
            'generationConfig' => [
                'temperature' => 0.7,
                'maxOutputTokens' => 220,
                'topP' => 0.9,
            ],
        ];

        $ch = curl_init($url);

        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
            CURLOPT_POSTFIELDS => json_encode($payload, JSON_UNESCAPED_UNICODE),
            CURLOPT_TIMEOUT => 30,
        ]);

        $response = curl_exec($ch);
        $curlError = curl_error($ch);
        $statusCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($response === false || $curlError !== '') {
            Response::error('Gemini request failed.', 502, ['details' => $curlError]);
        }

        $decoded = json_decode($response, true);

        if ($statusCode >= 400) {
            $message = $decoded['error']['message'] ?? 'Gemini request returned an error.';
            Response::error($message, 502);
        }

        $parts = $decoded['candidates'][0]['content']['parts'] ?? [];
        $text = '';

        foreach ($parts as $part) {
            if (isset($part['text']) && is_string($part['text'])) {
                $text .= $part['text'];
            }
        }

        $text = trim($text);

        if ($text === '') {
            Response::error('Gemini returned an empty reply.', 502);
        }

        return [
            'provider' => 'gemini',
            'model' => $model,
            'reply' => $text,
        ];
    }
}
