import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'credits.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  TextEditingController _messageController = TextEditingController();
  TextEditingController _systemPromptController = TextEditingController();
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isBotTyping = false;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _initializeUnityAds();
    _waveController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _initializeUnityAds() async {
  await UnityAds.init(
    gameId: '5122862',
    onComplete: () => print('Initialization Complete'),
    onFailed: (error, message) =>
        print('Initialization Failed: $error $message'),
  );

  UnityAds.load(
    placementId: 'Interstitial_Android',
    onComplete: (placementId) {
      print('Load Complete $placementId');
      Future.delayed(Duration(seconds: 5), () {
        _showInterstitialAd();
      });
    },
    onFailed: (placementId, error, message) =>
        print('Load Failed $placementId: $error $message'),
  );
}

void _showInterstitialAd() {
  UnityAds.showVideoAd(
    placementId: 'Interstitial_Android',
    onStart: (placementId) => print('Video Ad $placementId started'),
    onClick: (placementId) => print('Video Ad $placementId click'),
    onSkipped: (placementId) => print('Video Ad $placementId skipped'),
    onComplete: (placementId) => print('Video Ad $placementId completed'),
    onFailed: (placementId, error, message) =>
        print('Video Ad $placementId failed: $error $message'),
  );
}

  void _loadChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      setState(() {
        _chatHistory = (prefs.getStringList('chatHistory') ?? []).map((e) {
          try {
            Map<String, dynamic> decodedMessage =
                jsonDecode(e) as Map<String, dynamic>;
            bool isUser = decodedMessage['isUser'] == true.toString();
            decodedMessage['isUser'] = isUser;
            return decodedMessage;
          } catch (error) {
            return <String, dynamic>{};
          }
        }).toList();
      });
    } catch (error) {
      print('Error loading chat history: $error');
    }
  }

  Future<void> sendMessage(String message, String systemPrompt) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? customInstructions = prefs.getString('customInstructions');

      setState(() {
        _chatHistory.add({'text': message, 'isUser': true});
        _isBotTyping = true; // Start typing animation
      });

      final response = await http.post(
        Uri.parse(
            'https://meta-llama-ai.onrender.com/predict'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'message': message,
          'system_prompt':
              customInstructions ?? systemPrompt,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          String responseText = jsonDecode(response.body);
          responseText = replaceEmojiText(responseText);
          _chatHistory.add({'text': responseText, 'isUser': false});
          _isBotTyping = false; // Stop typing animation
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print('Error sending message: $error');
    }
  }

  String replaceEmojiText(String text) {
    text = text.replaceAll('*smile*', '😊');
    text = text.replaceAll('*eyeroll*', '🙄');
    text = text.replaceAll('*thumbsup*', '👍');
    text = text.replaceAll('*thumbsdown*', '👎');
    text = text.replaceAll('*heart*', '❤️');
    text = text.replaceAll('*laugh*', '😂');
    text = text.replaceAll('*cry*', '😢');
    text = text.replaceAll('*angry*', '😠');
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('BRAIN'),
        leading: GestureDetector(
          onTap: () {
            showCupertinoModalPopup(
              context: context,
              builder: (BuildContext context) => CupertinoActionSheet(
                actions: <Widget>[
                  CupertinoActionSheetAction(
                    onPressed: () {
                      _clearChatHistory();
                      Navigator.pop(context);
                    },
                    child: Text('Delete chat history'),
                  ),
                  CupertinoActionSheetAction(
                    onPressed: () {
                      showCustomInstructionsModal(context);
                    },
                    child: Text('Custom instructions'),
                  ),
                  CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreditsScreen()),
                      );
                    },
                    child: Text('Credits'),
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Close'),
                ),
              ),
            );
          },
          child: Icon(CupertinoIcons.ellipsis),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final Map<String, dynamic> message = _chatHistory[index];
                  final bool isUser = message['isUser'];

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isUser ? CupertinoColors.lightBackgroundGray : CupertinoColors.activeBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MarkdownBody(
                            data: message['text'] ?? '',
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sent ${DateTime.now().toString()}',
                            style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Visibility(
              visible: _isBotTyping,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoTextField(
                      controller: _messageController,
                      placeholder: 'Type a message',
                      style: TextStyle(
                        color: CupertinoColors.black,
                        fontSize: 16,
                      ),
                      cursorColor: CupertinoColors.systemBlue,
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.send),
                    onPressed: () async {
                      try {
                        var userMessage = _messageController.text;
                        var systemPrompt = _systemPromptController.text;
                        if (userMessage.isNotEmpty) {
                          sendMessage(userMessage, systemPrompt);
                          _messageController.clear();
                        }
                      } catch (e) {
                        print(e.toString());
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearChatHistory() {
    setState(() {
      _chatHistory.clear();
    });
  }

  void showCustomInstructionsModal(BuildContext context) {
    _systemPromptController.text = '';
    _loadCustomInstructions();
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Custom Instructions'),
          content: CupertinoTextField(
            controller: _systemPromptController,
            placeholder: 'Enter system prompt',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                var systemPrompt = _systemPromptController.text;
                if (systemPrompt.isNotEmpty) {
                  Navigator.of(context).pop();
                  _saveCustomInstructions(systemPrompt);
                  _systemPromptController.clear();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _saveCustomInstructions(String systemPrompt) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('customInstructions', systemPrompt);
  }

  void _loadCustomInstructions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? customInstructions = prefs.getString('customInstructions');
    if (customInstructions != null && customInstructions.isNotEmpty) {
      _systemPromptController.text = customInstructions;
    }
  }
}

void main() {
  runApp(CupertinoApp(
    home: ChatPage(),
  ));
}
