public with sharing class ContractStoreController {

    /*
     * ============================================================
     * DATA CLASSES
     * ============================================================
     */

    public class ContractInfo {

        @AuraEnabled public Id contractId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String contractNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;
        @AuraEnabled public Integer daysRemaining;
        @AuraEnabled public Decimal progressPercent;
        @AuraEnabled public Boolean expired;
        @AuraEnabled public Boolean expiringSoon;
        @AuraEnabled public Boolean pricingEnabled;
        @AuraEnabled public String priceBookName;

    }


    public class UsageInfo {

        @AuraEnabled public Integer orderCount;
        @AuraEnabled public Decimal totalValue;
        @AuraEnabled public Integer productCount;

    }


    public class OrderInfo {

        @AuraEnabled public Id orderId;
        @AuraEnabled public String orderNumber;
        @AuraEnabled public String orderDate;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal total;

    }


    public class CompanyInfo {

        @AuraEnabled public String companyName;
        @AuraEnabled public String contactName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String industry;
        @AuraEnabled public String website;

    }


    public class AccessInfo {

        @AuraEnabled public String companyName;
        @AuraEnabled public String contractNumber;
        @AuraEnabled public String contractStatus;
        @AuraEnabled public Boolean pricingEnabled;
        @AuraEnabled public String priceBookName;
        @AuraEnabled public String purchaseMethod;
        @AuraEnabled public String specialTerms;
        @AuraEnabled public String accessMessage;

    }


    public class ProductContractInfo {

        @AuraEnabled public Boolean covered;
        @AuraEnabled public String productName;
        @AuraEnabled public String contractNumber;
        @AuraEnabled public String message;

    }


    public class ContractProductPriceInfo {

        @AuraEnabled public String productName;

        @AuraEnabled public Decimal listPrice;

        @AuraEnabled public Decimal contractPrice;

        @AuraEnabled public Boolean hasContractPrice;

        @AuraEnabled public Boolean hasListPrice;

        @AuraEnabled public String contractNumber;

        @AuraEnabled public String priceBookName;

    }


    public class CatalogProductItem {

        @AuraEnabled public Id productId;

        @AuraEnabled public String productName;

        @AuraEnabled public String sku;

        @AuraEnabled public Decimal referencePrice;

        @AuraEnabled public Decimal contractPrice;

        @AuraEnabled public Boolean hasReferencePrice;

        @AuraEnabled public Decimal savingsAmount;

        @AuraEnabled public Decimal savingsPercent;

    }


    public class ContractProductCatalogInfo {

        @AuraEnabled public String contractNumber;

        @AuraEnabled public String priceBookName;

        @AuraEnabled public Integer productCount;

        @AuraEnabled public String message;

        @AuraEnabled public List<CatalogProductItem> products;

    }


    /*
     * ============================================================
     * FIND LOGGED-IN USER'S CONTACT
     *
     * We do NOT use User.ContactId because that field is not
     * available in your org.
     *
     * Instead, we match the logged-in user's email with
     * Contact.Email.
     * ============================================================
     */

    private static Contact getCurrentContact() {

        String userEmail = UserInfo.getUserEmail();

        if (String.isBlank(userEmail)) {
            return null;
        }

        List<Contact> contacts = [

            SELECT
                Id,
                FirstName,
                LastName,
                Name,
                Email,
                Phone,
                AccountId,
                Account.Name,
                Account.Industry,
                Account.Website,
                Account.Phone

            FROM Contact

            WHERE Email = :userEmail

            LIMIT 1
        ];

        if (contacts.isEmpty()) {
            return null;
        }

        return contacts[0];
    }


    /*
     * ============================================================
     * FIND CURRENT CONTRACT
     *
     * First look for an Activated contract.
     *
     * If no Activated contract exists, return the most recent
     * contract for the account.
     * ============================================================
     */

    private static Contract getCurrentContract(Id accountId) {

        if (accountId == null) {
            return null;
        }


        /*
         * First: Activated contract
         */

        List<Contract> activeContracts = [

            SELECT
                Id,
                AccountId,
                Account.Name,
                ContractNumber,
                Status,
                StartDate,
                EndDate,
                Pricebook2Id,
                Pricebook2.Name,
                SpecialTerms

            FROM Contract

            WHERE AccountId = :accountId

            AND Status = 'Activated'

            ORDER BY EndDate DESC

            LIMIT 1
        ];


        if (!activeContracts.isEmpty()) {

            return activeContracts[0];

        }


        /*
         * Second: If no Activated contract exists,
         * get the most recent contract.
         */

        List<Contract> contracts = [

            SELECT
                Id,
                AccountId,
                Account.Name,
                ContractNumber,
                Status,
                StartDate,
                EndDate,
                Pricebook2Id,
                Pricebook2.Name,
                SpecialTerms

            FROM Contract

            WHERE AccountId = :accountId

            ORDER BY EndDate DESC

            LIMIT 1
        ];


        if (contracts.isEmpty()) {

            return null;

        }


        return contracts[0];
    }


    /*
     * ============================================================
     * 1. MY CONTRACT
     *
     * NOTE: This method is intentionally NOT marked cacheable.
     * It computes daysRemaining / progressPercent from
     * Date.today(), and its correct output legitimately changes
     * every calendar day even when the underlying Contract
     * record hasn't changed. cacheable=true (server-side Apex
     * action cache) can otherwise keep serving a stale result
     * from an earlier day even when called imperatively from
     * the LWC. "today" is still captured ONCE per invocation and
     * reused for every date-based calculation below
     * (daysRemaining, expired, expiringSoon, progressPercent) so
     * these values can never contradict each other within a
     * single call.
     * ============================================================
     */

    @AuraEnabled
    public static ContractInfo getMyContract() {

        Contact contact = getCurrentContact();


        if (contact == null || contact.AccountId == null) {

            return new ContractInfo();

        }


        Contract con =
            getCurrentContract(contact.AccountId);


        if (con == null) {

            return new ContractInfo();

        }


        ContractInfo result =
            new ContractInfo();


        result.contractId =
            con.Id;


        result.accountName =
            con.Account != null
                ? con.Account.Name
                : null;


        result.contractNumber =
            con.ContractNumber;


        result.status =
            con.Status;


        result.startDate =
            con.StartDate != null
                ? String.valueOf(con.StartDate)
                : null;


        result.endDate =
            con.EndDate != null
                ? String.valueOf(con.EndDate)
                : null;


        /*
         * Single source of truth for "today" - Salesforce's
         * own calendar date (Date has no time component,
         * so there is no timezone/off-by-one risk here).
         */

        Date today = Date.today();


        /*
         * Days remaining (raw, can be negative if the
         * contract has already ended).
         */

        Integer rawDaysRemaining = 0;


        if (con.EndDate != null) {

            rawDaysRemaining =
                today.daysBetween(con.EndDate);

        }


        result.expired =
            con.EndDate != null && rawDaysRemaining <= 0;


        result.expiringSoon =
            !result.expired &&
            rawDaysRemaining > 0 &&
            rawDaysRemaining <= 30;


        /*
         * Clamp the displayed value so the UI never shows
         * a negative number of days.
         */

        result.daysRemaining =
            rawDaysRemaining < 0 ? 0 : rawDaysRemaining;


        /*
         * Contract Validity = percentage of the contract term
         * that is still REMAINING, derived from the SAME
         * rawDaysRemaining value used above - not a separately
         * calculated "elapsed" figure. This is what keeps the
         * progress bar and the percentage consistent with
         * Days Remaining at all times.
         */

        if (
            con.StartDate != null &&
            con.EndDate != null
        ) {

            Integer totalDays =
                con.StartDate.daysBetween(con.EndDate);


            if (totalDays > 0) {

                Integer remainingDaysForProgress =
                    rawDaysRemaining;


                if (remainingDaysForProgress < 0) {

                    remainingDaysForProgress = 0;

                }


                if (remainingDaysForProgress > totalDays) {

                    remainingDaysForProgress = totalDays;

                }


                Decimal percentage =
                    (
                        (Decimal) remainingDaysForProgress /
                        totalDays
                    ) * 100;


                result.progressPercent =
                    percentage.setScale(0);

            } else {

                /*
                 * Zero-length contract (Start == End date).
                 */

                result.progressPercent =
                    (con.EndDate < today) ? 0 : 100;

            }

        }


        /*
         * Contract pricing
         *
         * Contract Price Book is used as the indicator
         * that contract pricing is configured.
         */

        result.pricingEnabled =
            con.Pricebook2Id != null;


        result.priceBookName =
            con.Pricebook2 != null
                ? con.Pricebook2.Name
                : null;


        return result;
    }


    /*
     * ============================================================
     * 2. CONTRACT USAGE
     * ============================================================
     */

    @AuraEnabled(cacheable=true)
    public static UsageInfo getContractUsage() {

        Contact contact =
            getCurrentContact();


        UsageInfo result =
            new UsageInfo();


        result.orderCount = 0;

        result.totalValue = 0;

        result.productCount = 0;


        if (
            contact == null ||
            contact.AccountId == null
        ) {

            return result;

        }


        /*
         * Get orders for the buyer's Account.
         */

        List<Order> orders = [

            SELECT
                Id,
                TotalAmount

            FROM Order

            WHERE AccountId = :contact.AccountId

            ORDER BY EffectiveDate DESC

            LIMIT 200
        ];


        result.orderCount =
            orders.size();


        Decimal total = 0;


        for (Order ord : orders) {

            if (ord.TotalAmount != null) {

                total +=
                    ord.TotalAmount;

            }

        }


        result.totalValue =
            total;


        /*
         * Count unique products purchased.
         *
         * We intentionally do NOT use
         * ContractLineItem.ContractId because
         * that field does not exist in your org.
         */

        Set<Id> orderIds =
            new Set<Id>();


        for (Order ord : orders) {

            orderIds.add(
                ord.Id
            );

        }


        if (!orderIds.isEmpty()) {

            AggregateResult[] productResults = [

                SELECT
                    Product2Id productId

                FROM OrderItem

                WHERE OrderId IN :orderIds

                AND Product2Id != null

                GROUP BY Product2Id

            ];


            result.productCount =
                productResults.size();

        }


        return result;
    }


    /*
     * ============================================================
     * 3. RECENT ORDERS
     * ============================================================
     */

    @AuraEnabled(cacheable=true)
    public static List<OrderInfo> getRecentOrders() {

        List<OrderInfo> result =
            new List<OrderInfo>();


        Contact contact =
            getCurrentContact();


        if (
            contact == null ||
            contact.AccountId == null
        ) {

            return result;

        }


        List<Order> orders = [

            SELECT
                Id,
                OrderNumber,
                EffectiveDate,
                Status,
                TotalAmount

            FROM Order

            WHERE AccountId = :contact.AccountId

            ORDER BY
                EffectiveDate DESC,
                CreatedDate DESC

            LIMIT 10
        ];


        for (Order ord : orders) {

            OrderInfo item =
                new OrderInfo();


            item.orderId =
                ord.Id;


            item.orderNumber =
                ord.OrderNumber;


            item.orderDate =
                ord.EffectiveDate != null
                    ? String.valueOf(
                        ord.EffectiveDate
                    )
                    : null;


            item.status =
                ord.Status;


            item.total =
                ord.TotalAmount != null
                    ? ord.TotalAmount
                    : 0;


            result.add(item);

        }


        return result;
    }


    /*
     * ============================================================
     * 4. MY COMPANY
     * ============================================================
     */

    @AuraEnabled(cacheable=true)
    public static CompanyInfo getMyCompany() {

        CompanyInfo result =
            new CompanyInfo();


        Contact contact =
            getCurrentContact();


        if (contact == null) {

            return result;

        }


        if (contact.Account != null) {

            result.companyName =
                contact.Account.Name;


            result.industry =
                contact.Account.Industry;


            result.website =
                contact.Account.Website;

        }


        result.contactName =
            contact.Name;


        result.email =
            contact.Email;


        /*
         * Phone: use Contact.Phone if present,
         * otherwise fall back to Account.Phone.
         */

        result.phone =
            String.isNotBlank(contact.Phone)
                ? contact.Phone
                : (
                    contact.Account != null
                        ? contact.Account.Phone
                        : null
                );


        return result;
    }


    /*
     * ============================================================
     * 5. CONTRACT ACCESS
     * ============================================================
     */

    @AuraEnabled(cacheable=true)
    public static AccessInfo getContractAccess() {

        AccessInfo result =
            new AccessInfo();


        Contact contact =
            getCurrentContact();


        if (
            contact == null ||
            contact.AccountId == null
        ) {

            result.accessMessage =
                'No company account was found for the logged-in user.';


            return result;

        }


        Contract con =
            getCurrentContract(
                contact.AccountId
            );


        if (con == null) {

            result.accessMessage =
                'No contract was found for your company.';


            return result;

        }


        result.companyName =
            con.Account != null
                ? con.Account.Name
                : null;


        result.contractNumber =
            con.ContractNumber;


        result.contractStatus =
            con.Status;


        result.pricingEnabled =
            con.Pricebook2Id != null;


        result.priceBookName =
            con.Pricebook2 != null
                ? con.Pricebook2.Name
                : null;


        result.specialTerms =
            con.SpecialTerms;


        /*
         * We don't invent a Purchase Method field.
         *
         * If Special Terms contains purchasing instructions,
         * display those terms.
         */

        result.purchaseMethod =
            null;


        if (
            String.isNotBlank(
                con.SpecialTerms
            )
        ) {

            result.purchaseMethod =
                con.SpecialTerms;

        }


        if (result.pricingEnabled) {

            result.accessMessage =
                'Contract pricing is enabled for your account.';

        }
        else {

            result.accessMessage =
                'Your account has an active contract.';

        }


        return result;
    }


    /*
     * ============================================================
     * 6. CHECK PRODUCT CONTRACT
     *
     * A product is considered "covered" when it has an active
     * PricebookEntry in the current contract's price book.
     * ============================================================
     */

    @AuraEnabled(cacheable=true)
    public static ProductContractInfo checkProductContract(Id productId) {

        ProductContractInfo result =
            new ProductContractInfo();

        result.covered = false;


        if (productId == null) {

            result.message =
                'No product specified.';

            return result;

        }


        Contact contact =
            getCurrentContact();


        if (
            contact == null ||
            contact.AccountId == null
        ) {

            result.message =
                'No company account was found for the logged-in user.';

            return result;

        }


        Contract con =
            getCurrentContract(
                contact.AccountId
            );


        if (con == null) {

            result.message =
                'No contract was found for your company.';

            return result;

        }


        result.contractNumber =
            con.ContractNumber;


        List<Product2> products = [

            SELECT
                Id,
                Name

            FROM Product2

            WHERE Id = :productId

            LIMIT 1
        ];


        result.productName =
            !products.isEmpty()
                ? products[0].Name
                : null;


        if (con.Pricebook2Id == null) {

            result.message =
                'Your contract does not have contract pricing configured.';

            return result;

        }


        List<PricebookEntry> entries = [

            SELECT
                Id,
                UnitPrice

            FROM PricebookEntry

            WHERE Pricebook2Id = :con.Pricebook2Id

            AND Product2Id = :productId

            AND IsActive = true

            LIMIT 1
        ];


        if (!entries.isEmpty()) {

            result.covered = true;

            result.message =
                'This product is included in your contract pricing.';

        } else {

            result.covered = false;

            result.message =
                'This product is not included in your current contract.';

        }


        return result;
    }


    /*
     * ============================================================
     * 7. CONTRACT PRODUCT PRICING
     *
     * Returns:
     *
     * 1. "List" / strikethrough price - from the
     *    "Dealer Store Strikethrough Price Book".
     *    Falls back to the Standard Price Book if the
     *    product has no active entry in the strikethrough
     *    book yet, so the UI never silently loses the
     *    struck-through price.
     *
     * 2. Contract price - from the Price Book attached
     *    to the customer's current Contract.
     *
     * This is used by the Contract Product Price LWC
     * to display:
     *
     * ~~List / Strikethrough Price~~   Contract Price
     * ============================================================
     */

    private static final String STRIKETHROUGH_PRICEBOOK_NAME =
        'Dealer Store Strikethrough Price Book';


    @AuraEnabled(cacheable=true)
    public static ContractProductPriceInfo getContractProductPricing(
        Id productId
    ) {

        ContractProductPriceInfo result =
            new ContractProductPriceInfo();

        result.hasContractPrice = false;
        result.hasListPrice = false;


        /*
         * Product is required.
         */

        if (productId == null) {

            return result;

        }


        /*
         * Get product name.
         */

        List<Product2> products = [

            SELECT
                Id,
                Name

            FROM Product2

            WHERE Id = :productId

            LIMIT 1

        ];


        if (products.isEmpty()) {

            return result;

        }


        result.productName =
            products[0].Name;


        /*
         * --------------------------------------------------------
         * LIST / STRIKETHROUGH PRICE
         * --------------------------------------------------------
         *
         * Preferred source: the dedicated strikethrough
         * price book, matched by name.
         *
         * Fallback: the Standard Price Book, in case a
         * product hasn't been added to the strikethrough
         * book yet.
         */

        List<PricebookEntry> strikethroughEntries = [

            SELECT
                Id,
                UnitPrice

            FROM PricebookEntry

            WHERE Product2Id = :productId

            AND Pricebook2.Name = :STRIKETHROUGH_PRICEBOOK_NAME

            AND IsActive = true

            LIMIT 1

        ];


        if (!strikethroughEntries.isEmpty()) {

            result.listPrice =
                strikethroughEntries[0].UnitPrice;

            result.hasListPrice =
                result.listPrice != null;

        } else {

            List<PricebookEntry> standardEntries = [

                SELECT
                    Id,
                    UnitPrice

                FROM PricebookEntry

                WHERE Product2Id = :productId

                AND Pricebook2.IsStandard = true

                AND IsActive = true

                LIMIT 1

            ];


            if (!standardEntries.isEmpty()) {

                result.listPrice =
                    standardEntries[0].UnitPrice;

                result.hasListPrice =
                    result.listPrice != null;

            }

        }


        /*
         * Get logged-in Contact.
         */

        Contact contact =
            getCurrentContact();


        if (
            contact == null ||
            contact.AccountId == null
        ) {

            return result;

        }


        /*
         * Get current contract.
         */

        Contract con =
            getCurrentContract(
                contact.AccountId
            );


        if (con == null) {

            return result;

        }


        /*
         * Contract information.
         */

        result.contractNumber =
            con.ContractNumber;


        result.priceBookName =
            con.Pricebook2 != null
                ? con.Pricebook2.Name
                : null;


        /*
         * --------------------------------------------------------
         * CONTRACT PRICE
         * --------------------------------------------------------
         *
         * Get the price from the Price Book attached
         * to the customer's current contract.
         */

        if (con.Pricebook2Id == null) {

            return result;

        }


        List<PricebookEntry> contractEntries = [

            SELECT
                Id,
                UnitPrice

            FROM PricebookEntry

            WHERE Pricebook2Id = :con.Pricebook2Id

            AND Product2Id = :productId

            AND IsActive = true

            LIMIT 1

        ];


        if (!contractEntries.isEmpty()) {

            result.contractPrice =
                contractEntries[0].UnitPrice;

            result.hasContractPrice =
                result.contractPrice != null;

        }


        return result;

    }


    /*
     * ============================================================
     * 8. CONTRACT PRODUCT CATALOG
     *
     * Lists all active products in the current contract's
     * price book, with reference (strikethrough) and contract
     * prices. Reuses the same reference-price priority as
     * getContractProductPricing().
     * ============================================================
     */

    @AuraEnabled(cacheable=true)
    public static ContractProductCatalogInfo getContractProductCatalog() {

        ContractProductCatalogInfo result =
            new ContractProductCatalogInfo();

        result.products =
            new List<CatalogProductItem>();

        result.productCount = 0;


        Contact contact =
            getCurrentContact();


        if (
            contact == null ||
            contact.AccountId == null
        ) {

            result.message =
                'No company account was found for the logged-in user.';

            return result;

        }


        Contract con =
            getCurrentContract(
                contact.AccountId
            );


        if (con == null) {

            result.message =
                'No contract was found for your company.';

            return result;

        }


        result.contractNumber =
            con.ContractNumber;


        result.priceBookName =
            con.Pricebook2 != null
                ? con.Pricebook2.Name
                : null;


        if (con.Pricebook2Id == null) {

            result.message =
                'Your contract does not have a price book configured.';

            return result;

        }


        List<PricebookEntry> contractEntries = [

            SELECT
                Id,
                UnitPrice,
                Product2Id,
                Product2.Name,
                Product2.StockKeepingUnit

            FROM PricebookEntry

            WHERE Pricebook2Id = :con.Pricebook2Id

            AND IsActive = true

            AND Product2Id != null

            ORDER BY Product2.Name ASC

            LIMIT 200

        ];


        if (contractEntries.isEmpty()) {

            result.message =
                'No products are available in your contract price book.';

            return result;

        }


        Set<Id> productIds =
            new Set<Id>();


        for (PricebookEntry entry : contractEntries) {

            productIds.add(
                entry.Product2Id
            );

        }


        Map<Id, Decimal> strikethroughPrices =
            new Map<Id, Decimal>();


        for (PricebookEntry entry : [

            SELECT
                Product2Id,
                UnitPrice

            FROM PricebookEntry

            WHERE Product2Id IN :productIds

            AND Pricebook2.Name = :STRIKETHROUGH_PRICEBOOK_NAME

            AND IsActive = true

        ]) {

            strikethroughPrices.put(
                entry.Product2Id,
                entry.UnitPrice
            );

        }


        Map<Id, Decimal> standardPrices =
            new Map<Id, Decimal>();


        for (PricebookEntry entry : [

            SELECT
                Product2Id,
                UnitPrice

            FROM PricebookEntry

            WHERE Product2Id IN :productIds

            AND Pricebook2.IsStandard = true

            AND IsActive = true

        ]) {

            standardPrices.put(
                entry.Product2Id,
                entry.UnitPrice
            );

        }


        for (PricebookEntry entry : contractEntries) {

            CatalogProductItem item =
                new CatalogProductItem();


            item.productId =
                entry.Product2Id;


            item.productName =
                entry.Product2.Name;


            item.sku =
                entry.Product2.StockKeepingUnit;


            item.contractPrice =
                entry.UnitPrice;


            if (
                strikethroughPrices.containsKey(
                    entry.Product2Id
                )
            ) {

                item.referencePrice =
                    strikethroughPrices.get(
                        entry.Product2Id
                    );

                item.hasReferencePrice =
                    item.referencePrice != null;

            }
            else if (
                standardPrices.containsKey(
                    entry.Product2Id
                )
            ) {

                item.referencePrice =
                    standardPrices.get(
                        entry.Product2Id
                    );

                item.hasReferencePrice =
                    item.referencePrice != null;

            }
            else {

                item.hasReferencePrice = false;

            }


            if (
                item.hasReferencePrice &&
                item.referencePrice != null &&
                item.contractPrice != null &&
                item.referencePrice >
                item.contractPrice
            ) {

                item.savingsAmount =
                    item.referencePrice -
                    item.contractPrice;


                if (item.referencePrice != 0) {

                    item.savingsPercent =
                        (
                            (
                                item.savingsAmount /
                                item.referencePrice
                            ) * 100
                        ).setScale(2);

                }

            }


            result.products.add(item);

        }


        result.productCount =
            result.products.size();


        result.message =
            'Products available under your contract pricing.';


        return result;

    }

}