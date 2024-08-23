import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../Bloc/weather_bloc.dart';
import '../modelclass/WeaterModel.dart';

class AlarmTimerSet extends StatefulWidget {
  const AlarmTimerSet({super.key});

  @override
  State<AlarmTimerSet> createState() => _AlarmTimerSetState();
}

class Alarm {
  int hour;
  int minute;
  String label;
  double latitude;
  double longitude;

  Alarm({
    required this.hour,
    required this.minute,
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

TextEditingController hoursController = TextEditingController();
TextEditingController minutesController = TextEditingController();
TextEditingController labelController = TextEditingController();

class _AlarmTimerSetState extends State<AlarmTimerSet> {
  late StreamSubscription subscription;
  var isDeviceConnected = false;
  bool isAlertSet = false;
  List<Alarm> alarms = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Detroit')); // Adjust timezone as needed
    _initializeNotificationPlugin();
    loadAlarms();
    getConnectivity();
  }

  Future<void> _initializeNotificationPlugin() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      alarms = (prefs.getStringList('alarms') ?? []).map((alarmString) {
        final parts = alarmString.split('|');
        return Alarm(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
          label: parts[2],
          latitude: double.parse(parts[3]),
          longitude: double.parse(parts[4]),
        );
      }).toList();
    });
  }

  Future<void> saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'alarms',
      alarms.map((alarm) => '${alarm.hour}|${alarm.minute}|${alarm.label}|${alarm.latitude}|${alarm.longitude}').toList(),
    );
  }

  void getConnectivity() {
    subscription = Connectivity().onConnectivityChanged.listen((result) async {
      isDeviceConnected = await InternetConnectionChecker().hasConnection;
      if (!isDeviceConnected && isAlertSet == false) {
        showDialogBox();
        setState(() => isAlertSet = true);
      }
    });
  }

  Future<void> createAlarm() async {
    String hourText = hoursController.text;
    String minuteText = minutesController.text;
    String labelText = labelController.text;

    int? hour = int.tryParse(hourText);
    int? minutes = int.tryParse(minuteText);

    if (hour != null && minutes != null) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);

      setState(() {
        alarms.add(Alarm(
          hour: hour,
          minute: minutes,
          label: labelText,
          latitude: position.latitude,
          longitude: position.longitude,
        ));
        FlutterAlarmClock.createAlarm(hour: hour, minutes: minutes);
      });
      await saveAlarms();

      // Schedule the notification
      _scheduleNotification(hour, minutes, labelText);
    } else {
      print('Invalid time entered');
    }
  }

  Future<void> _scheduleNotification(int hour, int minute, String label) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Channel for Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Alarm',
      label,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> deleteAlarm(int index) async {
    setState(() {
      alarms.removeAt(index);
    });
    await saveAlarms();
  }

  Future<void> editAlarm(int index) async {
    setState(() {
      Alarm alarm = alarms[index];
      hoursController.text = alarm.hour.toString();
      minutesController.text = alarm.minute.toString();
      labelController.text = alarm.label;

      alarms[index] = Alarm(
        hour: int.parse(hoursController.text),
        minute: int.parse(minutesController.text),
        label: labelController.text,
        latitude: alarm.latitude,  // Keep original latitude
        longitude: alarm.longitude, // Keep original longitude
      );
    });
    await saveAlarms();
  }

  void showDialogBox() => showCupertinoDialog<String>(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: const Text('No Connection'),
      content: const Text('Please check your internet connection'),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            Navigator.pop(context, 'Cancel');
            setState(() => isAlertSet = false);
            isDeviceConnected =
            await InternetConnectionChecker().hasConnection;
            if (!isDeviceConnected) {
              showDialogBox();
              setState(() => isAlertSet = true);
            }
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    var mheight=MediaQuery.of(context).size.height;
    var mwidth=MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alarm & Timer"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: <Widget>[
            const Text(
              'Set Alarm',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            SizedBox(
              height: mheight*0.05,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Hours'),
                const SizedBox(width: 10),
                SizedBox(
                  width:mwidth*0.1,
                  child: TextField(
                    controller: hoursController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: mwidth*0.02,
                ),
                const Text('Minutes'),
                const SizedBox(width: 10),
                SizedBox(
                  width: mwidth*0.1,
                  child: TextField(
                    controller: minutesController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Label'),
                const SizedBox(width: 10),
                SizedBox(
                  width: mwidth*0.15,
                  child: TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: mheight*0.05,
            ),
            ElevatedButton(
              onPressed: (){
                createAlarm();
                BlocProvider.of<WeatherBloc>(context).add(FetchWeather());
              },

              child: const Text('Create Alarm'),
            ),
       SizedBox(
         height: mheight*0.1,
       ),
            Expanded(
              child: ListView.builder(
                itemCount: alarms.length,
                itemBuilder: (context, index) {
                  final alarm = alarms[index];
                  return ListTile(
                    title: Text(
                      '${alarm.hour}:${alarm.minute.toString().padLeft(2, '0')} - ${alarm.label}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    subtitle:  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
    BlocBuilder<WeatherBloc, WeatherState>(
    builder: (context, state) {
      if (state is WeatherblocLoading) {
        CircularProgressIndicator();
      }
      if (state is WeatherblocLoadeded) {
        final country = BlocProvider
            .of<WeatherBloc>(context)
            .weaterModel
            .weather!.first.main;
        print("shaheen sha$country");
      return Text("current weather is ${country.toString()}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),);
    }
    if(state is WeatherblocError){
      return Text("internal issue");
    }else{
      return Container();
    }
    }
    ),

                        Text(
                          'Latitude: ${alarm.latitude}, Longitude: ${alarm.longitude}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            editAlarm(index);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            deleteAlarm(index);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
