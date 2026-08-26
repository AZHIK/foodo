import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

class ChatDialog extends ConsumerStatefulWidget {
  const ChatDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const ChatDialog(),
    );
  }

  @override
  ConsumerState<ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends ConsumerState<ChatDialog> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(chatMessagesProvider.notifier).addMessage(text, MessageRole.user);
    _controller.clear();

    Future.microtask(() {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final colors = context.colors;
    final isMobile = context.isMobile;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 450,
        height: isMobile ? MediaQuery.of(context).size.height * 0.7 : 600,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(Insets.lg),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Restaurant Assistant',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.onPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: Insets.lg),
                            Text(
                              'Start a conversation',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: Insets.sm),
                            Text(
                              'Ask me about orders, inventory, sales, and more',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(Insets.lg),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isUser = message.role == MessageRole.user;

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: Insets.md),
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Insets.md,
                                vertical: Insets.sm,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? colors.primary
                                    : colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message.content,
                                style: TextStyle(
                                  color: isUser
                                      ? colors.onPrimary
                                      : colors.onSurface,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(Insets.md),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.semantic.hairline),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Insets.md,
                          vertical: Insets.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.semantic.hairline,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.semantic.hairline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: Material(
                      color: colors.primary,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: colors.onPrimary,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
