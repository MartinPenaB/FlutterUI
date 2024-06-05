import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Flask Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _response = '';
  File? _image;
  String _modifiedImage = '';

  Future<void> _sendString() async {
    final inputString = _controller.text;
    try {
      final response = await postRequest(inputString);
      setState(() {
        _response = response;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _sendImage(_image!);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _sendImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final response = await http.post(
      //Uri.parse('http://10.0.2.2:5000/modify_image'),
      //Uri.parse('http://192.168.2.32:5000/modify_image'),
      Uri.parse('http://martinpb.pythonanywhere.com/modify_image'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'image': base64Encode(bytes)}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _modifiedImage = response.body;
      });
    } else {
      print('Failed to send image to server');
    }
  }

  Future<String> postRequest(String inputString) async {
    final response = await http.post(
      //Uri.parse('http://10.0.2.2:5000/concat'),
      //Uri.parse('http://192.168.2.32:5000/concat'),
      Uri.parse('http://martinpb.pythonanywhere.com/concat'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'input_string': inputString}),
    );

    return response.statusCode == 200
        ? jsonDecode(response.body)['result']
        : 'Failed to connect to server';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Flask Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InputField(controller: _controller),
            const SizedBox(height: 20),
            ImageButton(onPressed: _getImage),
            const SizedBox(height: 20),
            SendButton(onPressed: _sendString),
            const SizedBox(height: 20),
            ResponseText(response: _response),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _image != null
                    ? Image.file(_image!, width: 150, height: 150)
                    : Container(),
                _modifiedImage.isNotEmpty
                    ? Image.memory(base64Decode(_modifiedImage),
                        width: 150, height: 150)
                    : Container(),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final TextEditingController controller;

  const InputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Enter a string'),
    );
  }
}

class SendButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SendButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Send to Flask'),
    );
  }
}

class ImageButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ImageButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Take Picture'),
    );
  }
}

class ResponseText extends StatelessWidget {
  final String response;

  const ResponseText({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Text(response, style: const TextStyle(fontSize: 24));
  }
}
