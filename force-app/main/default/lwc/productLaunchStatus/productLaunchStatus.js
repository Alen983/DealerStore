import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getProduct from '@salesforce/apex/ProductLaunchStatusController.getProduct';

export default class ProductLaunchStatus extends LightningElement {

    product;
    productId;

    countdown = '';
    timer = null;

    isExclusive = false;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {

        if (!pageRef) {
            return;
        }

        this.productId = pageRef?.attributes?.recordId;

        if (!this.productId) {
            const path = window.location.pathname;
            const parts = path.split('/');

            this.productId = parts[parts.length - 1];
        }

        console.log('PRODUCT ID:', this.productId);

        if (this.productId) {
            this.loadProduct();
        }
    }

    loadProduct() {

        getProduct({
            productId: this.productId
        })
        .then(result => {

            console.log(
                'PRODUCT FROM SALESFORCE:',
                JSON.stringify(result)
            );

            this.product = result;

            this.startCountdown();
        })
        .catch(error => {

            console.error(
                'ERROR LOADING PRODUCT:',
                JSON.stringify(error)
            );

            this.isExclusive = false;
            this.countdown = '';
        });
    }

    startCountdown() {

        if (this.timer) {
            clearInterval(this.timer);
            this.timer = null;
        }

        if (
            !this.product ||
            !this.product.launchDate ||
            this.product.earlyAccess === null ||
            this.product.earlyAccess === undefined
        ) {

            console.error(
                'Missing Launch Date or Early Access Minutes'
            );

            this.isExclusive = false;
            this.countdown = '';

            return;
        }

        /*
         * Salesforce sends the Datetime as an ISO timestamp.
         * Do NOT manually add/subtract the Indian timezone.
         */

        const launchTime = Date.parse(this.product.launchDate);

        const earlyAccessMinutes =
            Number(this.product.earlyAccess);

        const exclusiveEndTime =
            launchTime +
            (earlyAccessMinutes * 60 * 1000);

        console.log(
            'Launch Date from Salesforce:',
            this.product.launchDate
        );

        console.log(
            'Launch Timestamp:',
            launchTime
        );

        console.log(
            'Early Access Minutes:',
            earlyAccessMinutes
        );

        console.log(
            'Exclusive End:',
            new Date(exclusiveEndTime).toString()
        );

        console.log(
            'Exclusive End ISO:',
            new Date(exclusiveEndTime).toISOString()
        );

        console.log(
            'Browser Current Time:',
            new Date().toString()
        );

        /*
         * Run immediately.
         */
        this.updateCountdown(exclusiveEndTime);

        /*
         * Then update every second.
         */
        this.timer = setInterval(() => {

            this.updateCountdown(exclusiveEndTime);

        }, 1000);
    }

    updateCountdown(endTime) {

        const now = Date.now();

        const difference = endTime - now;

        /*
         * GOLD EXCLUSIVE PERIOD HAS ENDED
         */
        if (difference <= 0) {

            this.isExclusive = false;
            this.countdown = '';

            if (this.timer) {
                clearInterval(this.timer);
                this.timer = null;
            }

            console.log(
                'GOLD ACCESS ENDED - AVAILABLE TO ALL'
            );

            return;
        }

        /*
         * GOLD EXCLUSIVE PERIOD IS ACTIVE
         */
        this.isExclusive = true;

        const totalSeconds =
            Math.floor(difference / 1000);

        const hours =
            Math.floor(totalSeconds / 3600);

        const minutes =
            Math.floor(
                (totalSeconds % 3600) / 60
            );

        const seconds =
            totalSeconds % 60;

        this.countdown =
            `${String(hours).padStart(2, '0')}:` +
            `${String(minutes).padStart(2, '0')}:` +
            `${String(seconds).padStart(2, '0')}`;

    }

    disconnectedCallback() {

        if (this.timer) {

            clearInterval(this.timer);
            this.timer = null;
        }
    }
}