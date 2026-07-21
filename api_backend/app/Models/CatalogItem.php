<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class CatalogItem extends Model
{
    use HasFactory, SoftDeletes;

    public const TYPE_SERVICE = 'service';

    public const TYPE_PACKAGE = 'package';

    public const PRICE_TYPE_FIXED = 'fixed';

    public const PRICE_TYPE_INSPECTION = 'inspection';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'category_id',
        'type',
        'name',
        'description',
        'instructions',
        'price_type',
        'price',
        'duration_minutes',
        'is_active',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'category_id' => 'integer',
            'price' => 'decimal:2',
            'duration_minutes' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    /**
     * التصنيف.
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * صور الخدمة أو البكج.
     */
    public function images(): HasMany
    {
        return $this->hasMany(CatalogItemImage::class)
            ->orderByDesc('is_primary')
            ->orderBy('sort_order')
            ->orderBy('id');
    }

    /**
     * الصورة الرئيسية.
     */
    public function primaryImage(): HasMany
    {
        return $this->hasMany(CatalogItemImage::class)
            ->where('is_primary', true);
    }

    /**
     * سجلات المفضلة الخاصة بهذه الخدمة أو البكج.
     */
    public function favorites(): HasMany
    {
        return $this->hasMany(
            CustomerFavorite::class,
            'catalog_item_id',
        );
    }

    /**
     * الخدمات الموجودة داخل البكج.
     */
    public function packageServices(): BelongsToMany
    {
        return $this->belongsToMany(
            self::class,
            'package_items',
            'package_id',
            'service_id'
        )
            ->withPivot([
                'quantity',
                'notes',
            ])
            ->withTimestamps();
    }

    /**
     * البكجات التي تحتوي هذه الخدمة.
     */
    public function containingPackages(): BelongsToMany
    {
        return $this->belongsToMany(
            self::class,
            'package_items',
            'service_id',
            'package_id'
        )
            ->withPivot([
                'quantity',
                'notes',
            ])
            ->withTimestamps();
    }

    /**
     * الكوبونات المرتبطة بالخدمة أو البكج.
     */
    public function coupons(): BelongsToMany
    {
        return $this->belongsToMany(
            Coupon::class,
            'coupon_catalog_item'
        )->withTimestamps();
    }

    public function isService(): bool
    {
        return $this->type === self::TYPE_SERVICE;
    }

    public function isPackage(): bool
    {
        return $this->type === self::TYPE_PACKAGE;
    }

    public function hasFixedPrice(): bool
    {
        return $this->price_type === self::PRICE_TYPE_FIXED;
    }

    public function requiresInspection(): bool
    {
        return $this->price_type === self::PRICE_TYPE_INSPECTION;
    }
}
