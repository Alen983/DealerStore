import { LightningElement, api, wire } from 'lwc';
import getEligibility from '@salesforce/apex/OrderCancellationController.getEligibility';
import submitRequest from '@salesforce/apex/OrderCancellationController.submitRequest';

const REASON_OPTIONS = [
    { label: 'Wrong quantity', value: 'Wrong quantity' },
    { label: 'Duplicate order', value: 'Duplicate order' },
    { label: 'Customer cancelled', value: 'Customer cancelled' },
    { label: 'Pricing issue', value: 'Pricing issue' },
    { label: 'Other', value: 'Other' }
];

export default class OrderCancellationRequest extends LightningElement {
    @api orderSummaryId;

    reasonOptions = REASON_OPTIONS;

    isLoading = true;
    isSubmitting = false;
    isModalOpen = false;

    canRequest = false;
    hasOpenRequest = false;
    caseNumber;
    caseId;
    orderNumber;
    eligibilityMessage;

    selectedReason = '';
    comments = '';
    acknowledged = false;

    submitSuccess = false;
    submitMessage = '';
    submitError = '';

    @wire(getEligibility, { orderSummaryId: '$orderSummaryId' })
    wiredEligibility({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.canRequest = data.canRequest;
            this.hasOpenRequest = data.hasOpenRequest;
            this.caseNumber = data.caseNumber;
            this.caseId = data.caseId;
            this.orderNumber = data.orderNumber;
            this.eligibilityMessage = data.message;
        } else if (error) {
            this.canRequest = false;
            this.hasOpenRequest = false;
            this.eligibilityMessage =
                'We could not load cancellation options for this order.';
        }
    }

    get showRequestButton() {
        return !this.isLoading && this.canRequest && !this.submitSuccess;
    }

    get showPendingBanner() {
        return !this.isLoading && this.hasOpenRequest && !this.submitSuccess;
    }

    get showSuccessBanner() {
        return this.submitSuccess;
    }

    get showIneligibleMessage() {
        return (
            !this.isLoading &&
            !this.canRequest &&
            !this.hasOpenRequest &&
            !this.submitSuccess &&
            this.eligibilityMessage
        );
    }

    get isSubmitDisabled() {
        return (
            this.isSubmitting ||
            !this.selectedReason ||
            !this.acknowledged
        );
    }

    get modalTitle() {
        return this.orderNumber
            ? `Request cancellation — ${this.orderNumber}`
            : 'Request cancellation';
    }

    openModal() {
        this.submitError = '';
        this.isModalOpen = true;
    }

    closeModal() {
        if (this.isSubmitting) {
            return;
        }
        this.isModalOpen = false;
    }

    handleReasonChange(event) {
        this.selectedReason = event.detail.value;
    }

    handleCommentsChange(event) {
        this.comments = event.detail.value;
    }

    handleAcknowledgedChange(event) {
        this.acknowledged = event.target.checked;
    }

    handleBackdropClick() {
        this.closeModal();
    }

    handleDialogClick(event) {
        event.stopPropagation();
    }

    async handleSubmit() {
        this.submitError = '';
        this.isSubmitting = true;

        try {
            const result = await submitRequest({
                orderSummaryId: this.orderSummaryId,
                reason: this.selectedReason,
                comments: this.comments,
                acknowledged: this.acknowledged
            });

            if (result.success) {
                this.submitSuccess = true;
                this.submitMessage = result.message;
                this.caseNumber = result.caseNumber;
                this.caseId = result.caseId;
                this.canRequest = false;
                this.hasOpenRequest = true;
                this.isModalOpen = false;
            } else {
                this.submitError =
                    result.message ||
                    'We could not submit your cancellation request.';
            }
        } catch (e) {
            this.submitError =
                'We could not submit your cancellation request. Please try again.';
        } finally {
            this.isSubmitting = false;
        }
    }
}
