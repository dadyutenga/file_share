## Authentication
The API uses JWT Bearer token authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

---

## 🔐 Authentication Endpoints

### 1. Register User (API)
**Endpoint:** `POST /auth/register`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** None required

**Request Body (Form Data):**
```
username=your_username
password=your_password
```

**Flutter Example:**
```dart
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> registerUser(String username, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'username': username,
      'password': password,
    },
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Registration failed: ${response.body}');
  }
}
```

**Response (Success):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer"
}
```

**Response (Error):**
```json
{
  "detail": "Username already registered"
}
```

**Validation Rules:**
- Username: Required, unique
- Password: Minimum 6 characters

---

### 2. Login User (API)
**Endpoint:** `POST /auth/login`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** None required

**Request Body (Form Data):**
```
username=your_username
password=your_password
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> loginUser(String username, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'username': username,
      'password': password,
    },
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Login failed: ${response.body}');
  }
}
```

**Response (Success):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer"
}
```

**Response (Error):**
```json
{
  "detail": "Incorrect username or password"
}
```

---

### 3. Logout
**Endpoint:** `POST /auth/logout`  
**Authentication:** Required

**Flutter Example:**
```dart
Future<void> logoutUser(String token) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/logout'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  
  if (response.statusCode != 200) {
    throw Exception('Logout failed');
  }
}
```

**Response:**
```json
{
  "message": "Successfully logged out"
}
```

---