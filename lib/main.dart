import 'dart:convert' as convert;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:passwordfield/passwordfield.dart';

void main() {
  runApp(const Login());
}

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VRClient',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: "VRChat client (Who's online?)"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class TwoFactorAuth extends StatefulWidget {
  const TwoFactorAuth({super.key, required this.title, required this.auth});

  final String title;
  final String auth;

  @override
  State<TwoFactorAuth> createState() => _TwoFactorAuth();
}

class Friends extends StatefulWidget {
  const Friends({super.key, required this.title, required this.auth});

  final String title;
  final String auth;

  @override
  State<Friends> createState() => _Friends();
}

class _Friends extends State<Friends> {

  List<String> onlineName = [];
  List<String> onlineStat = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInfo();
    });
    _fetchUsers();
  }

  Future<void> _handleRefresh() async {
    await _fetchUsers();
    setState(() {});
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Attention'),
          content: const Text(
              'Please pull down your finger on the screen to the refresh!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.white,
            backgroundColor: Colors.blue,
            child: ListView.builder(
              itemCount: onlineName.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(onlineName[index]),
                  subtitle: Text(onlineStat[index]),
                );
              },
            )));
  }

  Future<void> _fetchUsers() async {
    onlineName.clear();
    onlineStat.clear();
    final response = await http.get(
        Uri.parse(
            "https://api.vrchat.cloud/api/1/auth/user/friends?offline=false?n=100"),
        headers: {
          HttpHeaders.userAgentHeader:
              "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36",
          HttpHeaders.contentTypeHeader: "application/json",
          HttpHeaders.cookieHeader: widget.auth,
        });
    List<Map<String, dynamic>> userNames =
        json.decode(response.body).cast<Map<String, dynamic>>();

    for (var user in userNames) {
      if (user["location"].length > 10) {
        onlineStat.add("Joinable");
      } else {
        onlineStat.add(user["location"]);
      }
      onlineName.add(user["displayName"]);
    }
    return;
  }
}

class _TwoFactorAuth extends State<TwoFactorAuth> {
  var authController = TextEditingController();
  late var twoFa;
  var authJson;

  Future<void> _twoFreq() async {
    authJson = {"code": twoFa};
    final response = await http.post(
        Uri.parse(
            "https://api.vrchat.cloud/api/1/auth/twofactorauth/totp/verify"),
        body: convert.jsonEncode(authJson),
        headers: {
          HttpHeaders.userAgentHeader:
              "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36",
          HttpHeaders.contentTypeHeader: "application/json",
          HttpHeaders.cookieHeader: widget.auth,
        });
    if (response.statusCode == 200) {
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  Friends(title: "Friends list", auth: widget.auth)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: authController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                hintText: "Please give me the 2FA code!",
              ),
              onChanged: (v) {
                twoFa = authController.text;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: TextButton(
                style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.deepPurple)),
                onPressed: () async {
                  _twoFreq();
                },
                child: const Text("Hit it!"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late String username;
  late String password;

  var unameController = TextEditingController();
  var passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    unameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _myRequest() async {
    var usernameEncode = Uri.encodeFull(username);
    var passwordEncode = Uri.encodeFull(password);
    var uPass = "$usernameEncode:$passwordEncode";
    var bareAuth;
    var bareAuthSplitted;
    String credence = convert.base64.encode(convert.utf8.encode(uPass));
    final response = await http.get(
      Uri.parse("https://api.vrchat.cloud/api/1/auth/user"),
      headers: {
        HttpHeaders.userAgentHeader:
            "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36",
        HttpHeaders.authorizationHeader: 'Basic $credence',
      },
    );
    if (response.statusCode == 200) {
      bareAuth = response.headers['set-cookie'];
      bareAuthSplitted = bareAuth.split(";");
      var myAuth = bareAuthSplitted[0];

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                TwoFactorAuth(title: "2FA require", auth: myAuth)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Please enter your login information's",
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextField(
                controller: unameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter your Username",
                ),
                onChanged: (y) {
                  username = unameController.text;
                },
                //textInputAction: ,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: PasswordField(
                backgroundColor: Colors.white,
                controller: passwordController,
                errorMessage: 'Must contain special character',
                passwordConstraint: r'.*[@$#.*-:].*',
                passwordDecoration: PasswordDecoration(
                  inputPadding: const EdgeInsets.symmetric(horizontal: 10),
                  suffixIcon: const Icon(
                    Icons.not_accessible,
                    color: Colors.grey,
                  ),
                  inputStyle: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                hintText: 'Enter your Password',
                onChanged: (x) {
                  password = passwordController.text;
                },
                border: PasswordBorder(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide:
                        BorderSide(width: 2, color: Colors.red.shade200),
                  ),
                ),
              ),
            ),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                child: TextButton(
                  style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all(Colors.deepPurple),
                  ),
                  onPressed: () {
                    _myRequest();
                  },
                  child: const Text('Hit it!'),
                )),
          ],
        ),
      ),
    );
  }
}
