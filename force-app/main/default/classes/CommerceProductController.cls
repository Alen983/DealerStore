public with sharing class CommerceProductController {

    @AuraEnabled(cacheable=true)
    public static List<Product2Wrapper> getProducts() {

        List<Product2Wrapper> result = new List<Product2Wrapper>();

        for(Product2 p : [
            SELECT Id,
                   Name,
                   ProductCode,
                   IsActive
            FROM Product2
            WHERE IsActive = true
        ]){

            Product2Wrapper wrap = new Product2Wrapper();

            wrap.Id = p.Id;
            wrap.Name = p.Name;
            wrap.ProductCode = p.ProductCode;
            wrap.StandardPrice = 1000;

            result.add(wrap);
        }

        return result;
    }

    public class Product2Wrapper {

        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String ProductCode;
        @AuraEnabled public Decimal StandardPrice;

    }
}