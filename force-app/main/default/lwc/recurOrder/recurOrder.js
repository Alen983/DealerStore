import { LightningElement, wire } from 'lwc';
import { OrdersAdapter } from 'commerce/orderApi';

export default class RecurOrder extends LightningElement {
    showFlow = false;
    selectedOrderId;
    orders = [];
    error;

    @wire(OrdersAdapter)
    wiredOrders({ data, error }) {
        if (data) {
            const rawList = data.orderSummaries || [];
            const uniqueMap = new Map(
                rawList.map(o => [o.orderSummaryId, o])
            );

            this.orders = Array.from(uniqueMap.values()).map(order => ({
                ...order,
                formattedDate: order.orderedDate
                    ? new Date(order.orderedDate).toLocaleDateString('en-US')
                    : ''
            }));

            this.error = undefined;

        } else if (error) {
            console.error('ORDERS ADAPTER ERROR:', error);
            this.error = error;
            this.orders = [];
        }
    }

    handleRecurOrder(event) {
        this.selectedOrderId = event.currentTarget.dataset.orderId;

        console.log('===== SELECTED ORDER ID =====');
        console.log(this.selectedOrderId);
        console.log('=============================');

        if (this.selectedOrderId) {
            this.showFlow = true;
        }
    }

    get flowInputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.selectedOrderId
            }
        ];
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showFlow = false;
            this.selectedOrderId = null;
        }
    }
}