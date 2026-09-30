public with sharing class SimplePOCreditValidatorController {

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

        // STEP 1: Get the current cart
        WebCart cart = [
            SELECT Id,
                   GrandTotalAmount,
                   AccountId
            FROM WebCart
            WHERE Id = :cartId
            LIMIT 1
        ];

        // STEP 2: Get cart total
        result.cartTotal =
            cart.GrandTotalAmount == null
            ? 0
            : cart.GrandTotalAmount;

        // STEP 3: Make sure cart is connected to an Account
        if (cart.AccountId == null) {

            result.withinLimit = false;
            result.message =
                'Unable to determine the dealer account for this cart.';

            return result;
        }

        // STEP 4: Get dealer Account credit information
        Account dealerAccount = [
            SELECT Id,
                   Name,
                   Purchase_Order_Credit_Limit__c,
                   Purchase_Order_Used_Credit__c
            FROM Account
            WHERE Id = :cart.AccountId
            LIMIT 1
        ];

        // STEP 5: Get credit limit
        result.creditLimit =
            dealerAccount.Purchase_Order_Credit_Limit__c == null
            ? 0
            : dealerAccount.Purchase_Order_Credit_Limit__c;

        // STEP 6: Get used credit
        result.usedCredit =
            dealerAccount.Purchase_Order_Used_Credit__c == null
            ? 0
            : dealerAccount.Purchase_Order_Used_Credit__c;

        // STEP 7: Calculate available credit
        Decimal calculatedAvailableCredit =
            result.creditLimit - result.usedCredit;

        // STEP 8: Never allow available credit to be negative
        if (calculatedAvailableCredit < 0) {
            calculatedAvailableCredit = 0;
        }

        result.availableCredit = calculatedAvailableCredit;

        // STEP 9: Compare cart total with available credit
        result.withinLimit =
            result.cartTotal <= result.availableCredit;

        // STEP 10: Return appropriate message
        if (result.withinLimit) {

            result.message =
                'Purchase Order credit is sufficient.';

        } else {

            result.message =
                'Purchase Order exceeds the available credit. ' +
                'Available credit: $' +
                String.valueOf(result.availableCredit) +
                '. Cart total: $' +
                String.valueOf(result.cartTotal) +
                '.';
        }

        return result;
    }
}