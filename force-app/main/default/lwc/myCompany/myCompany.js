import { LightningElement, wire } from 'lwc';

import getMyCompany
    from '@salesforce/apex/ContractStoreController.getMyCompany';

export default class MyCompany extends LightningElement {

    company;
    error;
    loading = true;

    @wire(getMyCompany)
    wiredCompany({ data, error }) {

        this.loading = false;

        if (data) {
            this.company = data;
            this.error = undefined;
        } else if (error) {
            this.company = undefined;

            this.error =
                error?.body?.message ||
                'Unable to load company information.';
        }
    }

    get hasCompany() {
        return !!(
            this.company &&
            this.company.companyName
        );
    }

    get displayPhone() {
        return this.company?.phone || 'Not provided';
    }

    get displayEmail() {
        return this.company?.email || 'Not provided';
    }

    get displayIndustry() {
        return this.company?.industry || 'Not provided';
    }

    get displayWebsite() {
        return this.company?.website || 'Not provided';
    }

    get displayContact() {
        return this.company?.contactName || 'Not provided';
    }

    get companyInitial() {
        return this.company?.companyName
            ? this.company.companyName.charAt(0).toUpperCase()
            : '?';
    }
}