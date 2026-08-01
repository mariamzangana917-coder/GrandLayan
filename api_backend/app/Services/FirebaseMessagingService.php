<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use RuntimeException;

final class FirebaseMessagingService
{
    public function sendToToken(
        string $token,
        string $title,
        string $body,
        array $data = [],
    ): array {
        $credentials = (string) config('firebase.credentials');

        if ($credentials === '' || ! is_file($credentials)) {
            throw new RuntimeException(
                'Firebase credentials file was not found.'
            );
        }

        $messaging = (new Factory())
            ->withServiceAccount($credentials)
            ->createMessaging();

        $normalizedData = [];

        foreach ($data as $key => $value) {
            $normalizedData[(string) $key] = is_scalar($value) || $value === null
                ? (string) $value
                : json_encode(
                    $value,
                    JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE
                );
        }

        $message = CloudMessage::new()->withToken($token)
            ->withNotification(Notification::create($title, $body))
            ->withData($normalizedData);

        return $messaging->send($message);
    }
}