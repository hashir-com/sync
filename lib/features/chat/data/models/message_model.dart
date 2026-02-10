import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sync_event/features/chat/domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {

  const MessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.senderName,
    required super.receiverId,
    required super.text,
    super.imageUrl,
    required super.timestamp,
    super.isRead,
    super.messageType,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc, String chatId) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: chatId,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Someone',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      messageType: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['messageType']}',
        orElse: () => MessageType.text,
      ),
    );
  }

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      chatId: entity.chatId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      receiverId: entity.receiverId,
      text: entity.text,
      imageUrl: entity.imageUrl,
      timestamp: entity.timestamp,
      isRead: entity.isRead,
      messageType: entity.messageType,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
        'senderName': senderName,
  'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'messageType': messageType.toString().split('.').last,
    };
  }
}