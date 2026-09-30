public with sharing class DealerCreditController {

    @AuraEnabled(cacheable=true)
    public static Account getDealerCredit() {

        String userEmail = UserInfo.getUserEmail();

        System.debug('CURRENT USER EMAIL = ' + userEmail);

        List<Contact> contacts = [
            SELECT Id, Email, AccountId, Account.Name
            FROM Contact
            WHERE Email = :userEmail
            AND AccountId != null
            LIMIT 1
        ];

        System.debug('CONTACTS FOUND = ' + contacts);

        if (contacts.isEmpty()) {
            System.debug('NO CONTACT FOUND FOR EMAIL');
            return null;
        }

        Id accountId = contacts[0].AccountId;

        System.debug('ACCOUNT ID = ' + accountId);

        Account dealerAccount = [
            SELECT Id,
                   Name,
                   Purchase_Order_Credit_Limit__c,
                   Purchase_Order_Used_Credit__c,
                   Purchase_Order_Available_Credit__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        System.debug('DEALER ACCOUNT = ' + dealerAccount);
        System.debug('CREDIT LIMIT = ' + dealerAccount.Purchase_Order_Credit_Limit__c);
        System.debug('USED CREDIT = ' + dealerAccount.Purchase_Order_Used_Credit__c);
        System.debug('AVAILABLE CREDIT = ' + dealerAccount.Purchase_Order_Available_Credit__c);

        return dealerAccount;
    }
}