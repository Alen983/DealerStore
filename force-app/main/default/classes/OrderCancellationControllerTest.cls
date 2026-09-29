@IsTest
private class OrderCancellationControllerTest {
    @IsTest
    static void getEligibilityReturnsMessageWhenOrderSummaryMissing() {
        Test.startTest();
        OrderCancellationController.EligibilityResult result =
            OrderCancellationController.getEligibility(null);
        Test.stopTest();

        System.assertEquals(false, result.canRequest);
        System.assertEquals('Order information is missing.', result.message);
    }

    @IsTest
    static void getEligibilityReturnsMessageWhenOrderSummaryNotFound() {
        Id fakeOrderSummaryId = buildFakeOrderSummaryId();

        Test.startTest();
        OrderCancellationController.EligibilityResult result =
            OrderCancellationController.getEligibility(fakeOrderSummaryId);
        Test.stopTest();

        System.assertEquals(false, result.canRequest);
        System.assertEquals(
            'We could not find this order for your account.',
            result.message
        );
    }

    @IsTest
    static void submitRequestValidatesAcknowledgment() {
        Id fakeOrderSummaryId = buildFakeOrderSummaryId();

        Test.startTest();
        OrderCancellationController.SubmitResult result =
            OrderCancellationController.submitRequest(
                fakeOrderSummaryId,
                'Duplicate order',
                'Please cancel this order.',
                false
            );
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(
            'Please confirm you understand the cancellation policy.',
            result.message
        );
    }

    @IsTest
    static void submitRequestValidatesReason() {
        Id fakeOrderSummaryId = buildFakeOrderSummaryId();

        Test.startTest();
        OrderCancellationController.SubmitResult result =
            OrderCancellationController.submitRequest(
                fakeOrderSummaryId,
                'Invalid reason',
                'Please cancel this order.',
                true
            );
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals('Please select a valid cancellation reason.', result.message);
    }

    @IsTest
    static void submitRequestReturnsNotFoundForUnknownOrder() {
        Id fakeOrderSummaryId = buildFakeOrderSummaryId();

        Test.startTest();
        OrderCancellationController.SubmitResult result =
            OrderCancellationController.submitRequest(
                fakeOrderSummaryId,
                'Pricing issue',
                'Need to cancel due to pricing.',
                true
            );
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(
            'We could not find this order for your account.',
            result.message
        );
    }

    private static Id buildFakeOrderSummaryId() {
        String prefix = '1Os';
        String suffix = '000000000000';

        if (Schema.OrderSummary.SObjectType.getDescribe().getKeyPrefix() != null) {
            prefix = Schema.OrderSummary.SObjectType.getDescribe().getKeyPrefix();
        }

        return (Id) JSON.deserialize(
            '"' + prefix + suffix + '"',
            Id.class
        );
    }
}
