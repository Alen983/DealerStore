import { LightningElement, wire } from 'lwc';
import { CheckoutComponentBase } from 'commerce/checkoutApi';
import { CartSummaryAdapter } from 'commerce/cartApi';

import getDealerCredit from '@salesforce/apex/DealerCreditController.getDealerCredit';

export default class DealerCreditCheckoutValidator extends CheckoutComponentBase {

    cartId;
    cartTotal;

    availableCredit;

    showError = false;
    errorMessage = '';

    @wire(CartSummaryAdapter)
    wiredCartSummary({ data, error }) {

        if (data) {

            console.log(
                '========== CREDIT CHECKOUT CART DEBUG =========='
            );

            console.log(
                'CART SUMMARY:',
                JSON.stringify(data)
            );

            this.cartId = data.cartId;

            this.cartTotal = data.grandTotalAmount;

            console.log(
                'CART ID:',
                this.cartId
            );

            console.log(
                'CART TOTAL:',
                this.cartTotal
            );

        } else if (error) {

            console.error(
                'CART SUMMARY ERROR:',
                JSON.stringify(error)
            );

            this.cartId = undefined;
            this.cartTotal = undefined;
        }
    }


    @wire(getDealerCredit)
    wiredDealerCredit({ data, error }) {

        if (data) {

            this.availableCredit =
                data.Purchase_Order_Available_Credit__c;

            console.log(
                'AVAILABLE CREDIT:',
                this.availableCredit
            );

        } else if (error) {

            console.error(
                'DEALER CREDIT ERROR:',
                JSON.stringify(error)
            );

            this.availableCredit = undefined;
        }
    }


    get isCreditExceeded() {

        if (
            this.cartTotal === undefined ||
            this.cartTotal === null ||
            this.availableCredit === undefined ||
            this.availableCredit === null
        ) {
            return false;
        }

        return this.cartTotal > this.availableCredit;
    }


    get formattedCartTotal() {

        if (
            this.cartTotal === undefined ||
            this.cartTotal === null
        ) {
            return '$0.00';
        }

        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(this.cartTotal);
    }


    get formattedAvailableCredit() {

        if (
            this.availableCredit === undefined ||
            this.availableCredit === null
        ) {
            return '$0.00';
        }

        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(this.availableCredit);
    }


    async stageAction(checkoutStage) {

        console.log(
            'CREDIT VALIDATOR CHECKOUT STAGE:',
            checkoutStage
        );

        /*
         * Allow normal checkout processing
         * during the normal validity update.
         */
        if (checkoutStage === 'CHECK_VALIDITY_UPDATE') {
            return true;
        }


        /*
         * Perform the actual credit check
         * when the customer attempts to place
         * the order.
         */
        if (checkoutStage === 'REPORT_VALIDITY_SAVE') {

            console.log(
                '========== PURCHASE ORDER CREDIT CHECK =========='
            );

            console.log(
                'CART TOTAL:',
                this.cartTotal
            );

            console.log(
                'AVAILABLE CREDIT:',
                this.availableCredit
            );

            console.log(
                'CREDIT EXCEEDED:',
                this.isCreditExceeded
            );


            if (this.isCreditExceeded) {

                this.showError = true;

                this.errorMessage =
                    'Order blocked due to insufficient credit limit.';

                console.log(
                    '❌ ORDER BLOCKED - INSUFFICIENT CREDIT'
                );

                return false;
            }


            this.showError = false;
            this.errorMessage = '';

            console.log(
                '✅ CREDIT CHECK PASSED - ORDER CAN PROCEED'
            );

            return true;
        }


        return true;
    }
}