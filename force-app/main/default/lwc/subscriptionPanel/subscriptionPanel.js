import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import Id from '@salesforce/community/Id';
import getSellingModels from '@salesforce/apex/CommerceSubscriptionController.getSellingModels';
import addToCart from '@salesforce/apex/CommerceSubscriptionController.addToCart';

export default class SubscriptionPanel extends LightningElement {

    @track options = [];
    @track selectedOption;
    @track error;
    @track successMessage;

    productId;
    communityId = Id;

    @wire(CurrentPageReference)
    pageRef(pageRef) {
        if (!pageRef) {
            return;
        }

        this.productId =
            pageRef.attributes?.recordId ||
            pageRef.state?.recordId ||
            pageRef.attributes?.objectId;

        if (!this.productId) {
            console.warn('No productId resolved from pageRef', pageRef);
            return;
        }

        this.loadSellingModels();
    }

    loadSellingModels() {
        getSellingModels({ productId: this.productId })
            .then(result => {
                this.options = result.map(item => ({
    label: item.pricingTerm
        ? `${item.sellingModelName} (${item.pricingTerm} ${item.pricingTermUnit})`
        : item.sellingModelName,
    value: item.sellingModelId   // CHANGED from item.optionId
}));
                this.error = undefined;
            })
            .catch(error => {
                console.error('getSellingModels error:', error);
                this.error = error?.body?.message || 'Unknown error loading purchase options';
            });
    }

    get isAddToCartDisabled() {
        return !this.selectedOption;
    }

    handleSelection(event) {
        this.selectedOption = event.detail.value;
        this.successMessage = undefined;
    }

    handleAddToCart() {
        addToCart({
            communityId: this.communityId,
            productId: this.productId,
            sellingModelId: this.selectedOption,
            quantity: 1
        })
            .then(() => {
                this.error = undefined;
                this.successMessage = 'Added to cart!'; 
            })
            .catch(error => {
                console.error('addToCart error:', error);
                this.error = error?.body?.message || 'Could not add to cart';
                this.successMessage = undefined;
            });
    }
}