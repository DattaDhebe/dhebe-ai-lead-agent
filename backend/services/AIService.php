<?php

declare(strict_types=1);

require_once __DIR__ . '/GeminiService.php';
require_once __DIR__ . '/OpenAIService.php';

final class AIService
{
    private GeminiService $geminiService;

    public function __construct(?GeminiService $geminiService = null)
    {
        $this->geminiService = $geminiService ?? new GeminiService();
    }

    /**
     * @param array<string, mixed> $payload
     * @return array<string, string|int|null>
     */
    public function generateLeadReply(PDO $pdo, int $userId, array $payload): array
    {
        $this->assertRateLimit($pdo, $userId);

        $leadId = isset($payload['lead_id']) ? (int) $payload['lead_id'] : null;
        $businessProfile = $this->getBusinessProfile($pdo, $userId);
        $lead = $leadId !== null ? $this->getOwnedLead($pdo, $userId, $leadId) : null;

        $customerMessage = trim((string) ($payload['customer_message'] ?? $lead['customer_message'] ?? ''));

        if ($customerMessage === '') {
            Response::error('Customer message is required to generate a reply.', 422);
        }

        $customerName = trim((string) ($payload['customer_name'] ?? $lead['name'] ?? ''));
        $serviceInterested = trim((string) ($payload['service_interested'] ?? $lead['service_interested'] ?? ''));
        $source = trim((string) ($payload['source'] ?? $lead['source'] ?? ''));

        $prompt = $this->buildPrompt($businessProfile, [
            'customer_name' => $customerName,
            'service_interested' => $serviceInterested,
            'source' => $source,
            'customer_message' => $customerMessage,
        ]);

        try {
            $result = $this->geminiService->generateReply($prompt);
            $reply = trim($result['reply']);

            $this->saveGeneratedReply(
                $pdo,
                $userId,
                $leadId,
                $customerMessage,
                $reply,
                $result['provider'],
                $result['model']
            );

            $this->saveUsageLog(
                $pdo,
                $userId,
                $leadId,
                $result['provider'],
                $result['model'],
                $customerMessage,
                'success',
                null
            );

            return [
                'lead_id' => $leadId,
                'provider' => $result['provider'],
                'model' => $result['model'],
                'reply' => $reply,
            ];
        } catch (Throwable $exception) {
            $this->saveUsageLog(
                $pdo,
                $userId,
                $leadId,
                'gemini',
                Env::get('GEMINI_MODEL', 'gemini-2.0-flash'),
                $customerMessage,
                'failed',
                $exception->getMessage()
            );

            throw $exception;
        }
    }

    private function assertRateLimit(PDO $pdo, int $userId): void
    {
        $limit = (int) Env::get('AI_RATE_LIMIT_PER_HOUR', '30');

        $stmt = $pdo->prepare(
            'SELECT COUNT(*) AS total
             FROM ai_usage_logs
             WHERE user_id = :user_id
               AND created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)'
        );
        $stmt->execute(['user_id' => $userId]);
        $total = (int) ($stmt->fetch()['total'] ?? 0);

