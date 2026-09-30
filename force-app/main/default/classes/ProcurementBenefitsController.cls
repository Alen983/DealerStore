public without sharing class ProcurementBenefitsController {

    private static final Decimal BASIC_THRESHOLD = 2500;
    private static final Decimal PREMIUM_THRESHOLD = 5000;
    private static final Decimal ELITE_THRESHOLD = 10000;

    @AuraEnabled
    public static ProcurementBenefitsWrapper getProcurementBenefits() {
        ProcurementBenefitsWrapper response = new ProcurementBenefitsWrapper();

        User currentUser = [
            SELECT Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        Id accountId = currentUser.Contact.AccountId;

        List<OrderSummary> orders = [
            SELECT GrandTotalAmount,
                   TotalAdjDistAmount
            FROM OrderSummary
            WHERE AccountId = :accountId
        ];

        Decimal totalSpend = 0;
        Decimal highest = 0;
        Decimal savings = 0;

        for (OrderSummary os : orders) {
            if (os.GrandTotalAmount != null) {
                totalSpend += os.GrandTotalAmount;

                if (os.GrandTotalAmount > highest) {
                    highest = os.GrandTotalAmount;
                }
            }

            if (os.TotalAdjDistAmount != null) {
                savings += Math.abs(os.TotalAdjDistAmount);
            }
        }

        response.totalSpend = totalSpend;
        response.highestOrderAmount = highest;
        response.totalSavings = savings;
        response.currentTier = resolveTier(totalSpend);

        return response;
    }

    private static String resolveTier(Decimal totalSpend) {
        if (totalSpend >= ELITE_THRESHOLD) {
            return 'Elite';
        }
        if (totalSpend >= PREMIUM_THRESHOLD) {
            return 'Premium';
        }
        if (totalSpend >= BASIC_THRESHOLD) {
            return 'Basic';
        }
        return 'No Tier Achieved';
    }

    public class ProcurementBenefitsWrapper {
        @AuraEnabled
        public Decimal totalSpend;

        @AuraEnabled
        public Decimal highestOrderAmount;

        @AuraEnabled
        public Decimal totalSavings;

        @AuraEnabled
        public String currentTier;
    }
}
