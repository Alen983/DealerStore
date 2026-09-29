public class AccountDashboardController {
 
    public List<Account> accounts { get; private set; }
 
    public AccountDashboardController() {
        accounts = [
            SELECT Id, Name, Industry, Type, Rating
            FROM Account
            ORDER BY Name
            LIMIT 10
        ];
    }
}