/// AlAdhan calculation method — hardcoded mapping, `/methods` is never
/// called (specs/002-home-page/contracts/prayer_times_api.md).
enum CalculationMethod {
  ummAlQura('umm_al_qura', 4),
  isna('isna', 2),
  mwl('mwl', 3);

  const CalculationMethod(this.storedValue, this.alAdhanId);

  final String storedValue;
  final int alAdhanId;

  /// Default when nothing has been stored yet — research.md §4.
  static const CalculationMethod fallback = CalculationMethod.ummAlQura;

  static CalculationMethod fromStoredValue(String? value) {
    return CalculationMethod.values.firstWhere(
      (m) => m.storedValue == value,
      orElse: () => fallback,
    );
  }
}
