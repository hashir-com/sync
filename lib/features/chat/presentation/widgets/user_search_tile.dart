import 'package:flutter/material.dart';
import 'package:sync_event/features/chat/domain/entities/chat_user_entity.dart';

class UserSearchTile extends StatelessWidget {
  final ChatUserEntity user;
  final VoidCallback onTap;

  const UserSearchTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: user.image != null ? NetworkImage(user.image!) : null,
        child: user.image == null
            ? Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 18),
              )
            : null,
      ),
      title: Text(user.name),
      subtitle: Text(user.email),
      onTap: onTap,
    );
  }
}