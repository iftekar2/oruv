class OnboardingData {
  String fullName = '';
  int? age;
  String occupation = '';
  String focusPriority = 'Deep Work & Career Focus';
  String dailyScreenTime = '3 - 4 hours';
  bool screenTimeAuthorized = false;

  int nativeSelectedAppsCount = 0;
  int nativeSelectedCategoriesCount = 0;
  int nativeSelectedDomainsCount = 0;

  Set<String> selectedCategories = {};
  Set<String> selectedApps = {};

  String scheduleStart = '9:00 AM';
  String scheduleEnd = '5:00 PM';
  Set<String> activeDays = {'M', 'T', 'W', 'T2', 'F'};
  bool strictLock = true;

  static final OnboardingData instance = OnboardingData._internal();
  OnboardingData._internal();

  int get totalSelectedAppsCount {
    final nativeTotal = nativeSelectedAppsCount +
        nativeSelectedCategoriesCount +
        nativeSelectedDomainsCount;
    if (nativeTotal > 0 || screenTimeAuthorized) {
      return nativeTotal;
    }
    return selectedApps.length;
  }

  Map<String, dynamic> toMap() {
    return {
      ...toProfileMap(),
      'occupation': occupation,
    };
  }

  /// Exact column subset matching `public.profiles` in `supabase/schema.sql`.
  Map<String, dynamic> toProfileMap() {
    return {
      'full_name': fullName,
      'age': age,
      'focus_priority': focusPriority,
      'daily_screen_time': dailyScreenTime,
      'screen_time_authorized': screenTimeAuthorized,
      'selected_apps_count': nativeSelectedAppsCount,
      'selected_categories_count': nativeSelectedCategoriesCount,
      'selected_domains_count': nativeSelectedDomainsCount,
      'selected_categories': selectedCategories.toList(),
      'selected_apps': selectedApps.toList(),
      'schedule_start': scheduleStart,
      'schedule_end': scheduleEnd,
      'active_days': activeDays.toList(),
      'strict_lock': strictLock,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  void loadFromMap(Map<String, dynamic> map) {
    final name = map['full_name'];
    if (name is String && name.trim().isNotEmpty) {
      fullName = name.trim();
    }
    final rawOccupation = map['occupation'];
    if (rawOccupation is String && rawOccupation.trim().isNotEmpty) {
      occupation = rawOccupation.trim();
    }
    final rawAge = map['age'];
    if (rawAge is int) {
      age = rawAge;
    } else if (rawAge is num) {
      age = rawAge.toInt();
    }
    final priority = map['focus_priority'];
    if (priority is String && priority.isNotEmpty) {
      focusPriority = priority;
    }
    final screenTime = map['daily_screen_time'];
    if (screenTime is String && screenTime.isNotEmpty) {
      dailyScreenTime = screenTime;
    }
    if (map['screen_time_authorized'] is bool) {
      screenTimeAuthorized = map['screen_time_authorized'] as bool;
    }
    if (map['strict_lock'] is bool) {
      strictLock = map['strict_lock'] as bool;
    }
    final start = map['schedule_start'];
    if (start is String && start.isNotEmpty) {
      scheduleStart = start;
    }
    final end = map['schedule_end'];
    if (end is String && end.isNotEmpty) {
      scheduleEnd = end;
    }
    final days = map['active_days'];
    if (days is List && days.isNotEmpty) {
      activeDays = days.map((e) => e.toString()).toSet();
    }
  }

  void reset() {
    fullName = '';
    age = null;
    occupation = '';
    focusPriority = 'Deep Work & Career Focus';
    dailyScreenTime = '3 - 4 hours';
    screenTimeAuthorized = false;
    nativeSelectedAppsCount = 0;
    nativeSelectedCategoriesCount = 0;
    nativeSelectedDomainsCount = 0;
    selectedCategories = {};
    selectedApps = {};
    scheduleStart = '9:00 AM';
    scheduleEnd = '5:00 PM';
    activeDays = {'M', 'T', 'W', 'T2', 'F'};
    strictLock = true;
  }
}
