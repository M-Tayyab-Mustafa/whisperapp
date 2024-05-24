import 'message_model.dart';

class ChatModel {
  String chatId;
  final List<String> members;
  final List<MessageModel> messages;

  ChatModel({
    required this.chatId,
    required this.members,
    required this.messages,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'members': members,
      'messages': messages.map((message) => message.toMap()).toList(),
    };
  }
}
