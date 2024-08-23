import 'dart:convert';


import 'package:http/http.dart';


import '../modelclass/WeaterModel.dart';
import 'api_client.dart';



class WeatherApi{


  ApiClient apiClient = ApiClient();
  String trendingpath = 'http://api.openweathermap.org/data/2.5/weather?q=kochi&appid=a3d6bb09c7275dfb4f02100d5f59bb04';


  Future<WeaterModel> getTrendingWeather() async {



    Response response = await apiClient.invokeAPI(trendingpath, 'GET_', null);

    return WeaterModel.fromJson(jsonDecode(response.body));


  }


}