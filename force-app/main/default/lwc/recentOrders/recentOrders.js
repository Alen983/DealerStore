import { LightningElement, wire } from 'lwc';

import getRecentOrders
    from '@salesforce/apex/ContractStoreController.getRecentOrders';


export default class RecentOrders extends LightningElement {

    orders = [];

    error;


    @wire(getRecentOrders)

    wiredOrders({ data, error }) {

        if (data) {

            this.orders =
                data.map(order => {

                    return {
                        ...order,
                        statusClass:
                            this.getStatusClass(order.status)
                    };

                });

            this.error = undefined;

        }


        if (error) {

            this.orders = [];

            this.error =
                error?.body?.message ||
                'Unable to load orders.';

        }

    }


    get hasOrders() {

        return this.orders.length > 0;

    }


    getStatusClass(status) {

        if (!status) {
            return 'status-badge';
        }

        const value =
            status.toLowerCase();

        if (
            value.includes('activate') ||
            value.includes('complete') ||
            value.includes('ship')
        ) {

            return 'status-badge success';

        }


        if (
            value.includes('cancel') ||
            value.includes('reject')
        ) {

            return 'status-badge error-badge';

        }


        return 'status-badge warning-badge';

    }


    handleViewOrders() {

        window.location.href =
            '/s/order-history';

    }

}