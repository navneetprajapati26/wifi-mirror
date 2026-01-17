// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Get URL query parameters from browser window
Map<String, String> getUrlParams() {
  final uri = Uri.parse(html.window.location.href);
  return uri.queryParameters;
}

/// Get the current URL
String getCurrentUrl() {
  return html.window.location.href;
}
