import 'package:client/api.dart';

class Social {
  Social({ApiClient? client}) : client = client ?? ApiClient();

  final ApiClient client;

  EventsApi get events => EventsApi(client);
  PostsApi get posts => PostsApi(client);
}
