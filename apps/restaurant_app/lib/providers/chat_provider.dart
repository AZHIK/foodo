import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';

final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  void addMessage(String content, MessageRole role) {
    const uuid = Uuid();
    final message = ChatMessage(
      id: uuid.v4(),
      content: content,
      role: role,
      timestamp: DateTime.now(),
    );
    state = [...state, message];

    if (role == MessageRole.user) {
      Future.delayed(const Duration(milliseconds: 500), () {
        addMessage(_getBotResponse(content), MessageRole.assistant);
      });
    }
  }

  String _getBotResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('hello') || message.contains('hi')) {
      return 'Hello! 👋 How can I help you today? You can ask me about orders, inventory, sales, staff, or anything else.';
    }

    if (message.contains('order')) {
      return 'You can view and manage orders in the Sales section. Check the current orders, view order details, and track payments.';
    }

    if (message.contains('inventory') || message.contains('stock')) {
      return 'Go to the Inventory section to check stock levels, add new items, adjust quantities, or view low stock alerts.';
    }

    if (message.contains('staff') || message.contains('employee')) {
      return 'In the Staff section, you can manage team members, assign roles, view activity logs, and track staff hours.';
    }

    if (message.contains('finance') || message.contains('expense') || message.contains('income')) {
      return 'The Finance section shows income and expenses. You can track ad-hoc income, record expenses, and view financial reports.';
    }

    if (message.contains('sale') || message.contains('revenue') || message.contains('sales')) {
      return 'Check the Sales dashboard to see your sales trends, order history, and revenue metrics over time.';
    }

    if (message.contains('help') || message.contains('support')) {
      return 'I can help you with: Orders, Inventory, Staff, Finance, Sales analytics, and POS operations. What would you like to know?';
    }

    if (message.contains('thank')) {
      return 'You\'re welcome! 😊 Feel free to ask if you need anything else.';
    }

    return 'I can help you with POS operations, inventory management, staff coordination, sales tracking, and financial reports. What would you like to know?';
  }

  void clearMessages() {
    state = [];
  }
}
