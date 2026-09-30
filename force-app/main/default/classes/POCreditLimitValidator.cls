public class POCreditLimitValidator extends CartExtension.CheckoutPlaceOrder {

    public override CartExtension.PlaceOrderResponse validate(
        CartExtension.PlaceOrderRequest request,
        List<String> domainList
    ) {
        System.debug('=== PO CREDIT VALIDATOR INVOKED ===');

        // Get the current checkout cart
        CartExtension.Cart cart = request.getCart();

        // Get cart total
        Decimal cartTotal = cart.getGrandTotalAmount();

        // Get dealer account
        Id accountId = cart.getAccountId();

        System.debug('=== CART ID: ' + cart.getId() + ' ===');
        System.debug('=== ACCOUNT ID: ' + accountId + ' ===');
        System.debug('=== CART GRAND TOTAL: ' + cartTotal + ' ===');

        // Get dealer's available PO credit
        Account dealer = [
            SELECT Id,
                   Purchase_Order_Credit_Limit__c,
                   Purchase_Order_Used_Credit__c,
                   Purchase_Order_Available_Credit__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        Decimal availableCredit = dealer.Purchase_Order_Available_Credit__c;

        System.debug('=== PO CREDIT LIMIT: ' 
            + dealer.Purchase_Order_Credit_Limit__c);

        System.debug('=== PO USED CREDIT: ' 
            + dealer.Purchase_Order_Used_Credit__c);

        System.debug('=== PO AVAILABLE CREDIT: ' 
            + availableCredit);

        // Credit limit validation
        if (cartTotal > availableCredit) {

            System.debug('=== PO CREDIT LIMIT EXCEEDED ===');

            throw new POCreditLimitPlaceOrderValidationException(
                'Purchase Order exceeds the available credit limit. Please reduce the order amount or contact your account manager.'
            );
        }

        System.debug('=== PO CREDIT CHECK PASSED ===');

        // Continue with the normal Commerce Place Order process
        return super.validate(request, domainList);
    }

    public class POCreditLimitPlaceOrderValidationException extends Exception {
    }
}