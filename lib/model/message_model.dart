class MessageModel {
  final String sender;
  final String messageText;
  final int timestamp;
  bool read;
  final String messageType;
  final String room;
  MessageModel({
    required this.sender,
    required this.messageText,
    required this.timestamp,
    this.read = false,
    required this.messageType,
    required this.room,
  });

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'messageText': messageText,
      'timestamp': timestamp,
      'read': read,
      'messageType': messageType,
      'room':room,
    };
  }
}
