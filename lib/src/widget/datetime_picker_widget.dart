import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../date_picker.dart';
import '../date_picker_constants.dart';
import '../date_picker_theme.dart';
import '../date_time_formatter.dart';
import '../i18n/date_picker_i18n.dart';
import 'date_picker_title_widget.dart';

/// DateTimePicker widget. Can display date and time picker.
///
/// @author dylan wu
/// @since 2019-05-10
class DateTimePickerWidget extends StatefulWidget {
  DateTimePickerWidget({
    Key key,
    this.minDateTime,
    this.maxDateTime,
    this.initDateTime,
    this.dateFormat = DATETIME_PICKER_TIME_FORMAT,
    this.locale = DATETIME_PICKER_LOCALE_DEFAULT,
    this.pickerTheme = DateTimePickerTheme.Default,
    this.minuteDivider = 1,
    this.onCancel,
    this.onChange,
    this.onConfirm,
  }) : super(key: key) {
    final DateTime minTime = minDateTime ?? DateTime.parse(DATE_PICKER_MIN_DATETIME);
    final DateTime maxTime = maxDateTime ?? DateTime.parse(DATE_PICKER_MAX_DATETIME);
    assert(minTime.compareTo(maxTime) < 0);
  }

  final DateTime minDateTime, maxDateTime, initDateTime;
  final String dateFormat;
  final DateTimePickerLocale locale;
  final DateTimePickerTheme pickerTheme;
  final DateVoidCallback onCancel;
  final DateValueCallback onChange, onConfirm;
  final int minuteDivider;

  @override
  State<StatefulWidget> createState() => _DateTimePickerWidgetState(
      minDateTime, maxDateTime, initDateTime, minuteDivider);
}

class _DateTimePickerWidgetState extends State<DateTimePickerWidget> {


  _DateTimePickerWidgetState(
      DateTime minTime, DateTime maxTime, DateTime initTime, int minuteDivider) {
    // check minTime value
      minTime ??= DateTime.parse(DATE_PICKER_MIN_DATETIME);
  
      maxTime ??= DateTime.parse(DATE_PICKER_MAX_DATETIME);
  
      initTime ??= DateTime.now();
    
    // limit initTime value
    if (initTime.compareTo(minTime) < 0) {
      initTime = minTime;
    }
    if (initTime.compareTo(maxTime) > 0) {
      initTime = maxTime;
    }

    _minTime = minTime;
    _maxTime = maxTime;
    _currHour = initTime.hour;
    _currMinute = initTime.minute;
    _currSecond = initTime.second;

    _minuteDivider = minuteDivider;

    // limit the range of date
    _dayRange = _calcDayRange();
    final int currDate = initTime.difference(_baselineDate).inDays;
    _currDay = min(max(_dayRange.first, currDate), _dayRange.last);

    // limit the range of hour
    _hourRange = _calcHourRange();
    _currHour = min(max(_hourRange.first, _currHour), _hourRange.last);

    // limit the range of minute
    _minuteRange = _calcMinuteRange();
    _currMinute =
        min(max(_minuteRange.first, _currMinute), _minuteRange.last);

    // limit the range of second
    _secondRange = _calcSecondRange();
    _currSecond =
        min(max(_secondRange.first, _currSecond), _secondRange.last);

    // create scroll controller
    _dayScrollCtrl =
        FixedExtentScrollController(initialItem: _currDay - _dayRange.first);
    _hourScrollCtrl =
        FixedExtentScrollController(initialItem: _currHour - _hourRange.first);
    _minuteScrollCtrl = FixedExtentScrollController(
        initialItem: (_currMinute - _minuteRange.first) ~/ _minuteDivider);
    _secondScrollCtrl = FixedExtentScrollController(
        initialItem: _currSecond - _secondRange.first);

    _scrollCtrlMap = {
      'H': _hourScrollCtrl,
      'm': _minuteScrollCtrl,
      's': _secondScrollCtrl
    };
    _valueRangeMap = {'H': _hourRange, 'm': _minuteRange, 's': _secondRange};
  }
  
