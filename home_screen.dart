import 'package:flutter/material.dart';
import 'package:otp_auth/model/history_model.dart';
import 'package:otp_auth/provider/auth_provider.dart';
import 'package:otp_auth/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<String> records = [];

  @override
  void initState() {
    super.initState();
  }

  void _openDialog() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _textController = TextEditingController();

        final formKey = GlobalKey<FormState>();

        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Navigate your way!"),
          content: Form(
            key: formKey,
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: "Enter record",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final ap = Provider.of<AuthProvider>(context, listen: false);
                String userId = ap.getUserModel.uid; // Get the user ID
                String record = _textController.text;

                HistoryModel history = HistoryModel(
                  uid: userId,
                  location: record,
                  timeStamp: DateTime.now(),
                );

                await addHistoryToFirestore(history); // Store the history in Firestore

                setState(() {
                  records.add(record); // Add the record to the local list
                });

                Navigator.pop(context);
              },
              child: const Text(
                "Add",
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
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
                      "Find your way to your destination",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 20),
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
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20.0),
                            color: Colors.red,
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              FirebaseFirestore.instance.collection('history').doc(history.uid).delete();
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
                                subtitle: Text("Time: ${history.timeStamp}", style: TextStyle(color: Colors.white)),
                                trailing: Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30),
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

        floatingActionButton: FloatingActionButton
        (
          onPressed: _openDialog,
          tooltip: "Add Dept Record",
          child: const Icon(Icons.search),
          backgroundColor: Colors.blue.shade50,
          foregroundColor: Colors.blue,
          shape: CircleBorder(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.blue,
          selectedItemColor: Colors.blue.shade50,
          unselectedItemColor: Colors.blue.shade900,
          showUnselectedLabels: false,
          selectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: "LiveTracker",
            ),
          ],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ));
  }
}
