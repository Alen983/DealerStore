public with sharing class ReorderAssistantController {

    public class ProductRecommendation {

        @AuraEnabled
        public Id productId;

        @AuraEnabled
        public String name;

        @AuraEnabled
        public String sku;

        @AuraEnabled
        public Decimal price;
    }


    public class ReorderData {

        @AuraEnabled
        public String contactName;

        @AuraEnabled
        public String preferredCategory;

        @AuraEnabled
        public List<ProductRecommendation> products;
    }


    @AuraEnabled(cacheable=true)
    public static ReorderData getReorderData(Id accountId) {

        ReorderData result = new ReorderData();

        result.products = new List<ProductRecommendation>();


        if (accountId == null) {
            return result;
        }


        // Find the Contact belonging to the buyer account
        List<Contact> contacts = [
            SELECT Id,
                   Name,
                   Preferred_Product_Category__c
            FROM Contact
            WHERE AccountId = :accountId
            LIMIT 1
        ];


        if (contacts.isEmpty()) {
            return result;
        }


        Contact buyerContact = contacts[0];

        result.contactName = buyerContact.Name;

        result.preferredCategory =
            buyerContact.Preferred_Product_Category__c;


        // No preferred category
        if (String.isBlank(result.preferredCategory)) {
            return result;
        }


        // Find products belonging to preferred category
        List<Product2> products = [
            SELECT Id,
                   Name,
                   ProductCode,
                   Preferred__c,
                   IsActive
            FROM Product2
            WHERE Preferred__c = :result.preferredCategory
            AND IsActive = true
            ORDER BY Name
            LIMIT 10
        ];


        if (products.isEmpty()) {
            return result;
        }


        // Collect Product IDs
        Set<Id> productIds = new Set<Id>();

        for (Product2 product : products) {
            productIds.add(product.Id);
        }


        // Get active Standard Price Book entries
        List<PricebookEntry> priceEntries = [
            SELECT Product2Id,
                   UnitPrice
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
            AND Pricebook2.IsStandard = true
            AND IsActive = true
        ];


        // Create Product ID → Price map
        Map<Id, Decimal> priceMap = new Map<Id, Decimal>();

        for (PricebookEntry entry : priceEntries) {
            priceMap.put(
                entry.Product2Id,
                entry.UnitPrice
            );
        }


        // Build response
        for (Product2 product : products) {

            ProductRecommendation recommendation =
                new ProductRecommendation();

            recommendation.productId = product.Id;

            recommendation.name =
                product.Name;

            recommendation.sku =
                product.ProductCode;

            recommendation.price =
                priceMap.get(product.Id);

            result.products.add(
                recommendation
            );
        }


        return result;
    }
}