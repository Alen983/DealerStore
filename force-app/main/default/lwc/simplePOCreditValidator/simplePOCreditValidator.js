import { LightningElement, wire } from 'lwc';
import { CheckoutComponentBase } from 'commerce/checkoutApi';
import { CartSummaryAdapter } from 'commerce/cartApi';

import validateCredit from '@salesforce/apex/SimplePOCreditValidatorController.validateCredit';

export default class SimplePOCreditValidator extends CheckoutComponentBase {

    cartId;
    showError = false;
    errorMessage = '';

    @wire(CartSummaryAdapter)
    wiredCart({ data, error }) {
        if (data) {
            this.cartId = data.cartId;

            console.log(
                'PO Credit Validator Cart ID:',
                this.cartId
            );
        }

        if (error) {
            console.error(
                'Cart Summary Error:',
                error
            );
        }
    }

    async stageAction(checkoutStage) {

        console.log(
            'PO Credit Validator Stage:',
            checkoutStage
        );

        // Allow normal checkout processing
        // without performing the credit check.
        if (checkoutStage === 'CHECK_VALIDITY_UPDATE') {
            return true;
        }

        // Perform credit validation when
        // checkout is trying to place the order.
        if (checkoutStage === 'REPORT_VALIDITY_SAVE') {

            console.log(
                'PO CREDIT CHECK: PLACE ORDER VALIDATION'
            );

            const isValid =
                await this.validatePurchaseOrderCredit();

            console.log(
                'PO CREDIT CHECK RESULT:',
                isValid
            );

            return isValid;
        }

        return true;
    }

    async validatePurchaseOrderCredit() {

        this.showError = false;
        this.errorMessage = '';

        console.log(
            'PO CREDIT VALIDATION STARTED'
        );

        if (!this.cartId) {

            console.error(
                'PO Credit Validator: Cart ID not available.'
            );

            this.errorMessage =
                'Unable to validate Purchase Order credit because the cart could not be identified.';

            this.showError = true;

            return false;
        }

        try {

            const result = await validateCredit({
                cartId: this.cartId
            });

            console.log(
                'PO Credit Validation Result:',
                JSON.stringify(result)
            );

            // CREDIT IS AVAILABLE
            if (result.withinLimit === true) {

                console.log(
                    'PO CREDIT CHECK PASSED'
                );

                return true;
            }

            // CREDIT IS EXCEEDED
            console.log(
                'PO CREDIT CHECK FAILED - ORDER BLOCKED'
            );

            this.errorMessage =
                result.message ||
                'Purchase Order credit limit exceeded.';

            this.showError = true;

            return false;

        } catch (error) {

            console.error(
                'PO Credit Validation Error:',
                error
            );

            this.errorMessage =
                'Unable to validate the Purchase Order credit limit. Please try again.';

            this.showError = true;

            return false;
        }
    }
}