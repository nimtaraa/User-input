import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class test1 extends StatefulWidget {
  const test1({Key? key});

  @override
  State<test1> createState() => _test1State();
}

class _test1State extends State<test1> {
  XFile? _imageFile;
  String? _imageUrl;
  final name = TextEditingController();

  Future<void> pickImage() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile =
          await imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      } else {
        print('No image selected.');
      }
    } catch (error) {
      print('Error picking image: $error');
      print('An error occurred while picking an image.');
    }
  }

  Future<void> uploadImageToFirebaseStorage() async {
    try {
      if (_imageFile == null) return;

      final firebase_storage.Reference storageRef =
          firebase_storage.FirebaseStorage.instance.ref().child('images');

      final String imageName = DateTime.now().millisecondsSinceEpoch.toString();
      final firebase_storage.UploadTask uploadTask =
          storageRef.child(imageName).putFile(File(_imageFile!.path));

      final firebase_storage.TaskSnapshot downloadSnapshot =
          await uploadTask.whenComplete(() => null);

      final String downloadUrl = await downloadSnapshot.ref.getDownloadURL();

      setState(() {
        _imageUrl = downloadUrl;
      });
    } catch (error) {
      print('Error uploading image to Firebase Storage: $error');
    }
  }

  void _addToFirestore(String text, String img) async {
    try {
      await FirebaseFirestore.instance.collection('ads').add({
        'name': text,
        'img': img,
        // add more fields as needed
      });
      name.clear();
      setState(() {
        _imageFile = null; // Clear the image after upload
      });
    } catch (e) {
      print('Error adding to Firestore: $e');
      // Handle error accordingly
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                pickImage();
              },
              child: Container(
                height: 100,
                width: 200,
                decoration: BoxDecoration(color: Colors.amber),
                child: _imageFile != null
                    ? Image.file(File(_imageFile!.path)) // Use Image.file instead of Image.network
                    : Icon(Icons.add_a_photo),
              ),
            ),
            TextField(
              controller: name,
              decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2))),
            ),
            ElevatedButton(
              onPressed: () async {
                await uploadImageToFirebaseStorage();
                String text = name.text.trim();
                String img = _imageUrl ?? ""; // Use _imageUrl if available
                _addToFirestore(text, img);
              },
              child: Text("Save"),
            ),
            Container(
                          height: 300,
                          child: StreamBuilder(
                            stream:FirebaseFirestore.instance.collection("ads").snapshots(),
                            builder: (context, snapshot) {
                              if(snapshot.hasError){
                                return Text("Connection Error");
                              }
                              if(snapshot.connectionState==ConnectionState.waiting){
                                return Text("Loading....");
                              }
                              var newdetailsdocs=snapshot.data!.docs;
                 
                              return  ListView.builder(
 
                                     itemCount: newdetailsdocs.length,
                                     itemBuilder: (context, index) {
                                          Map<String, dynamic> data = newdetailsdocs[index].data() as Map<String, dynamic>;
                                                   String name = data['name'] ?? '';
    String imgUrl = data['img'] ?? '';
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(name),
        leading: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imgUrl),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
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
}
