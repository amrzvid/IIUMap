import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> addHistoryToFirestore(HistoryModel history) async {
  DocumentReference ref = _firestore.collection('history').doc();
  String historyId = ref.id;
  await ref.set(history.toMap()..['historyId'] = historyId);
}

class HistoryModel {
  String uid;
  String location;
  DateTime timeStamp;
  String historyId;

  HistoryModel({
    required this.uid,
    required this.location,
    required this.timeStamp,
    required this.historyId,
  });

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      uid: map['uid'] ?? '',
      location: map['location'] ?? '',
      timeStamp: DateTime.parse(map['timeStamp'] ?? ''),
      historyId: map['historyId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'location': location,
      'timeStamp': timeStamp.toIso8601String(),
      'historyId': historyId,
    };
  }
}
