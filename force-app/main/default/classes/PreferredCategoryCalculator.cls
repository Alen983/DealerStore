public with sharing class PreferredCategoryCalculator {

    public class Input {
        @InvocableVariable(required=true)
        public Id orderSummaryId;
    }

    @InvocableMethod(label='Calculate Preferred Category')
    public static void calculatePreferredCategory(List<Input> inputs) {

    Set<Id> orderSummaryIds = new Set<Id>();

    for(Input input : inputs){
        orderSummaryIds.add(input.orderSummaryId);
    }

    List<OrderSummary> orderSummaries = [
        SELECT Id,
            AccountId
        FROM OrderSummary
        WHERE Id IN :orderSummaryIds
    ];

    Set<Id> accountIds = new Set<Id>();

    for(OrderSummary os : orderSummaries){
    accountIds.add(os.AccountId);
    }

    List<OrderItemSummary> items = [

        SELECT Id,
            Type,
            Product2Id,
            OrderSummary.AccountId

        FROM OrderItemSummary

        WHERE OrderSummary.AccountId IN :accountIds

    ];

    // Store all Product IDs except Delivery Charges
    Set<Id> productIds = new Set<Id>();

    for(OrderItemSummary item : items){

    if(item.Type != 'Delivery Charge'){
        productIds.add(item.Product2Id);
    }

}

    // Fetch all Products in a single query
    Map<Id, Product2> productMap = new Map<Id, Product2>(

        [
            SELECT Id,
                Preferred__c
            FROM Product2
            WHERE Id IN :productIds
        ]

    );

    // Count category frequency
    Map<String,Integer> categoryCount = new Map<String,Integer>();

    for(OrderItemSummary item : items){

        if(item.Type == 'Delivery Charge'){
            continue;
        }

        Product2 product = productMap.get(item.Product2Id);

        if(product != null && product.Preferred__c != null){

            if(categoryCount.containsKey(product.Preferred__c)){

                categoryCount.put(
                    product.Preferred__c,
                    categoryCount.get(product.Preferred__c) + 1
                );

            }else{

                categoryCount.put(product.Preferred__c,1);

            }

        }

    }

    String preferredCategory;
    Integer highestCount = 0;

    for(String category : categoryCount.keySet()){

        if(categoryCount.get(category) > highestCount){

            highestCount = categoryCount.get(category);
            preferredCategory = category;

        }
    }

    List<Contact> contacts = [

        SELECT Id,
            Preferred_Product_Category__c

        FROM Contact

        WHERE AccountId IN :accountIds

        ];

        for(Contact con : contacts){

        con.Preferred_Product_Category__c = preferredCategory;

        }

        if(!contacts.isEmpty()){
        update contacts;
        }


}

}