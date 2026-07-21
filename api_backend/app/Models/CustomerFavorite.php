<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CustomerFavorite extends Model
{
    use HasFactory;

    /**
     * اسم الجدول المرتبط بالموديل.
     */
    protected $table = 'customer_favorites';

    /**
     * الحقول المسموح بإدخالها جماعيًا.
     *
     * @var list<string>
     */
    protected $fillable = [
        'customer_id',
        'catalog_item_id',
    ];

    /**
     * الزبونة المالكة لسجل المفضلة.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(
            User::class,
            'customer_id',
        );
    }

    /**
     * الخدمة أو البكج المحفوظ في المفضلة.
     */
    public function catalogItem(): BelongsTo
    {
        return $this->belongsTo(
            CatalogItem::class,
            'catalog_item_id',
        );
    }
}
