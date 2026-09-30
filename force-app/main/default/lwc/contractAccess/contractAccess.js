import { LightningElement, wire } from 'lwc';

import getContractAccess
    from '@salesforce/apex/ContractStoreController.getContractAccess';


export default class ContractAccess extends LightningElement {

    access;

    error;

    loading = true;


    @wire(getContractAccess)

    wiredAccess({ data, error }) {

        this.loading = false;


        if (data) {

            this.access = data;

            this.error = undefined;

        }


        if (error) {

            this.access = undefined;

            this.error =
                error?.body?.message ||
                'Unable to load contract access information.';

        }

    }


    get displayPriceBook() {
        return this.access?.priceBookName || 'Not assigned';
    }

    get displayTerms() {
        return this.access?.purchaseMethod || 'Standard terms apply';
    }

    get pricingLabel() {
        return this.access?.pricingEnabled ? 'Enabled' : 'Not Configured';
    }

    get pricingIconClass() {
        return this.access?.pricingEnabled
            ? 'item-icon pricing-icon pricing-on'
            : 'item-icon pricing-icon pricing-off';
    }

    get pricingTextClass() {
        return this.access?.pricingEnabled ? 'enabled' : 'disabled';
    }

    get statusBadgeClass() {
        const status = (this.access?.contractStatus || '').toLowerCase();

        if (status === 'activated') {
            return 'badge badge-active';
        }

        if (status === 'draft') {
            return 'badge badge-draft';
        }

        return 'badge badge-neutral';
    }

}