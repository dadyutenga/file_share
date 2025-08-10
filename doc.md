### 4. Upload File (Small Files - Up to 50MB)
**Endpoint:** `POST /files/upload-api`  
**Content-Type:** `multipart/form-data`  
**Authentication:** Required

**Request Body (Form Data):**
```
file: File (required)
ttl: integer (optional, default: 0) - Expiry time in hours (0 = no expiry)
is_public: string (optional, default: "false") - "true" or "false"
```

**Flutter Example:**
```dart
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';

Future<Map<String, dynamic>> uploadFile(
  File file, 
  String token, 
  {int ttl = 0, bool isPublic = false}
) async {
  var request = http.MultipartRequest(
    'POST', 
    Uri.parse('$baseUrl/files/upload-api')
  );
  
  // Add headers
  request.headers['Authorization'] = 'Bearer $token';
  
  // Add file
  request.files.add(await http.MultipartFile.fromPath(
    'file',
    file.path,
    contentType: MediaType('application', 'octet-stream'),
  ));
  
  // Add form fields
  request.fields['ttl'] = ttl.toString();
  request.fields['is_public'] = isPublic.toString();
  
  var response = await request.send();
  var responseBody = await response.stream.bytesToString();
  
  if (response.statusCode == 200) {
    return json.decode(responseBody);
  } else {
    throw Exception('Upload failed: $responseBody');
  }
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "file_id": "abc123def456",
  "download_url": "http://domain.com/files/download/abc123def456",
  "preview_url": "http://domain.com/files/preview/abc123def456",
  "filename": "document.pdf",
  "file_size": 1048576,
  "is_public": false
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "File too large. Maximum size is 500MB"
}
```

---

### 5. Chunked Upload (Large Files - 50MB to 500MB)

#### 5.1. Start Chunked Upload
**Endpoint:** `POST /files/chunked-upload/start`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required

**Request Body (Form Data):**
```
filename=large_video.mp4
file_size=104857600
total_chunks=50
ttl=0
is_public=false
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> startChunkedUpload(
  String filename,
  int fileSize,
  int totalChunks,
  String token,
  {int ttl = 0, bool isPublic = false}
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/files/chunked-upload/start'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'filename': filename,
      'file_size': fileSize.toString(),
      'total_chunks': totalChunks.toString(),
      'ttl': ttl.toString(),
      'is_public': isPublic.toString(),
    },
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to start upload: ${response.body}');
  }
}
```

**Response (Success):**
```json
{
  "upload_id": "upload_abc123def456",
  "status": "started",
  "message": "Ready to receive 50 chunks",
  "chunk_size": 2097152
}
```

#### 5.2. Upload Chunk
**Endpoint:** `POST /files/chunked-upload/chunk`  
**Content-Type:** `multipart/form-data`  
**Authentication:** Required

**Request Body (Form Data):**
```
upload_id: string (required)
chunk_number: integer (required) - 0-based index
chunk: File (required) - Binary chunk data
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> uploadChunk(
  String uploadId,
  int chunkNumber,
  List<int> chunkData,
  String token,
) async {
  var request = http.MultipartRequest(
    'POST', 
    Uri.parse('$baseUrl/files/chunked-upload/chunk')
  );
  
  request.headers['Authorization'] = 'Bearer $token';
  request.fields['upload_id'] = uploadId;
  request.fields['chunk_number'] = chunkNumber.toString();
  
  request.files.add(http.MultipartFile.fromBytes(
    'chunk',
    chunkData,
    filename: 'chunk_$chunkNumber',
  ));
  
  var response = await request.send();
  var responseBody = await response.stream.bytesToString();
  
  if (response.statusCode == 200) {
    return json.decode(responseBody);
  } else {
    throw Exception('Chunk upload failed: $responseBody');
  }
}
```

**Response (Success):**
```json
{
  "chunk_number": 0,
  "status": "received",
  "upload_complete": false,
  "message": "Chunk 0 uploaded successfully"
}
```

#### 5.3. Complete Chunked Upload
**Endpoint:** `POST /files/chunked-upload/complete`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required

