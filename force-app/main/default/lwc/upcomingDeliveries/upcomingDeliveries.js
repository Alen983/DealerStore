import { LightningElement, wire } from 'lwc';
import getUpcomingDeliveries from '@salesforce/apex/RecurringOrderController.getUpcomingDeliveries';

export default class UpcomingDeliveries extends LightningElement {
    orderGroups = [];
    error;

    @wire(getUpcomingDeliveries)
    wiredDeliveries({ data, error }) {
        if (data) {
            this.orderGroups = data.map(group => ({
                contractId: group.contractId,
                frequency: group.frequency || 'N/A',
                status: group.status,
                lineItems: (group.lineItems || []).map(item => ({
                    id: item.Id,
                    productName: item.Product__r ? item.Product__r.Name : 'Unknown Product',
                    quantity: item.Quantity__c,
                    price: item.Contract_Price__c,
                    nextDelivery: item.Next_Delivery_Date__c
                }))
            }));
            this.error = undefined;
        } else if (error) {
            console.error('UPCOMING DELIVERIES ERROR:', JSON.stringify(error));
            this.error = error;
            this.orderGroups = [];
        }
    }
}