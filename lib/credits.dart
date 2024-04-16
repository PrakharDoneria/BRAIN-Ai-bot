import 'package:flutter/cupertino.dart';

class CreditsScreen extends StatefulWidget {
  @override
  _CreditsScreenState createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10), // Adjust duration as needed
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.repeat(reverse: true); // Auto-scroll animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Credits'),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCreditItem('Bot Name:', 'BRAIN'),
              _buildCreditItem(
                'Powered by:',
                'Llama, an open-source chatbot developed by Meta (formerly Facebook). '
                'The bot code was taken from Hugging Face and fine-tuned for various tasks.',
              ),
              _buildCreditItem('Creator/Developer:', 'Prakhar Doneria'),
              _buildCreditItem('Company:', 'ProTec Games'),
              _buildCreditItem(
                'Purpose:',
                'The BRAIN bot was designed to assist users in various tasks, engage in conversation, and provide helpful information. '
                'It aims to enhance user experience and offer valuable assistance in different domains.',
              ),
              _buildCreditItem(
                'Acknowledgments:',
                'Special thanks to the Llama community, Meta (Facebook), Hugging Face, and all contributors who made this project possible. '
                'Their dedication and contributions are greatly appreciated. Emojis provided by the emojis package. '
                'Data serialization and deserialization provided by the dart:convert package.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
