import { LightningElement, wire } from 'lwc';
import getMyCompany from '@salesforce/apex/ContractStoreController.getMyCompany';

export default class AccountSummary extends LightningElement {

    company;
    error;

    @wire(getMyCompany)
    wiredCompany({ data, error }) {

        if (data) {
            this.company = data;
            this.error = undefined;
        }

        if (error) {
            this.error = error?.body?.message ||
                'Unable to load account information.';
        }
    }
}