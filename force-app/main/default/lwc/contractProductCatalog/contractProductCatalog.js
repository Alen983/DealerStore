import { LightningElement, wire } from 'lwc';

import getContractProductCatalog
    from '@salesforce/apex/ContractStoreController.getContractProductCatalog';


export default class ContractProductCatalog extends LightningElement {

    catalog;

    error;

    loading = true;


    @wire(getContractProductCatalog)

    wiredCatalog({ data, error }) {

        this.loading = false;


        if (data) {

            this.catalog = {
                ...data,
                products: (data.products || []).map(
                    product => this.decorateProduct(product)
                )
            };

            this.error = undefined;

        }


        if (error) {

            this.catalog = undefined;

            this.error =
                error?.body?.message ||
                'Unable to load contract product catalog.';

        }

    }


    decorateProduct(product) {

        const referencePrice =
            product.referencePrice != null
                ? Number(product.referencePrice)
                : null;

        const contractPrice =
            product.contractPrice != null
                ? Number(product.contractPrice)
                : null;

        const hasSavings =
            product.savingsAmount != null &&
            product.savingsPercent != null &&
            referencePrice != null &&
            contractPrice != null &&
            referencePrice > contractPrice;


        return {
            ...product,
            displaySku:
                product.sku || '—',
            formattedReferencePrice:
                referencePrice != null
                    ? referencePrice.toFixed(2)
                    : null,
            formattedContractPrice:
                contractPrice != null
                    ? contractPrice.toFixed(2)
                    : '—',
            showReferencePrice:
                hasSavings,
            formattedSavingsAmount:
                hasSavings
                    ? Number(product.savingsAmount).toFixed(2)
                    : null,
            formattedSavingsPercent:
                hasSavings
                    ? Number(product.savingsPercent).toFixed(2)
                    : null,
            hasSavings
        };

    }


    get hasProducts() {

        return (
            this.catalog?.products?.length > 0
        );

    }


    get headerSummary() {

        if (!this.catalog?.priceBookName) {
            return '';
        }


        const count =
            this.catalog.productCount || 0;


        return `${this.catalog.priceBookName} · ${count} products`;

    }

}