<?php

namespace App\Http\Controllers\Api\Notifications;

use App\Http\Controllers\Controller;
use App\Http\Requests\Notifications\UpdateNotificationPreferencesRequest;
use App\Http\Resources\Notifications\NotificationPreferenceResource;
use App\Models\NotificationPreference;
use Illuminate\Http\Request;

class NotificationPreferenceController extends Controller
{
    public function show(Request $request): NotificationPreferenceResource
    {
        return new NotificationPreferenceResource(
            $this->preferencesFor($request),
        );
    }

    public function update(
        UpdateNotificationPreferencesRequest $request,
    ): NotificationPreferenceResource {
        $preferences = $this->preferencesFor($request);
        $preferences->fill($request->validated());
        $preferences->save();

        return new NotificationPreferenceResource($preferences->refresh());
    }

    private function preferencesFor(Request $request): NotificationPreference
    {
        $preferences = NotificationPreference::query()->firstOrCreate([
            'user_id' => $request->user()->id,
        ]);

        return $preferences->refresh();
    }
}
