class OnboardingData {
  String fullName = '';
  int? age;
  String focusPriority = 'Deep Work & Career Focus';
  String dailyScreenTime = '3 - 4 hours';
  Set<String> selectedCategories = {
    'Social Media & Feeds',
    'Endless Video & Streaming',
    'News & Infinite Browsers',
  };
  String scheduleStart = '9:00 AM';
  String scheduleEnd = '5:00 PM';
  Set<String> activeDays = {'M', 'T', 'W', 'T2', 'F'};
  bool strictLock = true;

  static final OnboardingData instance = OnboardingData._internal();
  OnboardingData._internal();

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'age': age,
      'focus_priority': focusPriority,
      'daily_screen_time': dailyScreenTime,
      'selected_categories': selectedCategories.toList(),
      'schedule_start': scheduleStart,
      'schedule_end': scheduleEnd,
      'active_days': activeDays.toList(),
      'strict_lock': strictLock,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  void reset() {
    fullName = '';
    age = null;
    focusPriority = 'Deep Work & Career Focus';
    dailyScreenTime = '3 - 4 hours';
    selectedCategories = {
      'Social Media & Feeds',
      'Endless Video & Streaming',
      'News & Infinite Browsers',
    };
    scheduleStart = '9:00 AM';
    scheduleEnd = '5:00 PM';
    activeDays = {'M', 'T', 'W', 'T2', 'F'};
    strictLock = true;
  }
}

