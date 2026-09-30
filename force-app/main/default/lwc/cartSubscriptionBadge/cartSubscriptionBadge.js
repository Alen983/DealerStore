import { LightningElement, wire } from 'lwc';
import getActiveCartId from '@salesforce/apex/CartSubscriptionBadgeController.getActiveCartId';
import getCartSubscriptionItems from '@salesforce/apex/CartSubscriptionBadgeController.getCartSubscriptionItems';

export default class CartSubscriptionBadge extends LightningElement {

    subscriptionItems = [];
    cartId;

    connectedCallback() {
        this.loadCartSubscriptions();
    }

    loadCartSubscriptions() {
        getActiveCartId()
            .then(cartId => {
                this.cartId = cartId;
                if (!cartId) {
                    this.subscriptionItems = [];
                    return;
                }
                return getCartSubscriptionItems({ cartId });
            })
            .then(result => {
                if (result) {
                    this.subscriptionItems = result.map(item => ({
                        id: item.Id,
                        productName: item.Product__r?.Name,
                        sellingModelName: item.Selling_Model__r?.Name,
                    }));
                }
            })
            .catch(error => {
                console.error('cartSubscriptionBadge error:', error);
            });
    }
}