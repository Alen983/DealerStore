public with sharing class POCreditCheckoutValidatorController {

    public class CreditValidationResult {
        @AuraEnabled public Decimal cartTotal;
        @AuraEnabled public Decimal availableCredit;
        @AuraEnabled public Decimal creditLimit;
        @AuraEnabled public Decimal usedCredit;
        @AuraEnabled public Boolean withinLimit;
        @AuraEnabled public String message;
    }

    @AuraEnabled(cacheable=false)
    public static CreditValidationResult validateCredit(String cartId) {

        CreditValidationResult result = new CreditValidationResult();

        System.debug('=== PO CREDIT VALIDATION STARTED ===');
        System.debug('Cart ID = ' + cartId);

        // 1. Get cart total
        WebCart cart = [
            SELECT Id, GrandTotalAmount
            FROM WebCart
            WHERE Id = :cartId
            LIMIT 1
        ];

        result.cartTotal = cart.GrandTotalAmount == null
            ? 0
            : cart.GrandTotalAmount;

        System.debug('CART TOTAL = ' + result.cartTotal);


        // 2. Get current user's email
        String userEmail = UserInfo.getUserEmail();

        System.debug('CURRENT USER EMAIL = ' + userEmail);


        // 3. Find Contact using email
        List<Contact> contacts = [
            SELECT Id, Email, AccountId
            FROM Contact
            WHERE Email = :userEmail
            AND AccountId != NULL
            LIMIT 1
        ];

        System.debug('CONTACTS FOUND = ' + contacts);

        if (contacts.isEmpty()) {

            result.withinLimit = false;
            result.message =
                'Unable to determine the dealer account for this user.';

            System.debug('NO CONTACT FOUND');

            return result;
        }

        Contact contact = contacts[0];

        System.debug('CONTACT ID = ' + contact.Id);
        System.debug('ACCOUNT ID = ' + contact.AccountId);


        // 4. Get Dealer Account credit information
        Account dealerAccount = [
            SELECT Id,
                   Name,
                   Purchase_Order_Credit_Limit__c,
                   Purchase_Order_Used_Credit__c,
                   Purchase_Order_Available_Credit__c
            FROM Account
            WHERE Id = :contact.AccountId
            LIMIT 1
        ];

        System.debug('DEALER ACCOUNT = ' + dealerAccount);


        // 5. Get credit values
        result.creditLimit =
            dealerAccount.Purchase_Order_Credit_Limit__c == null
            ? 0
            : dealerAccount.Purchase_Order_Credit_Limit__c;

        result.usedCredit =
            dealerAccount.Purchase_Order_Used_Credit__c == null
            ? 0
            : dealerAccount.Purchase_Order_Used_Credit__c;

        result.availableCredit =
            dealerAccount.Purchase_Order_Available_Credit__c == null
            ? 0
            : dealerAccount.Purchase_Order_Available_Credit__c;


        System.debug('CREDIT LIMIT = ' + result.creditLimit);
        System.debug('USED CREDIT = ' + result.usedCredit);
        System.debug('AVAILABLE CREDIT = ' + result.availableCredit);


        // 6. Compare cart total with available credit
        result.withinLimit =
            result.cartTotal <= result.availableCredit;


        System.debug('WITHIN LIMIT = ' + result.withinLimit);


        // 7. Return appropriate message
        if (result.withinLimit) {

            result.message =
                'Purchase Order credit is sufficient.';

            System.debug('PO CREDIT CHECK PASSED');

        } else {

            result.message =
                'Purchase Order exceeds the available credit limit. ' +
                'Available credit: ' +
                String.valueOf(result.availableCredit) +
                '. Cart total: ' +
                String.valueOf(result.cartTotal) +
                '.';

            System.debug('PO CREDIT CHECK FAILED');
        }

        System.debug('=== PO CREDIT VALIDATION FINISHED ===');

        return result;
    }
}