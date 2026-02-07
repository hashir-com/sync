import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sync_event/features/chat/data/models/chat_model.dart';
import 'package:sync_event/features/chat/data/models/chat_user_model.dart';
import 'package:sync_event/features/chat/data/models/message_model.dart';
import 'package:sync_event/features/chat/domain/entities/message_entity.dart';

abstract class ChatRemoteDataSource {
  String get currentUserId;
  Future<ChatUserModel?> getCurrentUser();
  Future<ChatUserModel?> getUserByUid(String uid);
  Future<String> createOrGetChat(String otherUserId);
  Stream<List<ChatModel>> getUserChats();
  Future<void> sendMessage({
    required String chatId,
    required String text,
    String? imageUrl,
    MessageType messageType,
  });
  Stream<List<MessageModel>> getChatMessages(String chatId);
  Future<void> markMessagesAsRead(String chatId);
  Future<void> deleteChat(String chatId);
  Future<List<ChatUserModel>> searchUsers(String query);
  Future<void> updateOnlineStatus(bool isOnline);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ChatRemoteDataSourceImpl({required this.firestore, required this.auth});

  @override
  String get currentUserId => auth.currentUser?.uid ?? '';

  @override
  Future<ChatUserModel?> getCurrentUser() async {
    try {
      final doc = await firestore
          .collection('users')
          .where('uid', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        return ChatUserModel.fromFirestore(doc.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  @override
  Future<ChatUserModel?> getUserByUid(String uid) async {
    try {
      final doc = await firestore
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        return ChatUserModel.fromFirestore(doc.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<String> createOrGetChat(String otherUserId) async {
    try {
      final existingChat = await firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in existingChat.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      final otherUser = await getUserByUid(otherUserId);
      final currentUser = await getCurrentUser();

      if (otherUser == null || currentUser == null) {
        throw Exception('User not found');
      }

      final chatRef = await firestore.collection('chats').add({
        'participants': [currentUserId, otherUserId],
        'participantDetails': {
          currentUserId: currentUser.toParticipantDetails(),
          otherUserId: otherUser.toParticipantDetails(),
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadCount': {currentUserId: 0, otherUserId: 0},
      });

      return chatRef.id;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  @override
  Stream<List<ChatModel>> getUserChats() {
    return firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList(),
        );
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String text,
    String? imageUrl,
    MessageType messageType = MessageType.text,
  }) async {
    try {

      final chatDoc = await firestore.collection('chats').doc(chatId).get();
      final chat = ChatModel.fromFirestore(chatDoc);
      final otherUserId = chat.participants.firstWhere(
        (id) => id != currentUserId,
      );
      final currentUser = await getCurrentUser();
      final senderName = currentUser?.name ?? 'Someone';

      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: currentUserId,
        senderName: senderName,
        receiverId: otherUserId, 
        text: text,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        messageType: messageType,
      );

      await firestore
    .collection('chats')
    .doc(chatId)
    .collection('messages')
    .add(message.toFirestore());


      

      await firestore.collection('chats').doc(chatId).update({
        'lastMessage': text.isEmpty ? '📷 Image' : text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
Stream<List<MessageModel>> getChatMessages(String chatId) {
  return firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc, chatId))
            .toList(),
      );
}


  @override
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final chatDoc = await firestore.collection('chats').doc(chatId).get();
      final unreadCount = Map<String, int>.from(
        chatDoc.data()?['unreadCount'] ?? {},
      );

      if (unreadCount[currentUserId] != null &&
          unreadCount[currentUserId]! > 0) {
        await firestore.collection('chats').doc(chatId).update({
          'unreadCount.$currentUserId': 0,
        });
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    try {
      final messages = await firestore
          .collection('messages')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  @override
  Future<List<ChatUserModel>> searchUsers(String query) async {
    try {
      final queryLower = query.toLowerCase();

      final nameResults = await firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: queryLower)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      final emailResults = await firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: queryLower)
          .where('email', isLessThanOrEqualTo: '$queryLower\uf8ff')
          .limit(20)
          .get();

      final allDocs = [...nameResults.docs, ...emailResults.docs];
      final uniqueUsers = <String, ChatUserModel>{};

      for (var doc in allDocs) {
        final user = ChatUserModel.fromFirestore(doc);
        if (user.uid != currentUserId) {
          uniqueUsers[user.uid] = user;
        }
      }

      return uniqueUsers.values.toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  @override
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final userDoc = await firestore
          .collection('users')
          .where('uid', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        await userDoc.docs.first.reference.update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update online status: $e');
    }
  }
}
