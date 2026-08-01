<?php

namespace App\Enums;

enum BannerActionType: string
{
    case None = 'none';
    case Department = 'department';
    case Category = 'category';
    case CatalogItem = 'catalog_item';
    case Offers = 'offers';
    case Booking = 'booking';
    case GiftCard = 'gift_card';
    case ExternalUrl = 'external_url';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }

    public function requiresTarget(): bool
    {
        return in_array($this, [
            self::Department,
            self::Category,
            self::CatalogItem,
        ], true);
    }

    public function requiresExternalUrl(): bool
    {
        return $this === self::ExternalUrl;
    }
}
