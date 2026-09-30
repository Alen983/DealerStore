public with sharing class CartSubscriptionBadgeController {

    @AuraEnabled(cacheable=true)
    public static Id getActiveCartId() {
        List<WebCart> carts = [
            SELECT Id
            FROM WebCart
            WHERE AccountId = :getCurrentAccountId()
            AND Status = 'Active'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return carts.isEmpty() ? null : carts[0].Id;
    }

@AuraEnabled(cacheable=true)
public static List<Subscription_Request__c> getCartSubscriptionItems(Id cartId) {
    if (cartId == null) {
        return new List<Subscription_Request__c>();
    }

    // Get products actually still in the cart right now
    Set<Id> productsStillInCart = new Set<Id>();
    for (CartItem ci : [
        SELECT Product2Id
        FROM CartItem
        WHERE CartId = :cartId
    ]) {
        productsStillInCart.add(ci.Product2Id);
    }

    Map<Id, Subscription_Request__c> distinctByProduct = new Map<Id, Subscription_Request__c>();

    for (Subscription_Request__c req : [
        SELECT Id, Product__c, Product__r.Name, Selling_Model__r.Name, Quantity__c
        FROM Subscription_Request__c
        WHERE Cart_Id__c = :cartId
        AND Status__c = 'Pending'
        ORDER BY CreatedDate DESC
    ]) {
        // Only include it if the product is genuinely still in the live cart
        if (productsStillInCart.contains(req.Product__c) && !distinctByProduct.containsKey(req.Product__c)) {
            distinctByProduct.put(req.Product__c, req);
        }
    }

    return distinctByProduct.values();
}
    private static Id getCurrentAccountId() {
        WebCart cart = [
            SELECT AccountId
            FROM WebCart
            WHERE OwnerId = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return cart.AccountId;
    }
}