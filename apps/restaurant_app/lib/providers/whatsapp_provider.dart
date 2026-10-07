/// WhatsApp connection state for Settings + the requisition order screen.
///
/// Online-only read of the backend's per-business connection. A 404 (never
/// connected / disconnected) surfaces as null so the UI shows "Connect"
/// instead of an error.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/whatsapp_api_service.dart';
import 'inventory_api_provider.dart';
import 'permissions_provider.dart';

final whatsappApiServiceProvider = Provider<WhatsAppApiService>(
  (ref) => WhatsAppApiService(dio: ref.watch(inventoryServiceDioProvider)),
);

final whatsappConnectionProvider =
    FutureProvider.autoDispose<WhatsAppConnectionInfo?>((ref) async {
      final businessId = ref.watch(currentBusinessIdProvider);
      if (businessId == null) return null;
      return ref
          .watch(whatsappApiServiceProvider)
          .fetchConnection(businessId: businessId);
    });
