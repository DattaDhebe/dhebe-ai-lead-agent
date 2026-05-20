<?php

declare(strict_types=1);

final class OpenAIService
{
    /**
     * @return array<string, string>
     */
    public function generateReply(string $prompt): array
    {
        Response::error('OpenAI adapter is not enabled in this MVP build.', 501);
    }
}
