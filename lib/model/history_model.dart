import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> addHistoryToFirestore(HistoryModel history) async {
  await _firestore.collection('history').add(history.toMap());
}


class HistoryModel {
  String uid;
  String location;
  DateTime timeStamp;

  HistoryModel({
    required this.uid,
    required this.location,
    required this.timeStamp,
  });

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      uid: map['uid'] ?? '',
      location: map['location'] ?? '',
      timeStamp: DateTime.parse(map['timeStamp'] ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'location': location,
      'timeStamp': timeStamp.toIso8601String(),
    };
  }
}
