/// Submitted-order state: fetch one requisition with its per-supplier POs.
///
/// The just-submitted cart populates [requisitionCartProvider.lastSubmitted];
/// this family covers deep links, reloads, and returning later. Online-only,
/// like the purchases provider — no cache, direct API reads.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/requisition.dart';
import '../services/requisition_api_service.dart';
import 'permissions_provider.dart';
import 'requisition_cart_provider.dart';
import 'suppliers_provider.dart';

final requisitionOrderProvider = FutureProvider.autoDispose
    .family<SubmittedRequisition, String>((ref, requisitionId) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) throw StateError('No active business context');
  final json = await ref
      .watch(requisitionApiServiceProvider)
      .fetchRequisition(
          businessId: businessId, requisitionId: requisitionId);
  final names = {
    for (final s in ref.watch(suppliersListProvider)) s.id: s.name,
  };
  return submittedFromResponse(json, names);
});
