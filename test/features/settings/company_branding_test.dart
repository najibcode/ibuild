import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';

void main() {
  group('Company Branding & Letterhead Tests', () {
    setUp(() {
      OfflineDataCache().clear();
    });

    test('OfflineDataCache stores and retrieves company branding accurately', () {
      final branding = {
        'company_name': 'Apex Infra & Builders Ltd',
        'tagline': 'Building Tomorrow Today',
        'gstin': '29ABCDE1234F1Z5',
        'address': 'MG Road, Bengaluru, India',
        'upi_id': 'apexinfra@hdfc',
      };

      OfflineDataCache().cacheCompanyBranding(branding);
      final retrieved = OfflineDataCache().getCachedCompanyBranding();

      expect(retrieved, isNotNull);
      expect(retrieved!['company_name'], 'Apex Infra & Builders Ltd');
      expect(retrieved['tagline'], 'Building Tomorrow Today');
      expect(retrieved['gstin'], '29ABCDE1234F1Z5');
      expect(retrieved['address'], 'MG Road, Bengaluru, India');
      expect(retrieved['upi_id'], 'apexinfra@hdfc');
    });

    test('Overwriting company branding updates cache with latest changes', () {
      final initial = {
        'company_name': 'Initial Corp',
        'gstin': '000000000000000',
      };
      OfflineDataCache().cacheCompanyBranding(initial);

      final updated = {
        'company_name': 'Updated Corp',
        'tagline': 'High Rise Engineering',
        'gstin': '27ABCDE9999Z1Z5',
      };
      OfflineDataCache().cacheCompanyBranding(updated);

      final retrieved = OfflineDataCache().getCachedCompanyBranding();
      expect(retrieved!['company_name'], 'Updated Corp');
      expect(retrieved['tagline'], 'High Rise Engineering');
      expect(retrieved['gstin'], '27ABCDE9999Z1Z5');
    });
  });
}
