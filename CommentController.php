<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommentResource;
use App\Http\Resources\PostResource;
use App\Models\Comment;
use App\Models\Post;
use App\Models\UserNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CommentController extends Controller
{
    public function index(Request $request, Post $post): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $comments = $post->comments()
            ->with('user')
            ->latest()
            ->paginate($validated['per_page'] ?? 20)
            ->withQueryString();

        return CommentResource::collection($comments);
    }

    public function store(Request $request, Post $post): JsonResponse
    {
        $data = $request->validate([
            'content' => ['required', 'string', 'min:1', 'max:2000'],
        ]);

        $viewer = $request->user();

        $comment = Comment::create([
            'post_id' => $post->id,
            'user_id' => $viewer->id,
            'content' => $data['content'],
        ]);

        $comment->load('user');
        $post->loadMissing('user')->syncInteractionCounts();

        if ($post->user_id !== $viewer->id) {
            UserNotification::create([
                'user_id'       => $post->user_id,
                'actor_user_id' => $viewer->id,
                'post_id'       => $post->id,
                'type'          => 'post_commented',
                'title'         => $viewer->name . ' da binh luan ve bai viet cua ban.',
                'body'          => '"' . mb_substr($data['content'], 0, 80) . '"',
                'data'          => ['post_id' => $post->id, 'actor_user_id' => $viewer->id],
            ]);
        }

        $refreshedPost = Post::query()->frontendState($viewer)->findOrFail($post->id);

        return response()->json([
            'message' => 'Binh luan da duoc dang.',
            'data'    => [
                'comment' => (new CommentResource($comment))->resolve($request),
                'post'    => (new PostResource($refreshedPost))->resolve($request),
            ],
        ], 201);
    }

    public function destroy(Request $request, Post $post, Comment $comment): JsonResponse
    {
        if ($comment->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Khong co quyen xoa binh luan nay.'], 403);
        }

        $comment->delete();
        $post->syncInteractionCounts();

        return response()->json(['message' => 'Binh luan da duoc xoa.']);
    }
}
