import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import getContractProductPricing
    from '@salesforce/apex/ContractStoreController.getContractProductPricing';


const MAX_URL_RETRIES = 8;
const RETRY_DELAY_MS = 250;


export default class ContractProductPrice extends LightningElement {

    @api recordId;

    productId;

    pricing;
    error;
    loading = true;

    urlRetryCount = 0;


    /*
     * Get the current page information.
     *
     * On the B2B Commerce product page the URL contains
     * the Product2 Id.
     */
    @wire(CurrentPageReference)
    pageReference;


    connectedCallback() {

        this.resolveProductId();

    }


    renderedCallback() {

        /*
         * Sometimes CurrentPageReference / the URL is populated
         * after connectedCallback. Try again if we don't have
         * the Product Id yet.
         */
        if (!this.productId) {
            this.resolveProductId();
        }

    }


    /*
     * ============================================================
     * PRODUCT ID RESOLUTION - UNCHANGED, WORKING LOGIC
     *
     * Tries, in order:
     *   1. recordId supplied to the component
     *   2. CurrentPageReference attributes/state
     *   3. The last URL path segment
     *
     * If none of these resolve yet (the SPA router may still be
     * finishing navigation when this component mounts), retries
     * a few times with a short delay before giving up gracefully.
     * ============================================================
     */

    resolveProductId() {

        if (this.productId) {
            return;
        }


        /*
         * 1. recordId supplied by the page.
         */
        if (this.recordId) {

            this.setProductId(this.recordId);

            return;

        }


        /*
         * 2. CurrentPageReference attributes/state.
         */
        if (this.pageReference) {

            const attributes =
                this.pageReference.attributes || {};

            const state =
                this.pageReference.state || {};


            const possibleId =
                attributes.recordId ||
                attributes.productId ||
                state.recordId ||
                state.productId;


            if (
                possibleId &&
                this.isSalesforceId(possibleId)
            ) {

                this.setProductId(possibleId);

                return;

            }

        }


        /*
         * 3. URL fallback.
         *
         * B2B Commerce product URLs commonly look like:
         *
         * /product/electric-shaver/01tg5000006KdRZAA0
         */
        const urlId =
            this.getProductIdFromUrl();


        if (urlId) {

            this.setProductId(urlId);

            return;

        }


        /*
         * 4. Not resolved yet - retry shortly. The SPA router
         * may still be finishing the navigation when this
         * component first mounts. Give up gracefully after
         * a bounded number of attempts so we never spin forever.
         */
        if (this.urlRetryCount < MAX_URL_RETRIES) {

            this.urlRetryCount++;

            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {

                this.resolveProductId();

            }, RETRY_DELAY_MS);

        } else {

            this.loading = false;

        }

    }


    getProductIdFromUrl() {

        try {

            const path =
                window.location.pathname;

            const parts =
                path.split('/').filter(Boolean);


            if (parts.length === 0) {

                return null;

            }


            const lastPart =
                parts[parts.length - 1];


            return this.isSalesforceId(lastPart)
                ? lastPart
                : null;

        } catch (e) {

            return null;

        }

    }


    isSalesforceId(value) {

        if (!value) {
            return false;
        }


        /*
         * Salesforce IDs are normally
         * 15 or 18 characters.
         */

        return /^[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?$/
            .test(value);

    }


    setProductId(id) {

        if (this.productId === id) {
            return;
        }

        this.productId = id;

        this.loadPricing();

    }


    /*
     * ============================================================
     * IMPERATIVE APEX CALL
     *
     * Called explicitly once we have a resolved productId,
     * instead of relying on reactive @wire timing.
     * ============================================================
     */

    loadPricing() {

        if (!this.productId) {
            return;
        }

        this.loading = true;
        this.error = undefined;
        this.pricing = undefined;


        getContractProductPricing({
            productId: this.productId
        })

        .then(result => {

            this.pricing = result;
            this.error = undefined;

        })

        .catch(error => {

            this.pricing = undefined;

            this.error =
                error?.body?.message ||
                'Unable to load contract pricing.';

        })

        .finally(() => {

            this.loading = false;

        });

    }


    get hasPricing() {

        return !!(
            this.pricing &&
            this.pricing.hasContractPrice
        );

    }


    get showListPrice() {

        return (
            this.hasPricing &&
            this.pricing.listPrice != null &&
            this.pricing.contractPrice != null &&
            this.pricing.listPrice >
            this.pricing.contractPrice
        );

    }


    get formattedListPrice() {

        if (
            !this.pricing ||
            this.pricing.listPrice == null
        ) {
            return '';
        }


        return Number(
            this.pricing.listPrice
        ).toFixed(2);

    }


    get formattedContractPrice() {

        if (
            !this.pricing ||
            this.pricing.contractPrice == null
        ) {
            return '';
        }


        return Number(
            this.pricing.contractPrice
        ).toFixed(2);

    }


    /*
     * Savings are shown only when the original/reference price
     * is strictly greater than the contract price.
     * Equal or higher contract prices produce no discount line.
     */

    get showSavings() {

        return this.showListPrice;

    }


    get savingsAmount() {

        if (!this.showSavings) {
            return null;
        }


        return Number(
            this.pricing.listPrice
        ) - Number(
            this.pricing.contractPrice
        );

    }


    get formattedSavingsAmount() {

        if (this.savingsAmount == null) {
            return '';
        }


        return this.savingsAmount.toFixed(2);

    }


    get formattedSavingsPercentage() {

        if (
            !this.showSavings ||
            this.pricing.listPrice == null ||
            Number(this.pricing.listPrice) === 0
        ) {
            return '';
        }


        const percentage =
            (
                this.savingsAmount /
                Number(this.pricing.listPrice)
            ) * 100;


        return percentage.toFixed(2);

    }


    /*
     * ============================================================
     * "NO PRICING" STATE
     *
     * True once loading has finished, there is no error, and
     * no contract price was found for this product/customer.
     * This keeps the component from ever silently rendering
     * completely blank with no explanation.
     * ============================================================
     */

    get showNoPricing() {

        return (
            !this.loading &&
            !this.error &&
            !this.hasPricing
        );

    }


    get noPricingReason() {

        if (!this.productId) {

            return 'No product could be identified for this page.';

        }


        if (!this.pricing) {

            return 'No contract pricing is available for this product.';

        }


        if (!this.pricing.contractNumber) {

            return 'No contract was found for your account, so contract pricing is unavailable.';

        }


        return 'This product is not included in your current contract pricing.';

    }

}