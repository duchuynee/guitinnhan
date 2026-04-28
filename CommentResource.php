<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CommentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'post_id'    => $this->post_id,
            'content'    => $this->content,
            'timestamp'  => $this->created_at?->locale(app()->getLocale())->diffForHumans(),
            'created_at' => $this->created_at?->toISOString(),
            'author'     => $this->whenLoaded('user', fn () => [
                'id'         => $this->user->id,
                'name'       => $this->user->name,
                'username'   => $this->user->username,
                'avatar_url' => $this->user->avatar_url,
            ]),
        ];
    }
}
