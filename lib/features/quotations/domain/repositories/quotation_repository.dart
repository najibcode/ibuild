import '../../data/models/quotation_model.dart';

abstract class QuotationRepository {
  Future<List<Quotation>> getQuotations({
    String? statusFilter,
    String? projectId,
    int limit = 20,
    int offset = 0,
  });

  Future<Quotation> getQuotationById(String id);

  Future<Quotation> createQuotation(Quotation quotation);

  Future<Quotation> updateQuotation(Quotation quotation);

  Future<void> deleteQuotation(String id);
}