  DateTime _minTime, _maxTime;
  int _currDay, _currHour, _currMinute, _currSecond;
  int _minuteDivider;
  List<int> _dayRange, _hourRange, _minuteRange, _secondRange;
  FixedExtentScrollController _dayScrollCtrl,
      _hourScrollCtrl,
      _minuteScrollCtrl,
      _secondScrollCtrl;

  Map<String, FixedExtentScrollController> _scrollCtrlMap;
  Map<String, List<int>> _valueRangeMap;

  bool _isChangeTimeRange = false;

  final DateTime _baselineDate = DateTime(1900, 1, 1);


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Material(
          color: Colors.transparent, child: _renderPickerView(context)),
    );
  }

  /// render time picker widgets
  Widget _renderPickerView(BuildContext context) {
    final Widget pickerWidget = _renderDatePickerWidget();

    // display the title widget
    if (widget.pickerTheme.title != null || widget.pickerTheme.showTitle) {
      final Widget titleWidget = DatePickerTitleWidget(
        pickerTheme: widget.pickerTheme,
        locale: widget.locale,
        onCancel: () => _onPressedCancel(),
        onConfirm: () => _onPressedConfirm(),
      );
      return Column(children: <Widget>[titleWidget, pickerWidget]);
    }
    return pickerWidget;
  }

  /// pressed cancel widget
  void _onPressedCancel() {
    if (widget.onCancel != null) {
      widget.onCancel();
    }
    Navigator.pop(context);
  }

  /// pressed confirm widget
  void _onPressedConfirm() {
    if (widget.onConfirm != null) {
      final DateTime day = _baselineDate.add(Duration(days: _currDay));
      final DateTime dateTime = DateTime(
          day.year, day.month, day.day, _currHour, _currMinute, _currSecond);
      widget.onConfirm(dateTime, _calcSelectIndexList());
    }
    Navigator.pop(context);
  }

  /// notify selected datetime changed
  void _onSelectedChange() {
    if (widget.onChange != null) {
      final DateTime day = _baselineDate.add(Duration(days: _currDay));
      final DateTime dateTime = DateTime(
          day.year, day.month, day.day, _currHour, _currMinute, _currSecond);
      widget.onChange(dateTime, _calcSelectIndexList());
    }
  }

  /// find scroll controller by specified format
  FixedExtentScrollController _findScrollCtrl(String format) {
    FixedExtentScrollController scrollCtrl;
    _scrollCtrlMap.forEach((key, value) {
      if (format.contains(key)) {
        scrollCtrl = value;
      }
    });
    return scrollCtrl;
  }

  /// find item value range by specified format
  List<int> _findPickerItemRange(String format) {
    List<int> valueRange;
    _valueRangeMap.forEach((key, value) {
      if (format.contains(key)) {
        valueRange = value;
      }
    });
    return valueRange;
  }

  /// render the picker widget of year、month and day
  Widget _renderDatePickerWidget() {
    final List<Widget> pickers = <Widget>[];
    final List<String> formatArr = DateTimeFormatter.splitDateFormat(
        widget.dateFormat,
        mode: DateTimePickerMode.datetime);
    final int count = formatArr.length;
    final int dayFlex = count > 3 ? count - 1 : count;

    // render day picker column
    final String dayFormat = formatArr.removeAt(0);
    final Widget dayPickerColumn = _renderDatePickerColumnComponent(
      scrollCtrl: _dayScrollCtrl,
      valueRange: _dayRange,
      format: dayFormat,
      valueChanged: (value) {
        _changeDaySelection(value);
      },
      flex: dayFlex,
      itemBuilder: (BuildContext context, int index) =>
          _renderDayPickerItemComponent(_dayRange.first + index, dayFormat),
    );
    pickers.add(dayPickerColumn);

    // render time picker column
    formatArr.forEach((format) {
      final List<int> valueRange = _findPickerItemRange(format);

      final Widget pickerColumn = _renderDatePickerColumnComponent(
        scrollCtrl: _findScrollCtrl(format),
        valueRange: valueRange,
        format: format,
        flex: 1,
        minuteDivider: widget.minuteDivider,
        valueChanged: (value) {
          if (format.contains('H')) {
            _changeHourSelection(value);
          } else if (format.contains('m')) {
            _changeMinuteSelection(value);
          } else if (format.contains('s')) {
            _changeSecondSelection(value);
          }
        },
      );
      pickers.add(pickerColumn);
    });
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: pickers);
  }

  Widget _renderDatePickerColumnComponent({
    @required FixedExtentScrollController scrollCtrl,
    @required List<int> valueRange,
    @required String format,
    @required ValueChanged<int> valueChanged,
    int minuteDivider,
    int flex,
    IndexedWidgetBuilder itemBuilder,
  }) {
    final Widget columnWidget = Container(
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      height: widget.pickerTheme.pickerHeight,
      decoration: BoxDecoration(color: widget.pickerTheme.backgroundColor),
      child: CupertinoPicker.builder(
        backgroundColor: widget.pickerTheme.backgroundColor,
        scrollController: scrollCtrl,
        itemExtent: widget.pickerTheme.itemHeight,
        onSelectedItemChanged: valueChanged,
        childCount: format.contains('m')
          ? _calculateMinuteChildCount(valueRange, minuteDivider)
          : valueRange.last - valueRange.first + 1,
        itemBuilder: (context, index) {
          int value = valueRange.first + index;

          if (format.contains('m')) {
            value = minuteDivider * index;
          }

          return _renderDatePickerItemComponent(value, format);
        },
      ),
    );
    return Expanded(
      flex: flex,
      child: columnWidget,
    );
  }

  dynamic _calculateMinuteChildCount(List<int> valueRange, int divider) {
    if (divider == 0) {
      print('Cant devide by 0');
      return valueRange.last - valueRange.first + 1;
    }

    return (valueRange.last - valueRange.first + 1) ~/ divider;
  }

  /// render day picker item
  Widget _renderDayPickerItemComponent(int value, String format) {
    final DateTime dateTime = _baselineDate.add(Duration(days: value));
    return Container(
      height: widget.pickerTheme.itemHeight,
      alignment: Alignment.center,
      child: Text(
        DateTimeFormatter.formatDate(dateTime, format, widget.locale),
        style:
            widget.pickerTheme.itemTextStyle ?? DATETIME_PICKER_ITEM_TEXT_STYLE,
      ),
    );
  }

  /// render hour、minute、second picker item
  Widget _renderDatePickerItemComponent(int value, String format) {
    return Container(
      height: widget.pickerTheme.itemHeight,
      alignment: Alignment.center,
      child: Text(
        DateTimeFormatter.formatDateTime(value, format, widget.locale),
        style:
            widget.pickerTheme.itemTextStyle ?? DATETIME_PICKER_ITEM_TEXT_STYLE,
      ),
    );
  }

  /// change the selection of day picker
  void _changeDaySelection(int days) {
    final int value = _dayRange.first + days;
    if (_currDay != value) {
      _currDay = value;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change the selection of hour picker
  void _changeHourSelection(int index) {
    final int value = _hourRange.first + index;
    if (_currHour != value) {
      _currHour = value;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change the selection of minute picker
  void _changeMinuteSelection(int index) {
    //  copied from time_picker_widget - this looks like it would break date ranges but not taking into account _minuteRange.first
    final int value = index * _minuteDivider;
//    int value = _minuteRange.first + index;
    if (_currMinute != value) {
      _currMinute = value;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change the selection of second picker
  void _changeSecondSelection(int index) {
    final int value = _secondRange.first + index;
    if (_currSecond != value) {
      _currSecond = value;
      _onSelectedChange();
    }
  }

  /// change range of minute and second
  void _changeTimeRange() {
    if (_isChangeTimeRange) {
      return;
    }
    _isChangeTimeRange = true;

    final List<int> hourRange = _calcHourRange();
    final bool hourRangeChanged = _hourRange.first != hourRange.first ||
        _hourRange.last != hourRange.last;
    if (hourRangeChanged) {
      // selected day changed
      _currHour = max(min(_currHour, hourRange.last), hourRange.first);
    }

    final List<int> minuteRange = _calcMinuteRange();
    final bool minuteRangeChanged = _minuteRange.first != minuteRange.first ||
        _minuteRange.last != minuteRange.last;
    if (minuteRangeChanged) {
      // selected hour changed
      _currMinute = max(min(_currMinute, minuteRange.last), minuteRange.first);
    }

    final List<int> secondRange = _calcSecondRange();
    final bool secondRangeChanged = _secondRange.first != secondRange.first ||
        _secondRange.last != secondRange.last;
    if (secondRangeChanged) {
      // second range changed, need limit the value of selected second
      _currSecond = max(min(_currSecond, secondRange.last), secondRange.first);
    }

    setState(() {
      _hourRange = hourRange;
      _minuteRange = minuteRange;
      _secondRange = secondRange;

      _valueRangeMap['H'] = hourRange;
      _valueRangeMap['m'] = minuteRange;
      _valueRangeMap['s'] = secondRange;
    });

    if (hourRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      final int currHour = _currHour;
      _hourScrollCtrl.jumpToItem(hourRange.last - hourRange.first);
      if (currHour < hourRange.last) {
        _hourScrollCtrl.jumpToItem(currHour - hourRange.first);
      }
    }

    if (minuteRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      final int currMinute = _currMinute;
      _minuteScrollCtrl.jumpToItem((minuteRange.last - minuteRange.first) ~/ _minuteDivider);
      if (currMinute < minuteRange.last) {
        _minuteScrollCtrl.jumpToItem(currMinute - minuteRange.first);
      }
    }

    if (secondRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      final int currSecond = _currSecond;
      _secondScrollCtrl.jumpToItem(secondRange.last - secondRange.first);
      if (currSecond < secondRange.last) {
        _secondScrollCtrl.jumpToItem(currSecond - secondRange.first);
      }
    }

    _isChangeTimeRange = false;
  }

  /// calculate selected index list
  List<int> _calcSelectIndexList() {
    final int hourIndex = _currHour - _hourRange.first;
    final int minuteIndex = _currMinute - _minuteRange.first;
    final int secondIndex = _currSecond - _secondRange.first;
    return [hourIndex, minuteIndex, secondIndex];
  }

  /// calculate the range of day
  List<int> _calcDayRange() {
    final int minDays = _minTime.difference(_baselineDate).inDays;
    final int maxDays = _maxTime.difference(_baselineDate).inDays;
    return [minDays, maxDays];
  }

  /// calculate the range of hour
  List<int> _calcHourRange() {
    int minHour = 0, maxHour = 23;
    if (_currDay == _dayRange.first) {
      minHour = _minTime.hour;
    }
    if (_currDay == _dayRange.last) {
      maxHour = _maxTime.hour;
    }
    return [minHour, maxHour];
  }

  /// calculate the range of minute
  List<int> _calcMinuteRange({int currHour}) {
    int minMinute = 0, maxMinute = 59;
    currHour ??= _currHour;

    if (_currDay == _dayRange.first && currHour == _minTime.hour) {
      // selected minimum day、hour, limit minute range
      minMinute = _minTime.minute;
    }
    if (_currDay == _dayRange.last && currHour == _maxTime.hour) {
      // selected maximum day、hour, limit minute range
      maxMinute = _maxTime.minute;
    }
    return [minMinute, maxMinute];
  }

  /// calculate the range of second
  List<int> _calcSecondRange({int currHour, int currMinute}) {
    int minSecond = 0, maxSecond = 59;

    currHour ??= _currHour;
    currMinute ??= _currMinute;

    if (_currDay == _dayRange.first &&
        currHour == _minTime.hour &&
        currMinute == _minTime.minute) {
      // selected minimum hour and minute, limit second range
      minSecond = _minTime.second;
    }
    if (_currDay == _dayRange.last &&
        currHour == _maxTime.hour &&
        currMinute == _maxTime.minute) {
      // selected maximum hour and minute, limit second range
      maxSecond = _maxTime.second;
    }
    return [minSecond, maxSecond];
  }
}
