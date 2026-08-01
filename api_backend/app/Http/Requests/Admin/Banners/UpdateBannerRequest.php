<?php

namespace App\Http\Requests\Admin\Banners;

class UpdateBannerRequest extends BannerRequest
{
    protected function imageIsRequired(): bool
    {
        return false;
    }

    protected function fieldsAreRequired(): bool
    {
        return false;
    }
}
