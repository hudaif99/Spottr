import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<TimeOfDay?> showWorkoutTimePicker(
  BuildContext context,
  TimeOfDay initialTime,
) {
  if (Theme.of(context).platform != TargetPlatform.iOS) {
    return showTimePicker(context: context, initialTime: initialTime);
  }
  var value = DateTime(2000, 1, 1, initialTime.hour, initialTime.minute);
  return showCupertinoModalPopup<TimeOfDay>(
    context: context,
    builder: (context) => Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 260,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton(
                    onPressed: () =>
                        Navigator.pop(context, TimeOfDay.fromDateTime(value)),
                    child: const Text('Done'),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: value,
                  use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                  onDateTimeChanged: (date) => value = date,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
