// import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iiumap/const.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_iiumap/model/directions_model.dart';
// import 'package:flutter/foundation.dart';

class DirectionsRepository {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json?';

  final Dio _dio;

  DirectionsRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<Directions?> getDirections({
    @required LatLng? origin,
    @required LatLng? destination,
  }) async {
    final response = await _dio.get(
      _baseUrl,
      queryParameters: {
        'origin': '${origin!.latitude},${origin.longitude}',
        'destination': '${destination!.latitude},${destination.longitude}',
        'key': Secrets.API_KEY,
      },
    );

    if (response.statusCode == 200) {
      return Directions.fromMap(response.data);
    }

    return null;
  }
  
}