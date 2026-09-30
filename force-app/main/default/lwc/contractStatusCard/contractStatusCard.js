import { LightningElement } from 'lwc';

import getMyContract
    from '@salesforce/apex/ContractStoreController.getMyContract';


export default class ContractStatusCard extends LightningElement {

    contract;

    error;

    loading = true;


    connectedCallback() {

        this.loadContract();

    }


    /*
     * ============================================================
     * IMPERATIVE APEX CALL
     *
     * getMyContract() computes daysRemaining / progressPercent
     * based on Date.today(). Calling it imperatively (instead of
     * via a reactive @wire) guarantees the server recalculates
     * these values fresh every time this component loads, rather
     * than risking a stale, previously cached result from an
     * earlier day being shown by Lightning Data Service.
     * ============================================================
     */

    loadContract() {

        this.loading = true;

        this.error = undefined;


        getMyContract()

        .then(result => {

            this.contract = result;

            this.error = undefined;

        })

        .catch(error => {

            this.contract = undefined;

            this.error =
                error?.body?.message ||
                'Unable to load contract information.';

        })

        .finally(() => {

            this.loading = false;

        });

    }


    get hasContract() {

        return this.contract?.contractId != null;

    }


    get statusClass() {

        if (this.contract?.expired) {

            return 'status expired';

        }


        if (this.contract?.expiringSoon) {

            return 'status expiring';

        }


        return 'status active';

    }


    get statusLabel() {

        if (this.contract?.expired) {

            return 'EXPIRED';

        }


        if (this.contract?.expiringSoon) {

            return 'EXPIRING SOON';

        }


        return 'ACTIVE';

    }


    get progressStyle() {

        const percentage =
            this.contract?.progressPercent ?? 0;

        return `width: ${percentage}%;`;

    }


    get progressPercentLabel() {

        const percentage =
            this.contract?.progressPercent ?? 0;

        return `${percentage}%`;

    }


    get pricingEnabled() {

        return this.contract?.pricingEnabled;

    }


    get showPriceBookName() {

        return !!this.contract?.priceBookName;

    }


    get expiringSoon() {

        return this.contract?.expiringSoon;

    }


    get isExpired() {

        return this.contract?.expired;

    }

}