import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDcZNOpcBLXDjhgvgooqS5haOkpMbhJcZI",
      authDomain: "carlo-7b72f.firebaseapp.com",
      projectId: "carlo-7b72f",
      storageBucket: "carlo-7b72f.appspot.com",
      messagingSenderId: "501973736962",
      appId: "1:501973736962:web:6e063da2df78c58f45911b",
    ),
  );

  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Selected file in String name to display file name
  String selectedFile = '';

  // Selected File in Bytes
  Uint8List? fileInBytes;

  // NO NEED since nag pdfview network tayo
  //
  // Placeholder for the uploaded file from storage
  // Uint8List? uploadedImage;

  // Loading State when uploading file
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  // Function to select a file
  void _selectFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = result.files.first.name;
        fileInBytes = result.files.first.bytes;
      });
    }
  }

  // NO NEED since nag pdfview network tayo
  //
  // Function to get the pdf from a firebase storage download url
  // void getPdfBytes(String url) async {
  //   if (kIsWeb) {
  //     // Create a reference to the file
  //     Reference pdfRef = FirebaseStorage.instanceFor().refFromURL(url);
  //     debugPrint("pdfRef: $pdfRef");
  //     await pdfRef.getData().then((value) {
  //       // Set the uploaded image to the value returned from getData
  //       uploadedImage = value;

  //       // Update the UI
  //       setState(() {});
  //     });
  //   }
  // }

  // Function to upload a file to Firebase Storage and save the URL to Firestore
  Future<void> uploadFileAndSaveUrl(Uint8List fileData, String fileName) async {
    // Set the loading state to true
    setState(() {
      isLoading = true;
    });

    // Create a reference to the location you want to upload to in Firebase Storage
    final storageReference =
        FirebaseStorage.instance.ref().child('files').child(fileName);

    // Sets a metadata to the file of type PDF so that it can be viewed in the browser
    // instead na ma download
    final metadata = SettableMetadata(
      contentType: 'application/pdf',
    );

    // Upload the file to Firebase Storage
    UploadTask uploadTask = storageReference.putData(fileData, metadata);

    // Wait for the upload to complete
    final snapshot = await uploadTask;

    // Get the download URL
    String fileUrl = await snapshot.ref.getDownloadURL();

    // Print the download URL for testing
    debugPrint(fileUrl);

    // Save the URL to Firestore
    await FirebaseFirestore.instance.collection('files').add({
      'fileName': fileName,
      'fileUrl': fileUrl,
    });

    // Set the loading state to false
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Add a outlined button to pick a file and display the file name
                  OutlinedButton(
                    onPressed: _selectFile,
                    child: const Text('Pick a file'),
                  ),

                  // Display the file name
                  Text(selectedFile == '' ? 'example.pdf' : selectedFile),
                  Text(fileInBytes != null
                      ? 'File selected'
                      : 'No file selected'),

                  // Add a outlined button to upload the file
                  OutlinedButton(
                    onPressed: () {
                      if (fileInBytes != null) {
                        uploadFileAndSaveUrl(fileInBytes!, selectedFile);
                      }
                    },
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator())
                        : const Text('Upload File'),
                  ),

                  // Display the PDF in a bottom sheet
                  ElevatedButton(
                    onPressed: () {
                      showPDFInBottomSheet(context,
                          "https://firebasestorage.googleapis.com/v0/b/flutterfirebase-6c279.appspot.com/o/GIS.pdf?alt=media&token=51654170-c140-4ffa-ae1a-9fb431d0dee2");
                    },
                    child: const Text('Show Sample pdf in Bottom Sheet'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection('files').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (!snapshot.hasData) {
                    return const Text('No data');
                  }

                  final documents = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final document = documents[index];
                      final data = document.data();

                      return ListTile(
                        title: Text(data['fileName']),
                        subtitle: Text(data['fileUrl']),
                        onTap: () {
                          showPDFInBottomSheet(context, data['fileUrl']);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showPDFInBottomSheet(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      // for full screen
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('PDF Viewer'),
            ),
            body: SfPdfViewer.network(
              url,
            ),
          ),
        );
      },
    );
  }
}
