<?php

namespace App\Http\Controllers\Api\Notifications;

use App\Http\Controllers\Controller;
use App\Http\Requests\Notifications\UpdateNotificationPreferencesRequest;
use App\Http\Resources\Notifications\NotificationPreferenceResource;
use App\Models\NotificationPreference;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationPreferenceController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return $this->responseFor(
            $request,
            $this->preferencesFor($request),
        );
    }

    public function update(
        UpdateNotificationPreferencesRequest $request,
    ): JsonResponse {
        $preferences = $this->preferencesFor($request);
        $preferences->fill($request->validated());
        $preferences->save();

        return $this->responseFor(
            $request,
            $preferences->refresh(),
        );
    }

    private function preferencesFor(Request $request): NotificationPreference
    {
        return NotificationPreference::query()
            ->firstOrCreate([
                'user_id' => $request->user()->id,
            ])
            ->refresh();
    }

    private function responseFor(
        Request $request,
        NotificationPreference $preferences,
    ): JsonResponse {
        return response()->json([
            'data' => (new NotificationPreferenceResource(
                $preferences
            ))->resolve($request),
        ], 200);
    }
}