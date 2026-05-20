<?php

declare(strict_types=1);

final class Validator
{
    /**
     * @param array<string, mixed> $data
     * @param string[] $fields
     * @return array<string, string>
     */
    public static function requireFields(array $data, array $fields): array
    {
        $errors = [];

        foreach ($fields as $field) {
            $value = $data[$field] ?? null;

            if (!is_string($value) || trim($value) === '') {
                $errors[$field] = ucfirst(str_replace('_', ' ', $field)) . ' is required.';
            }
        }

        return $errors;
    }

    public static function email(?string $value, string $field, bool $required = false): ?string
    {
        $value = $value !== null ? trim($value) : null;

        if (($value === null || $value === '') && !$required) {
            return null;
        }

        if ($value === null || !filter_var($value, FILTER_VALIDATE_EMAIL)) {
            return ucfirst(str_replace('_', ' ', $field)) . ' must be a valid email address.';
        }

        return null;
    }

    public static function phone(?string $value, string $field): ?string
    {
        $value = $value !== null ? trim($value) : '';

        if ($value === '') {
            return ucfirst(str_replace('_', ' ', $field)) . ' is required.';
        }

        if (!preg_match('/^[0-9+\-\s]{7,20}$/', $value)) {
            return ucfirst(str_replace('_', ' ', $field)) . ' must be a valid phone number.';
        }

        return null;
    }

    public static function minLength(?string $value, string $field, int $min): ?string
    {
        $value = $value !== null ? trim($value) : '';

        if (mb_strlen($value) < $min) {
            return ucfirst(str_replace('_', ' ', $field)) . " must be at least {$min} characters.";
        }

        return null;
    }

    /**
     * @param string[] $allowed
     */
    public static function enum(?string $value, string $field, array $allowed): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        if (!in_array($value, $allowed, true)) {
            return ucfirst(str_replace('_', ' ', $field)) . ' is invalid.';
        }

        return null;
    }

    public static function dateTime(?string $value, string $field, bool $required = false): ?string
    {
        $value = $value !== null ? trim($value) : null;

        if (($value === null || $value === '') && !$required) {
            return null;
        }

        if ($value === null || strtotime($value) === false) {
            return ucfirst(str_replace('_', ' ', $field)) . ' must be a valid datetime.';
        }

        return null;
    }

    public static function integer(mixed $value, string $field, bool $required = false): ?string
    {
        if (($value === null || $value === '') && !$required) {
            return null;
        }

        if (filter_var($value, FILTER_VALIDATE_INT) === false) {
            return ucfirst(str_replace('_', ' ', $field)) . ' must be a valid integer.';
        }

        return null;
    }
}
