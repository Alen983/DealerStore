public with sharing class CommerceSubscriptionController {

    public class SellingModelWrapper {

        @AuraEnabled
        public Id optionId;
            @AuraEnabled public Id sellingModelId;  
        @AuraEnabled
        public String sellingModelName;

        @AuraEnabled
        public String sellingModelType;

        @AuraEnabled
        public Integer pricingTerm;

        @AuraEnabled
        public String pricingTermUnit;
    }

    @AuraEnabled(cacheable=true)
    public static List<SellingModelWrapper> getSellingModels(Id productId) {

        // If productId comes in null/undefined, fail loudly with a real message
        // instead of letting the platform reject the whole request silently.
        if (productId == null) {
            throw new AuraHandledException('productId is required.');
        }

        List<SellingModelWrapper> result = new List<SellingModelWrapper>();

        try {
            for (ProductSellingModelOption option : [
    SELECT Id,
           ProductSellingModel.Name,
           ProductSellingModel.SellingModelType,
           ProductSellingModel.PricingTerm,
           ProductSellingModel.PricingTermUnit
    FROM ProductSellingModelOption
    WHERE Product2Id = :productId
]) {
    SellingModelWrapper wrapper = new SellingModelWrapper();
    wrapper.optionId = option.Id;
    wrapper.sellingModelName = option.ProductSellingModel.Name;
    wrapper.sellingModelId = option.ProductSellingModelId;  
    wrapper.sellingModelType = option.ProductSellingModel.SellingModelType;
    wrapper.pricingTerm = option.ProductSellingModel.PricingTerm;
    wrapper.pricingTermUnit = option.ProductSellingModel.PricingTermUnit;
    result.add(wrapper);
}
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }
@AuraEnabled
public static ConnectApi.CartItem addToCart(String communityId, String productId, String sellingModelId, Integer quantity) {

    try {
        WebStoreNetwork wsn = [
            SELECT WebStoreId
            FROM WebStoreNetwork
            WHERE NetworkId = :communityId
            LIMIT 1
        ];

        ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();
        cartItemInput.productId = productId;
        cartItemInput.quantity = String.valueOf(quantity);
        cartItemInput.type = ConnectApi.CartItemType.PRODUCT;

        ConnectApi.CartItem addedItem = ConnectApi.CommerceCart.addItemToCart(
            wsn.WebStoreId,
            null,
            'current',
            cartItemInput
        );

        if (String.isNotBlank(sellingModelId)) {
            WebCart cart = [SELECT AccountId FROM WebCart WHERE Id = :addedItem.cartId LIMIT 1];

            Subscription_Request__c req = new Subscription_Request__c(
                Account__c = cart.AccountId,
                Product__c = productId,
                Selling_Model__c = sellingModelId,
                Quantity__c = quantity,
                Cart_Id__c = addedItem.cartId,
                Status__c = 'Pending'
            );
            insert req;
        }

        return addedItem;

    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}

}