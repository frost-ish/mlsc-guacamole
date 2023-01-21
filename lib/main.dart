import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

void main() {
  runApp(SignInScreen());
  initFirebase();
}

Future<void> initFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FirstPage(),
    );
  }
}

class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 33, 3, 114),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 1,
                      child: Image.asset(
                        'assets/image1.png',
                        height: 160,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'MLSC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Authentication().signInWithGoogle().then(
                    (value) {
                      User? user = value.user;
                      updateOnDatabase(user!);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: ((context) {
                            return SecondPage(user!);
                          }),
                        ),
                      );
                    },
                  );
                },
                child: Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Authentication {
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}

Future<void> updateOnDatabase(User user) async {
  final databaseRef =
      FirebaseDatabase.instance.ref().child('Users').child(user.uid);
  databaseRef.child('Name').set(user.providerData[0].displayName);
}

class SecondPage extends StatelessWidget {
  User? user;
  SecondPage(User user) {
    this.user = user;
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color.fromARGB(255, 33, 3, 114),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(),
                Expanded(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Flexible(
                          flex: 1,
                          child: Image.asset(
                            'assets/image1.png',
                            height: 60,
                          ),
                        ),
                      ),
                      Text(
                        ('Welcome, ${user!.providerData[0].displayName!}'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      Spacer(),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: (() => showFilePicker(user!)),
                          child: Text(
                            'Upload your vaccination certificate',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showFilePicker(User user) async {
  FilePickerResult? result = await FilePicker.platform
      .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

  if (result != null) {
    File file = File(result.files.single.path!);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('VaccinationCertificates')
        .child('${user.uid}.pdf');
    await storageRef.putFile(file);
    final url = await storageRef.getDownloadURL();
    FirebaseDatabase.instance
        .ref()
        .child('Users')
        .child(user.uid)
        .child('VacCerf')
        .set(url);
  } else {
    // User canceled the picker
  }
}
