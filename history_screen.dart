import 'package:flutter/material.dart';
import 'package:flutter_iiumap/model/history_model.dart';
import 'package:flutter_iiumap/provider/auth_provider.dart';
import 'package:flutter_iiumap/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<String> records = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("IIUMap"),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
              onPressed: () async {
                ap.signOut().then(
                      (value) => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WelcomeScreen(),
                          ),
                          (route) => false),
                    );
              },
              icon: const Icon(Icons.logout),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.white),
              )),
        ],
      ),
      body: Center
        (
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Hello, ",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: "${ap.getUserModel.name}",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "See your recent location here.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 10),
                    Icon(
                      Icons.arrow_downward,
                      color: Color.fromARGB(255, 28, 145, 255),
                      size: 24.0,
                    ),
                  ],
                ),
              ),

              Text(
                      "Recent Location",
                      style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                    ),

              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('history')
                    .orderBy('timeStamp', descending: true)
                    .snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final history = HistoryModel.fromMap(snapshot.data!.docs[index].data() as Map<String, dynamic>);
                        return Dismissible(
                          key: Key(history.uid),
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(left: 20.0),
                            color: Colors.green,
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.person, color: Colors.white, size: 50.0), // Profile icon
                                SizedBox(width: 15), // Spacing between the icon and the text
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center, // Center the column
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      '${ap.getUserModel.name}', // User name
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${history.uid}', // User ID
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20.0),
                            color: Colors.red,
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              FirebaseFirestore.instance.collection('history').doc(history.uid).delete().catchError((error) {
                                print("Error deleting document: $error");
                              });
                            }
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 5,
                            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(75, 129, 230, 0.898),
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: Icon(Icons.location_on, color: Colors.white),
                                title: Text(
                                  history.location,
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "Time: ${DateFormat('kk:mm – dd-MM-yyyy').format(DateTime.parse(history.timeStamp.toString()))}", 
                                  style: TextStyle(color: Colors.white)
                                ),
                                trailing: GestureDetector(
                                  onTap: () {
                                    // Add your code here
                                  },
                                  child: Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      );
  }
}
