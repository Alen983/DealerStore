public with sharing class SubscriptionRequestLinkAction {

    public class Request {
        @InvocableVariable(required=true)
        public Id orderId;

        @InvocableVariable(required=true)
        public Id accountId;
    }

    @InvocableMethod(label='Link Subscription Requests To Order')
    public static void linkRequests(List<Request> requests) {

        for (Request r : requests) {

            // Get products actually purchased on this order
            Set<Id> productIds = new Set<Id>();
            for (OrderItem oi : [SELECT Product2Id FROM OrderItem WHERE OrderId = :r.orderId]) {
                productIds.add(oi.Product2Id);
            }

            if (productIds.isEmpty()) continue;

            // Get all pending requests for this account, newest first
            List<Subscription_Request__c> pending = [
                SELECT Id, Product__c, CreatedDate
                FROM Subscription_Request__c
                WHERE Account__c = :r.accountId
                AND Product__c IN :productIds
                AND Status__c = 'Pending'
                ORDER BY CreatedDate DESC
            ];

            // Keep only the newest pending request per product; mark older duplicates cancelled
            Map<Id, Subscription_Request__c> newestByProduct = new Map<Id, Subscription_Request__c>();
            List<Subscription_Request__c> toUpdate = new List<Subscription_Request__c>();

            for (Subscription_Request__c req : pending) {
                if (!newestByProduct.containsKey(req.Product__c)) {
                    newestByProduct.put(req.Product__c, req);
                    toUpdate.add(new Subscription_Request__c(
                        Id = req.Id,
                        Status__c = 'Active',
                        Order__c = r.orderId,
                        Next_Order_Date__c = Date.today().addMonths(1)
                    ));
                } else {
                    toUpdate.add(new Subscription_Request__c(
                        Id = req.Id,
                        Status__c = 'Cancelled' // stale duplicate from repeated Add to Cart clicks
                    ));
                }
            }

            if (!toUpdate.isEmpty()) update toUpdate;
        }
    }
}