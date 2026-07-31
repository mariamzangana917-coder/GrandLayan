<?php

namespace App\Support\Notifications;

final class NotificationType
{
    public const APPOINTMENT_CREATED = 'appointment_created';
    public const APPOINTMENT_CONFIRMED = 'appointment_confirmed';
    public const APPOINTMENT_UPDATED = 'appointment_updated';
    public const APPOINTMENT_CANCELLED = 'appointment_cancelled';
    public const APPOINTMENT_REMINDER = 'appointment_reminder';
    public const LASER_REMINDER = 'laser_reminder';
    public const REVIEW_REQUEST = 'review_request';
    public const CHAT_MESSAGE = 'chat_message';
    public const OFFER_PUBLISHED = 'offer_published';
    public const GIFT_CARD_ORDER_CREATED = 'gift_card_order_created';
    public const GIFT_CARD_ISSUED = 'gift_card_issued';
    public const GIFT_CARD_EXPIRING = 'gift_card_expiring';
    public const PAYMENT_UPDATED = 'payment_updated';
    public const SECURITY = 'security';
    public const GENERAL = 'general';

    private function __construct()
    {
    }
}
