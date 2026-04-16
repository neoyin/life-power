class PresignedUrlData {
  final String presignedUrl;
  final String publicUrl;
  final Map<String, String> fields;

  PresignedUrlData.fromJson(Map<String, dynamic> json)
      : presignedUrl = json['presigned_url'],
        publicUrl = json['public_url'],
        fields = Map<String, String>.from(json['fields']);
}
