import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TempChatWidget extends StatefulWidget {
  final String requestId;
  final String currentUid;
  final bool isDark;

  const TempChatWidget({
    super.key,
    required this.requestId,
    required this.currentUid,
    required this.isDark,
  });

  @override
  State<TempChatWidget> createState() => _TempChatWidgetState();
}

class _TempChatWidgetState extends State<TempChatWidget> {
  final TextEditingController _messageController = TextEditingController();

  // --- BLACKLIST INTERNA ---
  // Aggiungi qui tutte le radici delle parole che vuoi censurare
  final List<String> _blacklist = [
    'cazz',
    'merd',
    'stronz',
    'vaffancul',
    'bastard',
    'cretin',
    'deficient',
    'coglion',
    'troi',
    'puttan',
    'schif',
    'ebet',
    'fancul',
    'pirla',
    'idiot',
    'handicap',
    'gay',
    'ricchione',
    'frocio',
    'lesbica',
    'stupid',
    'omosessua',
    'sess'
  ];

  // --- LOGICA DI CENSURA ---
  String _filtraLinguaggio(String input) {
    String output = input;
    bool censurato = false;

    for (var parola in _blacklist) {
      final regExp = RegExp(parola, caseSensitive: false);
      if (output.contains(regExp)) {
        censurato = true;
        output = output.replaceAllMapped(regExp, (match) {
          return '*' * match.group(0)!.length;
        });
      }
    }

    if (censurato) {
      // Avviso l'utente che il messaggio è stato ripulito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Linguaggio moderato automaticamente."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return output;
  }

  void _sendMessage() async {
    String originalText = _messageController.text.trim();
    if (originalText.isEmpty) return;

    // Applico la censura prima di pulire il controller
    String cleanText = _filtraLinguaggio(originalText);

    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('exchange_requests')
        .doc(widget.requestId)
        .collection('messages')
        .add({
          'text': cleanText,
          'senderId': widget.currentUid,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "Chat Temporanea",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A7D91),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('exchange_requests')
                  .doc(widget.requestId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var m = docs[index].data() as Map<String, dynamic>;
                    bool isMe = m['senderId'] == widget.currentUid;
                    return _buildMessageBubble(m['text'] ?? '', isMe);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      color: widget.isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: "Invia un messaggio...",
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: widget.isDark ? Colors.white10 : Colors.white,
                    ),
                    onSubmitted: (_) =>
                        _sendMessage(), // Invia anche premendo Invio sulla tastiera
                  ),
                ),
                const SizedBox(width: 5),
                CircleAvatar(
                  backgroundColor: const Color(0xFF4A7D91),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF4A7D91)
              : (widget.isDark ? Colors.white12 : Colors.grey[300]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe
                ? Colors.white
                : (widget.isDark ? Colors.white : Colors.black),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
