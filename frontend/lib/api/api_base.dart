// lib/api_base.dart

// Base URL for your backend while using the ANDROID EMULATOR.
// const String baseUrl = 'http://10.0.2.2:3000';

// Example full endpoint:
//   $baseUrl/api/status
import 'package:flutter/foundation.dart';

String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000'; // browser
  } else {
    return 'http://10.0.2.2:3000'; // android emulator
  }
}