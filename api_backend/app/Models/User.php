<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasRoles, Notifiable;

    /**
     * الحقول المسموح بإدخالها جماعيًا.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'phone',
        'avatar',
        'email',
        'password',
        'is_active',
    ];

    /**
     * الحقول التي يجب إخفاؤها عند تحويل الموديل إلى JSON.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * تحويل أنواع الحقول.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
        ];
    }

    /**
     * سجلات المفضلة الخاصة بهذه الزبونة.
     */
    public function favorites(): HasMany
    {
        return $this->hasMany(
            CustomerFavorite::class,
            'customer_id',
        );
    }

    /**
     * سجلات استخدام الكوبونات الخاصة بهذه الزبونة.
     */
    public function couponRedemptions(): HasMany
    {
        return $this->hasMany(
            CouponRedemption::class,
            'customer_id',
        );
    }

    /**
     * طلبات بطاقات الهدايا التي اشترتها هذه الزبونة.
     */
    public function giftCardOrders(): HasMany
    {
        return $this->hasMany(
            GiftCardOrder::class,
            'customer_id',
        );
    }

    /**
     * عمليات بطاقات الهدايا التي نفذها هذا المستخدم يدويًا.
     */
    public function performedGiftCardTransactions(): HasMany
    {
        return $this->hasMany(
            GiftCardTransaction::class,
            'performed_by_user_id',
        );
    }
}
