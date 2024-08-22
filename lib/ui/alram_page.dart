import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/browser.dart';

class AlaramTimerSet extends StatefulWidget {
  const AlaramTimerSet({super.key});

  @override
  State<AlaramTimerSet> createState() => _AlaramTimerSetState();
}

TextEditingController hoursController = TextEditingController();
TextEditingController minutesController = TextEditingController();

class _AlaramTimerSetState extends State<AlaramTimerSet> with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String currentLocation = "Locating...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
    _loadSavedAlarm();
    getCurrentLocation(); // Fetch location on startup
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var mheight = MediaQuery.of(context).size.height;
    var mwidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: mheight * 0.1),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeInputField(controller: hoursController, width: mwidth * 0.2, height: mheight * 0.05),
                    SizedBox(width: mwidth * 0.05),
                    _buildTimeInputField(controller: minutesController, width: mwidth * 0.2, height: mheight * 0.05),
                  ],
                ),
              ),
              SizedBox(height: mheight * 0.05),
              Center(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        String hourText = hoursController.text;
                        String minuteText = minutesController.text;
                        int? hour = int.tryParse(hourText);
                        int? minutes = int.tryParse(minuteText);

                        if (hour != null && minutes != null) {
                          _saveAlarm(hour, minutes);
                          _scheduleAlarm(DateTime.now().add(Duration(hours: hour, minutes: minutes)));
                          FlutterAlarmClock.createAlarm(hour: hour, minutes: minutes);
                        } else {
                          print('Invalid time entered');
                        }
                      },
                      child: Text("Create Alarm", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                    SizedBox(height: mheight * 0.03),
                    ElevatedButton(
                      onPressed: () {
                        FlutterAlarmClock.showAlarms();
                      },
                      child: Text("Show Alarms", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    SizedBox(height: mheight * 0.05),
                    TextButton(
                      onPressed: () {
                        int? minutes = int.tryParse(minutesController.text);
                        if (minutes != null) {
                          FlutterAlarmClock.createTimer(length: minutes);
                          _scheduleTimer(minutes);
                        }
                      },
                      child: Text("Create Timer", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                    SizedBox(height: mheight * 0.03),
                    ElevatedButton(
                      onPressed: () {
                        FlutterAlarmClock.showTimers();
                      },
                      child: Text("Show Timers", style: TextStyle(fontSize: 17)),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimeInputField({required TextEditingController controller, required double width, required double height}) {
    return Container(
      height: height,
      width: width,
      color: Colors.grey,
      child: Padding(
        padding: EdgeInsets.only(left: width * 0.02),
        child: TextFormField(
          controller: controller,
          inputFormatters: [LengthLimitingTextInputFormatter(4)],
          keyboardType: TextInputType.datetime,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          decoration: InputDecoration(
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            hintStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _saveAlarm(int hour, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('alarm_hour', hour);
    prefs.setInt('alarm_minutes', minutes);
  }

  Future<void> _loadSavedAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    int? hour = prefs.getInt('alarm_hour');
    int? minutes = prefs.getInt('alarm_minutes');
    if (hour != null && minutes != null) {
      _scheduleAlarm(DateTime.now().add(Duration(hours: hour, minutes: minutes)));
    }
  }

  Future<void> _scheduleAlarm(DateTime scheduledNotificationDateTime) async {
    final TZDateTime tzDateTime = TZDateTime.from(scheduledNotificationDateTime,Location(name, transitionAt, transitionZone, zones));

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Channel for Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'alarm',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Alarm',
      'Your alarm is ringing',
      tzDateTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _scheduleTimer(int minutes) async {
    final TZDateTime scheduledNotificationDateTime =TZDateTime.now(Location(name, transitionAt, transitionZone, zones)).add(Duration(minutes: minutes));

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      channelDescription: 'Channel for Timer notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'timer',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Timer',
      'Your timer is up!',
      scheduledNotificationDateTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  Future<Position> getCurrentLocation()async{
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location disabled');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          currentLocation="${permission.name.toString();} lon:${permission.}"
        });
        return Future.error('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permission denied');
    }
    return await Geolocator.getCurrentPosition();
  }
}
