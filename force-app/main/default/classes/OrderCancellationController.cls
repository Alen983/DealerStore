public with sharing class OrderCancellationController {
    private static final Set<String> ELIGIBLE_ORDER_STATUSES = new Set<String>{ 'Created' };

    private static final Set<String> VALID_REASONS = new Set<String>{
        'Wrong quantity',
        'Duplicate order',
        'Customer cancelled',
        'Pricing issue',
        'Other'
    };

    public class EligibilityResult {
        @AuraEnabled
        public Boolean canRequest { get; set; }

        @AuraEnabled
        public Boolean hasOpenRequest { get; set; }

        @AuraEnabled
        public String caseNumber { get; set; }

        @AuraEnabled
        public String caseId { get; set; }

        @AuraEnabled
        public String orderStatus { get; set; }

        @AuraEnabled
        public String orderNumber { get; set; }

        @AuraEnabled
        public String message { get; set; }
    }

    public class SubmitResult {
        @AuraEnabled
        public Boolean success { get; set; }

        @AuraEnabled
        public String caseNumber { get; set; }

        @AuraEnabled
        public String caseId { get; set; }

        @AuraEnabled
        public String message { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static EligibilityResult getEligibility(String orderSummaryId) {
        EligibilityResult result = new EligibilityResult();
        result.canRequest = false;
        result.hasOpenRequest = false;

        if (String.isBlank(orderSummaryId)) {
            result.message = 'Order information is missing.';
            return result;
        }

        OrderSummary orderSummary = loadAuthorizedOrderSummary(orderSummaryId);
        if (orderSummary == null) {
            result.message = 'We could not find this order for your account.';
            return result;
        }

        result.orderStatus = orderSummary.Status;
        result.orderNumber = orderSummary.OrderNumber;

        Case openCase = findOpenCancellationCase(orderSummaryId);
        if (openCase != null) {
            result.hasOpenRequest = true;
            result.caseNumber = openCase.CaseNumber;
            result.caseId = openCase.Id;
            result.message = 'A cancellation request is already under review.';
            return result;
        }

        if (!ELIGIBLE_ORDER_STATUSES.contains(orderSummary.Status)) {
            result.message =
                'Cancellation requests are only available while the order is being processed.';
            return result;
        }

        result.canRequest = true;
        result.message = 'You can submit a cancellation request for this order.';
        return result;
    }

    @AuraEnabled
    public static SubmitResult submitRequest(
        String orderSummaryId,
        String reason,
        String comments,
        Boolean acknowledged
    ) {
        SubmitResult result = new SubmitResult();
        result.success = false;

        if (String.isBlank(orderSummaryId)) {
            result.message = 'Order information is missing.';
            return result;
        }

        if (acknowledged != true) {
            result.message = 'Please confirm you understand the cancellation policy.';
            return result;
        }

        if (String.isBlank(reason) || !VALID_REASONS.contains(reason)) {
            result.message = 'Please select a valid cancellation reason.';
            return result;
        }

        if (!Schema.sObjectType.Case.isCreateable()) {
            result.message = 'You do not have permission to submit cancellation requests.';
            return result;
        }

        OrderSummary orderSummary = loadAuthorizedOrderSummary(orderSummaryId);
        if (orderSummary == null) {
            result.message = 'We could not find this order for your account.';
            return result;
        }

        if (findOpenCancellationCase(orderSummaryId) != null) {
            result.message = 'A cancellation request is already under review for this order.';
            return result;
        }

        if (!ELIGIBLE_ORDER_STATUSES.contains(orderSummary.Status)) {
            result.message =
                'This order is no longer eligible for a cancellation request.';
            return result;
        }

        Id buyerAccountId = getBuyerAccountId();
        Id buyerContactId = getBuyerContactId();
        String trimmedComments = String.isBlank(comments) ? '' : comments.trim();

        Case requestCase = new Case(
            Subject = 'Cancellation request — ' + orderSummary.OrderNumber,
            Description = buildDescription(reason, trimmedComments, orderSummary),
            Order_Summary__c = orderSummary.Id,
            Order_Number__c = orderSummary.OrderNumber,
            Cancellation_Reason__c = reason
        );

        if (buyerContactId != null && Schema.sObjectType.Case.fields.ContactId.isCreateable()) {
            requestCase.ContactId = buyerContactId;
        }

        if (buyerAccountId != null && Schema.sObjectType.Case.fields.AccountId.isCreateable()) {
            requestCase.AccountId = buyerAccountId;
        } else if (orderSummary.AccountId != null && Schema.sObjectType.Case.fields.AccountId.isCreateable()) {
            requestCase.AccountId = orderSummary.AccountId;
        }

        if (Schema.sObjectType.Case.fields.Origin.isCreateable()) {
            requestCase.Origin = 'Web';
        }

        if (Schema.sObjectType.Case.fields.Status.isCreateable()) {
            requestCase.Status = 'New';
        }

        if (requestCase.ContactId == null && requestCase.AccountId == null) {
            requestCase.SuppliedEmail = getCurrentUserEmail();
        }

        try {
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.CREATABLE,
                new List<Case>{ requestCase }
            );
            insert decision.getRecords();
            requestCase = (Case) decision.getRecords()[0];
            Case createdCase = [
                SELECT Id, CaseNumber
                FROM Case
                WHERE Id = :requestCase.Id
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            result.success = true;
            result.caseId = createdCase.Id;
            result.caseNumber = createdCase.CaseNumber;
            result.message =
                'Cancellation request submitted — reference #' + createdCase.CaseNumber;
        } catch (DmlException e) {
            result.message = buildDmlErrorMessage(e);
        }

        return result;
    }

    private static OrderSummary loadAuthorizedOrderSummary(String orderSummaryId) {
        Id buyerAccountId = getBuyerAccountId();
        List<OrderSummary> summaries = [
            SELECT Id, OrderNumber, Status, AccountId
            FROM OrderSummary
            WHERE Id = :orderSummaryId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (summaries.isEmpty()) {
            return null;
        }

        OrderSummary orderSummary = summaries[0];
        if (buyerAccountId != null && orderSummary.AccountId != buyerAccountId) {
            return null;
        }

        return orderSummary;
    }

    private static Case findOpenCancellationCase(String orderSummaryId) {
        List<Case> openCases = [
            SELECT Id, CaseNumber
            FROM Case
            WHERE
                Order_Summary__c = :orderSummaryId
                AND IsClosed = FALSE
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return openCases.isEmpty() ? null : openCases[0];
    }

    private static Id getBuyerAccountId() {
        List<User> users = [
            SELECT Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (users.isEmpty() || users[0].Contact == null) {
            return null;
        }

        return users[0].Contact.AccountId;
    }

    private static Id getBuyerContactId() {
        List<User> users = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (users.isEmpty()) {
            return null;
        }

        return users[0].ContactId;
    }

    private static String getCurrentUserEmail() {
        List<User> users = [
            SELECT Email
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return users.isEmpty() ? null : users[0].Email;
    }

    private static String buildDescription(
        String reason,
        String comments,
        OrderSummary orderSummary
    ) {
        List<String> lines = new List<String>{
            'Cancellation request submitted from Dealer Store.',
            'Order Number: ' + orderSummary.OrderNumber,
            'Order Summary Id: ' + orderSummary.Id,
            'Order Status: ' + orderSummary.Status,
            'Reason: ' + reason
        };

        if (String.isNotBlank(comments)) {
            lines.add('Comments: ' + comments);
        }

        lines.add('Buyer acknowledged cancellation is subject to review.');
        return String.join(lines, '\n');
    }

    private static String buildDmlErrorMessage(DmlException e) {
        if (e.getNumDml() > 0) {
            return 'We could not submit your request: ' + e.getDmlMessage(0);
        }
        return 'We could not submit your request. Please try again or contact support.';
    }
}
