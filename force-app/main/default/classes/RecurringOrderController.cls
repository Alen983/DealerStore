public with sharing class RecurringOrderController {

    public class RecurringOrderGroup {
        @AuraEnabled public String contractId;
        @AuraEnabled public String frequency;
        @AuraEnabled public String status;
        @AuraEnabled public List<Recurring_Contract_Line_Item__c> lineItems;
    }

    @AuraEnabled(cacheable=true)
    public static List<RecurringOrderGroup> getUpcomingDeliveries() {
        Id currentUserId = UserInfo.getUserId();

        String userQuery = 'SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1';
        List<User> users = Database.query(userQuery);
        if (users.isEmpty() || users[0].ContactId == null) {
            return new List<RecurringOrderGroup>();
        }

        Id contId = users[0].ContactId;
        String contactQuery = 'SELECT AccountId FROM Contact WHERE Id = :contId LIMIT 1';
        List<Contact> contacts = Database.query(contactQuery);
        if (contacts.isEmpty()) {
            return new List<RecurringOrderGroup>();
        }

        Id accountId = contacts[0].AccountId;

        List<Recurring_Contract_Line_Item__c> items = [
            SELECT Id, Next_Delivery_Date__c, Quantity__c, Contract_Price__c,
                   Product__r.Name, Product__r.ProductCode,
                   Recurring_Contract__c,
                   Recurring_Contract__r.Frequency__c,
                   Recurring_Contract__r.Contract_Status__c
            FROM Recurring_Contract_Line_Item__c
            WHERE Recurring_Contract__r.Buyer_Account__c = :accountId
              AND Recurring_Contract__r.Contract_Status__c = 'Active'
            WITH USER_MODE
            ORDER BY Next_Delivery_Date__c ASC
        ];

        Map<Id, RecurringOrderGroup> groups = new Map<Id, RecurringOrderGroup>();
        List<Id> orderedContractIds = new List<Id>();

        for (Recurring_Contract_Line_Item__c item : items) {
            Id contractId = item.Recurring_Contract__c;
            if (!groups.containsKey(contractId)) {
                RecurringOrderGroup g = new RecurringOrderGroup();
                g.contractId = contractId;
                g.frequency = item.Recurring_Contract__r.Frequency__c;
                g.status = item.Recurring_Contract__r.Contract_Status__c;
                g.lineItems = new List<Recurring_Contract_Line_Item__c>();
                groups.put(contractId, g);
                orderedContractIds.add(contractId);
            }
            groups.get(contractId).lineItems.add(item);
        }

        List<RecurringOrderGroup> result = new List<RecurringOrderGroup>();
        for (Id cId : orderedContractIds) {
            result.add(groups.get(cId));
        }
        return result;
    }
}