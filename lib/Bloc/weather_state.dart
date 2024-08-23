part of 'weather_bloc.dart';

@immutable
abstract class WeatherState {}

class WeatherInitial extends WeatherState {}
class WeatherblocLoading extends WeatherState{}
class WeatherblocLoadeded extends WeatherState{}
class WeatherblocError extends WeatherState{}
