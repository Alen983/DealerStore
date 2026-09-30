import { LightningElement, track } from 'lwc';

import getReorderData
    from '@salesforce/apex/ReorderAssistantController.getReorderData';

import { getSessionContext }
    from 'commerce/contextApi';

import { NavigationMixin } 
    from 'lightning/navigation';



export default class ReorderAssistant extends NavigationMixin(LightningElement) {

    @track preferredCategory;
    @track contactName;
    @track products = [];

    isLoading = true;
    errorMessage;


    connectedCallback() {
        this.loadReorderAssistant();
    }


    async loadReorderAssistant() {

        try {

            // Get Commerce session context
            const sessionContext = await getSessionContext();

            console.log(
                'Reorder Assistant Session Context:',
                JSON.stringify(sessionContext, null, 2)
            );


            if (!sessionContext) {

                this.errorMessage =
                    'Unable to retrieve Commerce session information.';

                return;
            }


            // Get buyer account
            const accountId =
                sessionContext.effectiveAccountId;

            console.log(
                'Effective Buyer Account Id:',
                accountId
            );


            if (!accountId) {

                this.errorMessage =
                    'Unable to identify the buyer account.';

                return;
            }


            // Send account ID to Apex
            const data = await getReorderData({
                accountId: accountId
            });


            console.log(
                'Reorder Data:',
                JSON.stringify(data, null, 2)
            );

            console.log('FIRST PRODUCT:', data.products[0]);
            console.log('FIRST PRODUCT ID:', data.products[0]?.id);


            if (!data) {

                this.errorMessage =
                    'No reorder information found.';

                return;
            }


            // Get contact information
            this.contactName =
                data.contactName;

            // Get preferred category
            this.preferredCategory =
                data.preferredCategory;


            // Convert Salesforce Product data
            // into the format used by our HTML
            this.products =
                (data.products || []).map(product => {

                    return {
                        id: product.productId,
                        name: product.name,
                        sku: product.sku,
                        price: product.price
                    };

                });


            // No preferred category
            if (!this.preferredCategory) {

                this.errorMessage =
                    'No preferred product category found yet.';

                return;
            }


            // No products
            if (this.products.length === 0) {

                this.errorMessage =
                    'No products found for your preferred category.';

                return;
            }


            // Everything worked
            this.errorMessage = null;


        } catch (error) {

            console.error(
                'Reorder Assistant Error:',
                error
            );

            this.errorMessage =
                error?.body?.message ||
                error?.message ||
                'Unable to retrieve reorder information.';

        } finally {

            this.isLoading = false;

        }

    }

            handleViewProduct(event) {

        const productId =
            event.currentTarget.dataset.productId;

        const productName =
            event.currentTarget.dataset.productName;

        console.log(
            'VIEW PRODUCT - PRODUCT ID:',
            productId
        );

        console.log(
            'VIEW PRODUCT - PRODUCT NAME:',
            productName
        );

        if (!productId) {

            console.error(
                '❌ Product ID is missing.'
            );

            return;
        }

        const productSlug =
            productName
                .toLowerCase()
                .trim()
                .replace(/[^a-z0-9]+/g, '-')
                .replace(/^-+|-+$/g, '');

        const productUrl =
            `/dealerstore/product/${productSlug}/${productId}`;

        console.log(
            'PRODUCT URL:',
            productUrl
        );

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: productUrl
            }
        });

    }

}