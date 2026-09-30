import { LightningElement, wire } from 'lwc';
import getDealerCredit from '@salesforce/apex/DealerCreditController.getDealerCredit';

export default class DealerCreditSummary extends LightningElement {
    creditLimit;
    usedCredit;
    availableCredit;
    error;

    @wire(getDealerCredit)
    wiredDealerCredit({ data, error }) {
        console.log('========== DEALER CREDIT DEBUG ==========');
        console.log('DATA:', JSON.stringify(data));
        console.log('ERROR:', JSON.stringify(error));

        if (data) {
            console.log('Credit Limit:', data.Purchase_Order_Credit_Limit__c);
            console.log('Used Credit:', data.Purchase_Order_Used_Credit__c);
            console.log('Available Credit:', data.Purchase_Order_Available_Credit__c);

            this.creditLimit = data.Purchase_Order_Credit_Limit__c;
            this.usedCredit = data.Purchase_Order_Used_Credit__c;
            this.availableCredit = data.Purchase_Order_Available_Credit__c;
            this.error = undefined;

        } else if (error) {
            console.error('ERROR FROM APEX:', error);

            this.error = error;
            this.creditLimit = undefined;
            this.usedCredit = undefined;
            this.availableCredit = undefined;
        }
    }

    get formattedCreditLimit() {
        return this.formatCurrency(this.creditLimit);
    }

    get formattedUsedCredit() {
        return this.formatCurrency(this.usedCredit);
    }

    get formattedAvailableCredit() {
        return this.formatCurrency(this.availableCredit);
    }

    formatCurrency(value) {
        if (value === undefined || value === null) {
            return '$0.00';
        }

        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(value);
    }
}