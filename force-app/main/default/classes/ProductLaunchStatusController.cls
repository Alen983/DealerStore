public without sharing class ProductLaunchStatusController {

    public class ProductLaunchWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public String releaseStatus;
        @AuraEnabled public Datetime launchDate;
        @AuraEnabled public Decimal earlyAccess;
    }

    @AuraEnabled
    public static ProductLaunchWrapper getProduct(Id productId) {

        System.debug('===== PRODUCT DEBUG =====');
        System.debug('Received Product ID: ' + productId);
        System.debug('Current User: ' + UserInfo.getUserId());
        System.debug('Current User Type: ' + UserInfo.getUserType());

       List<Product2> products = [
    SELECT
        Id,
        Name,
        Release_Status__c,
        Launch_Date_Time__c,
        Early_Access_Minutes__c
    FROM Product2
    WHERE Id = :productId
    WITH SYSTEM_MODE
    LIMIT 1
];

        System.debug('Products found: ' + products.size());

        if (products.isEmpty()) {
            throw new AuraHandledException(
                'DEBUG: Product query returned 0 records for ID: ' + productId
            );
        }

        Product2 p = products[0];

        System.debug('Product Name: ' + p.Name);
        System.debug('Launch Date: ' + p.Launch_Date_Time__c);
        System.debug('Early Access: ' + p.Early_Access_Minutes__c);
        System.debug('Release Status: ' + p.Release_Status__c);

        ProductLaunchWrapper wrapper = new ProductLaunchWrapper();

        wrapper.name = p.Name;
        wrapper.releaseStatus = p.Release_Status__c;
        wrapper.launchDate = p.Launch_Date_Time__c;
        wrapper.earlyAccess = p.Early_Access_Minutes__c;

        return wrapper;
    }
}