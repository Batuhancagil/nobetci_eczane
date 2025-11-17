class MedicineReminder {
  final String name;
  final String? dose;
  final String mealTiming;
  final int timesPerDay;
  final int totalDays;
  final DateTime startDate;

  MedicineReminder({
    required this.name,
    required this.mealTiming,
    required this.timesPerDay,
    required this.totalDays,
    required this.startDate,
    this.dose,
  });
}
