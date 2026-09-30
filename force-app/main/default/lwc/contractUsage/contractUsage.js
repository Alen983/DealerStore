import { LightningElement, wire } from 'lwc';

import getContractUsage
    from '@salesforce/apex/ContractStoreController.getContractUsage';


export default class ContractUsage extends LightningElement {

    usage;

    error;


    @wire(getContractUsage)

    wiredUsage({ data, error }) {

        if (data) {

            this.usage = data;

            this.error = undefined;

        }


        if (error) {

            this.usage = undefined;

            this.error =
                error?.body?.message ||
                'Unable to load contract usage.';

        }

    }

}