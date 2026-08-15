import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/app_content_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The content view is a support surface: a super-admin opens it to answer a
/// question about an owner's app. What matters is that a half-configured row —
/// no type, no shop, no price — still reads correctly rather than crashing the
/// list, because those are exactly the apps someone is asking about.
void main() {
  group('content summary', () {
    test('carries the counts and the app it belongs to', () {
      final summary = AppContentSummary.fromJson({
        'aupId': 42,
        'appName': 'Beirut Coffee House',
        'slug': 'opl42',
        'ownerName': 'Kassem Fawaz',
        'ownerEmail': 'k@build4all.net',
        'items': 37,
        'categories': 6,
        'customers': 412,
        'shops': 2,
        'orders': 158,
      });

      expect(summary.appName, 'Beirut Coffee House');
      expect(summary.items, 37);
      expect(summary.orders, 158);
      expect(summary.ownerEmail, 'k@build4all.net');
    });

    test('an empty app reports zeros', () {
      final summary = AppContentSummary.fromJson({'aupId': 7});

      expect(summary.items, 0);
      expect(summary.customers, 0);
      expect(summary.appName, isEmpty);
    });
  });

  group('catalogue rows', () {
    test('a fully configured item keeps its price, sale price, and shop', () {
      final item = AppItemRow.fromJson({
        'id': 1,
        'name': 'Ethiopian Yirgacheffe 250g',
        'sku': 'COF-ETH-250',
        'type': 'Product',
        'status': 'ACTIVE',
        'price': '18.50',
        'salePrice': '15.00',
        'stock': 42,
        'shopName': 'Hamra Branch',
      });

      expect(item.name, 'Ethiopian Yirgacheffe 250g');
      expect(item.salePrice, '15.00');
      expect(item.shopName, 'Hamra Branch');
      expect(item.stock, 42);
    });

    test('an item with no type, sku, or shop leaves those fields null', () {
      final item = AppItemRow.fromJson({
        'id': 2,
        'name': 'Barista Workshop',
        'sku': null,
        'type': null,
        'shopName': '',
        'price': '75.00',
      });

      expect(item.sku, isNull);
      expect(item.type, isNull);
      expect(item.shopName, isNull);
      expect(item.price, '75.00');
    });

    test('stock is distinguished between zero and not recorded', () {
      expect(AppItemRow.fromJson({'id': 1, 'stock': 0}).stock, 0);
      expect(AppItemRow.fromJson({'id': 1}).stock, isNull);
    });
  });

  group('customer rows', () {
    test('a verified customer keeps their contact details', () {
      final customer = AppCustomerRow.fromJson({
        'id': 11,
        'name': 'Rana Khoury',
        'email': 'rana@example.com',
        'phoneNumber': '+9613778899',
        'status': 'ACTIVE',
        'verified': true,
      });

      expect(customer.name, 'Rana Khoury');
      expect(customer.phoneNumber, '+9613778899');
      expect(customer.verified, isTrue);
    });

    test('a customer with no phone on record reads as null, not blank', () {
      final customer = AppCustomerRow.fromJson({
        'id': 12,
        'name': 'buyer_9',
        'email': 'b9@example.com',
        'phoneNumber': '',
        'verified': null,
      });

      expect(customer.phoneNumber, isNull);
      expect(customer.verified, isNull);
    });
  });
}
