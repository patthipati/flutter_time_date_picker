library flutter_time_date_picker;

export 'src/date_picker.dart';
export 'src/i18n/date_picker_i18n.dart';
export 'src/date_picker_theme.dart' show DateTimePickerTheme;
export 'src/widget/date_picker_widget.dart';
export 'src/widget/time_picker_widget.dart';
export 'src/widget/datetime_picker_widget.dart';

// import 'dart:async';

// import 'package:flutter/services.dart';

// class FlutterTimeDatePicker {
//   static const MethodChannel _channel =
//       const MethodChannel('flutter_time_date_picker');

//   static Future<String> get platformVersion async {
//     final String version = await _channel.invokeMethod('getPlatformVersion');
//     return version;
//   }
// }
