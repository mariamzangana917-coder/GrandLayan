<?php

namespace App\Http\Requests\Admin\Banners;

class StoreBannerRequest extends BannerRequest
{
    protected function imageIsRequired(): bool
    {
        return true;
    }

    protected function fieldsAreRequired(): bool
    {
        return true;
    }
}