**Request Body (Form Data):**
```
upload_id=upload_abc123def456
ttl=0
is_public=false
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> completeChunkedUpload(
  String uploadId,
  String token,
  {int ttl = 0, bool isPublic = false}
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/files/chunked-upload/complete'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'upload_id': uploadId,
      'ttl': ttl.toString(),
      'is_public': isPublic.toString(),
    },
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to complete upload: ${response.body}');
  }
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "file_id": "abc123def456",
  "download_url": "http://domain.com/files/download/abc123def456",
  "preview_url": "http://domain.com/files/preview/abc123def456",
  "filename": "large_video.mp4",
  "file_size": 104857600,
  "is_public": false
}
```

#### 5.4. Cancel Chunked Upload
**Endpoint:** `DELETE /files/chunked-upload/cancel`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required

**Request Body (Form Data):**
```
upload_id=upload_abc123def456
```

**Flutter Example:**
```dart
Future<void> cancelChunkedUpload(String uploadId, String token) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/files/chunked-upload/cancel'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'upload_id': uploadId,
    },
  );
  
  if (response.statusCode != 200) {
    throw Exception('Failed to cancel upload: ${response.body}');
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Upload cancelled and cleaned up"
}
```

---

### 6. Download File
**Endpoint:** `GET /files/download/{file_id}`  
**Authentication:** Required for private files, Optional for public files

**Flutter Example:**
```dart
Future<List<int>> downloadFile(String fileId, String? token) async {
  Map<String, String> headers = {};
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  
  final response = await http.get(
    Uri.parse('$baseUrl/files/download/$fileId'),
    headers: headers,
  );
  
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Download failed: ${response.body}');
  }
}
```

**Response:** Binary file data with appropriate headers

**Access Rules:**
- Public files: Accessible by anyone
- Private files: Accessible only by file owner

---

### 7. Get File Preview (JSON)
**Endpoint:** `GET /files/api/preview/{file_id}`  
**Authentication:** Required for private files, Optional for public files

**Flutter Example:**
```dart
Future<Map<String, dynamic>> getFilePreview(String fileId, String? token) async {
  Map<String, String> headers = {};
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  
  final response = await http.get(
    Uri.parse('$baseUrl/files/api/preview/$fileId'),
    headers: headers,
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to get preview: ${response.body}');
  }
}
```

**Response:**
```json
{
  "file_id": "abc123def456",
  "original_filename": "document.pdf",
  "file_size": 1048576,
  "content_type": "application/pdf",
  "upload_time": "2024-01-15T10:30:00",
  "download_count": 5,
  "is_public": false,
  "ttl": 24,
  "owner_username": "john_doe",
  "file_type": "pdf",
  "preview_available": true
}
```

---

### 8. Delete File
**Endpoint:** `POST /files/delete/{file_id}`  
**Authentication:** Required (Owner only)

**Flutter Example:**
```dart
Future<Map<String, dynamic>> deleteFile(String fileId, String token) async {
  final response = await http.post(
    Uri.parse('$baseUrl/files/delete/$fileId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Delete failed: ${response.body}');
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "File deleted successfully"
}
```

---

### 9. Toggle File Privacy
**Endpoint:** `POST /files/toggle-privacy/{file_id}`  
**Authentication:** Required (Owner only)

**Flutter Example:**
```dart
Future<Map<String, dynamic>> toggleFilePrivacy(String fileId, String token) async {
  final response = await http.post(
    Uri.parse('$baseUrl/files/toggle-privacy/$fileId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Toggle privacy failed: ${response.body}');
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "File privacy updated",
  "is_public": true
}
```

---

### 10. Delete All User Files
**Endpoint:** `POST /files/delete-all`  
**Authentication:** Required

**Flutter Example:**
```dart
Future<Map<String, dynamic>> deleteAllFiles(String token) async {
  final response = await http.post(
    Uri.parse('$baseUrl/files/delete-all'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Delete all failed: ${response.body}');
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "All files deleted successfully",
  "deleted_count": 15
}
```

---

## 📱 Flutter Complete Implementation Example
