class PostEditorResult {
  const PostEditorResult({this.savedBody, this.deleted = false})
    : assert(savedBody == null || !deleted);

  final String? savedBody;
  final bool deleted;
}
