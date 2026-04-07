<?php

function ensure_auth_role_support(PDO $pdo): void
{
    static $isInitialized = false;

    if ($isInitialized) {
        return;
    }

    $pdo->exec(
        "ALTER TABLE users
         MODIFY COLUMN role ENUM('user', 'admin', 'delivery') DEFAULT 'user'"
    );

    $defaultDeliveryEmail = 'delivery@wagba.com';
    $defaultDeliveryPasswordHash = '$2y$12$HgwJiSmQ5wfH.rSaaF3NWO2dR.Xi0lKyiFMjpfNFpvF5WXb8K/diy';

    $stmt = $pdo->prepare(
        "INSERT INTO users (full_name, email, password, role)
         VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
            full_name = VALUES(full_name),
            role = VALUES(role)"
    );
    $stmt->execute([
        'Saffron Delivery',
        $defaultDeliveryEmail,
        $defaultDeliveryPasswordHash,
        'delivery',
    ]);

    $isInitialized = true;
}

function normalize_auth_role(?string $role): string
{
    $normalized = strtolower(trim((string) $role));
    return in_array($normalized, ['user', 'admin', 'delivery'], true)
        ? $normalized
        : 'user';
}
