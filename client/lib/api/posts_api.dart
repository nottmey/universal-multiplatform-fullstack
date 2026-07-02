import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:client/api_client.dart';
import 'package:client/api_exception.dart';
import 'package:client/messages/create_post_request.dart';
import 'package:client/messages/edit_post_request.dart';
import 'package:client/messages/post_response.dart';

/// Endpoints with tag posts
class PostsApi {
  PostsApi(ApiClient? client) : client = client ?? ApiClient();

  final ApiClient client;

  /// Create a post
  Future<PostResponse> createPost(CreatePostRequest createPostRequest) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/posts',
      body: createPostRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'bearerAuth'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException<Object?>(
        response.statusCode,
        response.body,
      );
    }

    if (response.body.isNotEmpty) {
      return PostResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException<Object?>.unhandled(response.statusCode);
  }

  /// Replace the body of a post
  Future<PostResponse> editPost(
    String postId,
    EditPostRequest editPostRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.put,
      path: '/posts/{postId}'.replaceAll('{postId}', postId),
      body: editPostRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'bearerAuth'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException<Object?>(
        response.statusCode,
        response.body,
      );
    }

    if (response.body.isNotEmpty) {
      return PostResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException<Object?>.unhandled(response.statusCode);
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    final response = await client.invokeApi(
      method: Method.delete,
      path: '/posts/{postId}'.replaceAll('{postId}', postId),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'bearerAuth'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException<Object?>(
        response.statusCode,
        response.body,
      );
    }
  }
}
