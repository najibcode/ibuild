import '../../data/models/bill_model.dart';

abstract class BillingRepository {
  Future<List<Bill>> getBills({
    String? projectId,
    String? statusFilter,
    String? sortBy,
    bool ascending = false,
    int limit = 20,
    int offset = 0,
  });
  Future<Bill?> getBillById(String id);
  Future<void> createBill(Bill bill);
  Future<void> updateBill(Bill bill);
  Future<void> deleteBill(String id);
}
