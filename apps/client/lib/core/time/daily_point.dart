/// One value attached to one day.
///
/// The unit every progress chart in the app is drawn from. It lives here
/// rather than beside the chart so a domain layer can produce a series
/// without importing a widget.
typedef DailyPoint = ({DateTime day, double value});
