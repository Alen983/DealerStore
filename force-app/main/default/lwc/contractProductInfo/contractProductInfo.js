import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import checkProductContract
    from '@salesforce/apex/ContractStoreController.checkProductContract';

export default class ContractProductInfo extends LightningElement {

    productId;

    productInfo;

    error;

    loading = true;


    // Get the current Experience Cloud URL
    @wire(CurrentPageReference)
    pageReference;


    connectedCallback() {

        this.getProductIdFromUrl();

    }


    renderedCallback() {

        // Sometimes the Commerce page URL is available
        // after the component is initially rendered.
        if (!this.productId) {

            this.getProductIdFromUrl();

        }

    }


    getProductIdFromUrl() {

        try {

            const path = window.location.pathname;

            console.log(
                'ContractProductInfo URL:',
                path
            );


            /*
             * Expected Commerce URL:
             *
             * /contractstore26/product/electric-shaver/01tg50000006KdRZAA0
             *
             * Salesforce Product Id is the last URL segment.
             */

            const parts = path
                .split('/')
                .filter(Boolean);


            const lastPart =
                parts.length > 0
                    ? parts[parts.length - 1]
                    : null;


            if (
                lastPart &&
                this.isSalesforceId(lastPart)
            ) {

                if (this.productId !== lastPart) {

                    this.productId = lastPart;

                    console.log(
                        'Product ID found:',
                        this.productId
                    );

                    this.loadProductContract();

                }

            } else {

                console.log(
                    'No Salesforce Product ID found in URL.'
                );

            }

        } catch (e) {

            console.error(
                'Unable to determine Product ID:',
                e
            );

            this.loading = false;

            this.error =
                'Unable to determine the current product.';

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


    loadProductContract() {

        this.loading = true;

        this.error = undefined;

        this.productInfo = undefined;


        checkProductContract({
            productId: this.productId
        })

        .then(result => {

            console.log(
                'Product contract result:',
                JSON.stringify(result)
            );


            this.productInfo = result;

            this.error = undefined;

        })

        .catch(error => {

            console.error(
                'Product contract error:',
                error
            );


            this.productInfo = undefined;


            if (error?.body?.message) {

                this.error =
                    error.body.message;

            } else {

                this.error =
                    'Unable to verify contract.';

            }

        })

        .finally(() => {

            this.loading = false;

        });

    }


    get covered() {

        return this.productInfo?.covered === true;

    }


    get notCovered() {

        return (
            this.productInfo &&
            this.productInfo.covered === false
        );

    }

}