        if ($total >= $limit) {
            Response::error('AI usage limit reached for this hour. Please try again later.', 429);
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function getBusinessProfile(PDO $pdo, int $userId): array
    {
        $stmt = $pdo->prepare(
            'SELECT bp.*, u.name AS user_name, u.phone AS user_phone, u.business_name AS fallback_business_name
             FROM business_profiles bp
             INNER JOIN users u ON u.id = bp.user_id
             WHERE bp.user_id = :user_id
             LIMIT 1'
        );
        $stmt->execute(['user_id' => $userId]);
        $profile = $stmt->fetch();

        if ($profile === false) {
            $userStmt = $pdo->prepare(
                'SELECT id, name AS user_name, phone AS user_phone, business_name AS fallback_business_name
                 FROM users
                 WHERE id = :user_id
                 LIMIT 1'
            );
            $userStmt->execute(['user_id' => $userId]);
            $user = $userStmt->fetch();

            return $user === false ? [] : $user;
        }

        return $profile;
    }

    /**
     * @return array<string, mixed>
     */
    private function getOwnedLead(PDO $pdo, int $userId, int $leadId): array
    {
        $stmt = $pdo->prepare(
            'SELECT id, name, source, service_interested, customer_message
             FROM leads
             WHERE id = :id AND user_id = :user_id
             LIMIT 1'
        );
        $stmt->execute([
            'id' => $leadId,
            'user_id' => $userId,
        ]);

        $lead = $stmt->fetch();

        if ($lead === false) {
            Response::error('Lead not found.', 404);
        }

        return $lead;
    }

    /**
     * @param array<string, mixed> $businessProfile
     * @param array<string, string> $leadContext
     */
    private function buildPrompt(array $businessProfile, array $leadContext): string
    {
        $businessName = $businessProfile['business_name'] ?? $businessProfile['fallback_business_name'] ?? 'the business';
        $ownerName = $businessProfile['owner_name'] ?? $businessProfile['user_name'] ?? '';
        $services = $businessProfile['services_text'] ?? '';
        $faq = $businessProfile['faq_text'] ?? '';
        $tone = $businessProfile['tone_notes'] ?? '';
        $policyNotes = $businessProfile['policy_notes'] ?? '';

        return trim(
            "You are an assistant helping an Indian small business reply to inbound customer leads.\n\n" .
            "Business profile:\n" .
            "- Business name: {$businessName}\n" .
            "- Owner or rep name: {$ownerName}\n" .
            "- Services: {$services}\n" .
            "- FAQs and approved details: {$faq}\n" .
            "- Tone notes: {$tone}\n" .
            "- Important policy notes: {$policyNotes}\n\n" .
            "Lead context:\n" .
            "- Customer name: {$leadContext['customer_name']}\n" .
            "- Lead source: {$leadContext['source']}\n" .
            "- Service interested: {$leadContext['service_interested']}\n" .
            "- Customer message: {$leadContext['customer_message']}\n\n" .
            "Rules:\n" .
            "- Write one short WhatsApp-friendly reply only.\n" .
            "- Keep it polite, professional, helpful, and human-sounding.\n" .
            "- Ask one relevant follow-up question only when it helps move the conversation forward.\n" .
            "- Do not create guarantees, discounts, offers, or availability claims unless explicitly present in the business profile.\n" .
            "- Do not generate spammy, deceptive, harmful, or manipulative language.\n" .
            "- Output only the final reply text.\n"
        );
    }

    private function saveGeneratedReply(
        PDO $pdo,
        int $userId,
        ?int $leadId,
        string $customerMessage,
        string $reply,
        string $provider,
        string $model
    ): void {
        $stmt = $pdo->prepare(
            'INSERT INTO ai_generated_replies
                (user_id, lead_id, customer_message, generated_reply, provider, model_name)
             VALUES
                (:user_id, :lead_id, :customer_message, :generated_reply, :provider, :model_name)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'lead_id' => $leadId,
            'customer_message' => $customerMessage,
            'generated_reply' => $reply,
            'provider' => $provider,
            'model_name' => $model,
        ]);
    }

    private function saveUsageLog(
        PDO $pdo,
        int $userId,
        ?int $leadId,
        string $provider,
        string $model,
        string $requestExcerpt,
        string $status,
        ?string $errorMessage
    ): void {
        $stmt = $pdo->prepare(
            'INSERT INTO ai_usage_logs
                (user_id, lead_id, provider, model_name, request_excerpt, status, error_message)
             VALUES
                (:user_id, :lead_id, :provider, :model_name, :request_excerpt, :status, :error_message)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'lead_id' => $leadId,
            'provider' => $provider,
            'model_name' => $model,
            'request_excerpt' => mb_substr($requestExcerpt, 0, 500),
            'status' => $status,
            'error_message' => $errorMessage,
        ]);
    }
}
