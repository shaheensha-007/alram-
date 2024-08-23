import 'dart:async';

import 'package:alaram_intergation/Api/weatherApi.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../Widgets/Tostmessage.dart';
import '../modelclass/WeaterModel.dart';

part 'weather_event.dart';
part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
late WeaterModel weaterModel;
WeatherApi weatherApi=WeatherApi();
  WeatherBloc() : super(WeatherInitial()) {
    on<FetchWeather>((event, emit) async{
      emit(WeatherblocLoading());
      try{

        weaterModel=await weatherApi.getTrendingWeather();
        emit(WeatherblocLoadeded());
         }catch(e){
        ToastMessage().toastmessage(message:e.toString());
        emit(WeatherblocError());
        print("*******$e");
        }
      // TODO: implement event handler
    });
  }
}