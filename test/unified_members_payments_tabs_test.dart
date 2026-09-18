import 'package:c_h_o_l_o_t_o_dashboard/payments/payment_reviews_widget.dart';
import 'package:c_h_o_l_o_t_o_dashboard/payments/payment_transactions_widget.dart';
import 'package:c_h_o_l_o_t_o_dashboard/users/users_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unified Members & Payments Tabs', () {
    test('UsersWidget default constructor sets initialTabIndex to 0', () {
      const widget = UsersWidget();
      expect(widget.initialTabIndex, 0);
      expect(UsersWidget.routeName, 'users');
      expect(UsersWidget.routePath, '/users');
    });

    test('UsersWidget accepts custom initialTabIndex', () {
      const widget1 = UsersWidget(initialTabIndex: 1);
      expect(widget1.initialTabIndex, 1);

      const widget2 = UsersWidget(initialTabIndex: 2);
      expect(widget2.initialTabIndex, 2);
    });

    testWidgets(
      'PaymentReviewsWidget builds UsersWidget with initialTabIndex: 1',
      (tester) async {
        late Widget builtWidget;
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              builtWidget = const PaymentReviewsWidget().build(context);
              return const SizedBox();
            },
          ),
        );

        expect(builtWidget, isA<UsersWidget>());
        expect((builtWidget as UsersWidget).initialTabIndex, 1);
      },
    );

    testWidgets(
      'PaymentTransactionsWidget builds UsersWidget with initialTabIndex: 2',
      (tester) async {
        late Widget builtWidget;
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              builtWidget = const PaymentTransactionsWidget().build(context);
              return const SizedBox();
            },
          ),
        );

        expect(builtWidget, isA<UsersWidget>());
        expect((builtWidget as UsersWidget).initialTabIndex, 2);
      },
    );

    test('Route names and paths are preserved for backward compatibility', () {
      expect(PaymentReviewsWidget.routeName, 'PaymentReviews');
      expect(PaymentReviewsWidget.routePath, '/payment-reviews');

      expect(PaymentTransactionsWidget.routeName, 'PaymentTransactions');
      expect(PaymentTransactionsWidget.routePath, '/payments');
    });
  });
}
