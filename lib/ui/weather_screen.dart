import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather_app/secrets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


class WeatherScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const WeatherScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {

  late Future weatherFuture;
  String cityName = "";

  Future getCurrentWeather() async{
    try{
      String name = await getCityNameFromLocation();

      setState(() {
        cityName = name;
      });

      String url = "https://api.openweathermap.org/data/2.5/forecast?q=$name&APPID=$openWeatherAPIKey";
      final res = await http.get(Uri.parse(url));
      print(url);

      final data = jsonDecode(res.body);
      // print("---------------->>$data");
      if(data['cod'] == '200'){
        return data;
      }
      else{
        throw Text(data['message']);
      }
    }
    catch(e){
      throw e.toString();
    }
  }

  Future<String> getCityNameFromLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    // Request permission if not granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      return placemarks.first.locality ?? 'Unknown City';
    } else {
      throw Exception('Could not determine city name.');
    }
  }

  @override
  void initState() {
    super.initState();
    weatherFuture = getCurrentWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("Welcome Ritik")),
            ListTile(leading: Icon(Icons.home),title: Text("Home")),
            ListTile(leading: Icon(Icons.settings),title: Text("Setting")),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
            cityName,
          style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.normal)
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: (){
                setState(() {
                  weatherFuture = getCurrentWeather();
                });
              },
              icon: Icon(Icons.refresh)
          ),
          IconButton(
              onPressed:widget.onToggleTheme,
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
        ],
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(Icons.menu),
          ),
        ),
      ),

      body:FutureBuilder( // Creates a widget that builds itself based on the latest snapshot of interaction with a Future.
        future: weatherFuture, // this is the future: on the basis of latest interaction new widget is created.
        builder: (context, snapshot){
          print(snapshot);
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(
                child: const CircularProgressIndicator.adaptive()
            );
          }
          if(snapshot.hasError){
            return Center(child: Text(snapshot.error.toString()));
          }
          final data = snapshot.data!;

          final currentWeatherData = data['list'][0];

          final currentTemp = currentWeatherData['main']['temp'];
          final currentSky = currentWeatherData['weather'][0]['main'];
          final iconCode = currentWeatherData['weather'][0]['icon'];
          final iconUrl = "https://openweathermap.org/img/wn/$iconCode@2x.png";

          final currentHumidity = currentWeatherData['main']['humidity'];
          final currentWindSpeed = currentWeatherData['wind']['speed'];
          final currentPressure = currentWeatherData['main']['pressure'];

          return SingleChildScrollView(
            child: Padding (
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1.main card
                  SizedBox( // height depends on the given cardWidget.
                    width: double.infinity,
                    child: CardWidget(
                        temperature: "${(currentTemp-273.15).toStringAsFixed(2)}°C",
                        iconUrl: iconUrl,
                        description: currentSky
                    ),
                  ),
                  // 2.HourlyWeather forecast card
                  SizedBox(height: 8),
                  const Text(
                    "Hourly Forecast",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  // SingleChildScrollView(
                  //   scrollDirection: Axis.horizontal,
                  //   child: Row(
                  //     children: [
                  //       for(int i = 1;i<data['list'].length;i++)
                  //         HourlyForecastItem(
                  //             time:data['list'][i]['dt_txt'],
                  //             icon: icon,
                  //             temperature: "${(data['list'][i]['main']['temp']-273.15).toStringAsFixed(2)}°C"
                  //         ),
                  //     ],
                  //   ),
                  // ),

                  // The Above Code has performance issue: Since we are running a loop and in each iteration, widget is build
                  // So, We want to build widget only when user scroll the view. -> ListView.builder is like a RecyclerView
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5, //data['list'].length,
                        itemBuilder: (context, index){
                          final hourlyForecast = data['list'][index+1];
                          final time = DateTime.parse(hourlyForecast['dt_txt']);
                          return  HourlyForecastItem(
                              time:DateFormat.j().format(time),
                              iconUrl: iconUrl,
                              temperature: "${(hourlyForecast['main']['temp']-273.15).toStringAsFixed(2)}°C"
                          );
                        }
                    ),
                  ),

                  // 3.Additional information card
                  SizedBox(height: 8),
                  const Text(
                    "Additional Information",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AdditionalInfoItem(icon:Icons.water_drop, label:"Humidity",value:currentHumidity.toString()),
                      AdditionalInfoItem(icon:Icons.air, label:"Wind Speed",value:currentWindSpeed.toString()),
                      AdditionalInfoItem(icon:Icons.beach_access, label:"Pressure",value:currentPressure.toString()),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  final String temperature;
  final String iconUrl;
  final String description;

  const CardWidget({
    super.key,
    required this.temperature,
    required this.iconUrl,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,sigmaY: 10
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(temperature, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                SizedBox(height: 14),
                CachedNetworkImage(
                  imageUrl: iconUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                SizedBox(height: 14),
                Text(description, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HourlyForecastItem extends StatelessWidget {
  final String time;
  final String iconUrl;
  final String temperature;

  const HourlyForecastItem({
    super.key,
    required this.time,
    required this.iconUrl,
    required this.temperature
  });

  @override
  Widget build(BuildContext context) {
    return  Card(
      elevation: 0,
      child: Container(
        width: 120,
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12)
        ),
        child: Column(
          children: [
            Text(time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            CachedNetworkImage(
              imageUrl: iconUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => const SizedBox(
                width: 60,
                height: 60,
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            const SizedBox(height: 6),
            Text(temperature, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class AdditionalInfoItem extends StatelessWidget {

  final IconData icon;
  final String label;
  final String value;

  const AdditionalInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return  Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: 8),
        Text(label),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
