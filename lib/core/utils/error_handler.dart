class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    String message = error.toString();

    if (message.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (message.contains('401')) {
      return 'Session expired. Please login again.';
    } else if (message.contains('403')) {
      return 'Task is locked for 21 days.';
    } else if (message.contains('400')) {
      return 'Invalid request. Please check your input.';
    } else if (message.contains('500')) {
      return 'Server error. Please try again later.';
    }

    return message.replaceAll('Exception: ', '');
  }
}
