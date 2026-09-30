public class AccountController {
 
    @AuraEnabled
    public static void createAccount(String name, String phone, String website) {
        Account acc = new Account(
            Name = name,
            Phone = phone,
            Website = website
        );
        insert acc;
    }
}