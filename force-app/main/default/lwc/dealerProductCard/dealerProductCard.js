import { LightningElement, api, wire } from 'lwc';
import { resolve } from 'experience/resourceResolver';
import { NavigationContext, generateUrl, navigate } from 'lightning/navigation';
import { AppContextAdapter, SessionContextAdapter } from 'commerce/contextApi';
import { CartStatusAdapter } from 'commerce/cartApi';
import { ProductPricingAdapter } from 'commerce/productApi';
import { createCartItemAddAction, dispatchAction } from 'commerce/actionApi';
import { trackAddProductToCart } from 'commerce/activitiesApi';

const FEATURES = [
    'Includes premium attachments',
    'Advanced cleaning power',
    'Lightweight and versatile',
    'Professional-grade results'
];

export default class DealerProductCard extends LightningElement {
    @api item;

    _adding = false;

    @wire(NavigationContext)
    navContext;

    @wire(CartStatusAdapter)
    cartStatus;

    @wire(SessionContextAdapter)
    sessionContext;

    @wire(AppContextAdapter)
    appContext;

    @wire(ProductPricingAdapter, { productId: '$productId' })
    wiredPricing;

    get displayData() {
        return this.item || null;
    }

    get productId() {
        return this.displayData?.id || '';
    }

    get productName() {
        return this.displayData?.name || '';
    }

    get imageUrl() {
        const img = this.displayData?.image || this.displayData?.defaultImage;
        const rawUrl = img?.url || img?.thumbnailUrl || '';
        if (!rawUrl) {
            return '';
        }
        return resolve(rawUrl, false, {
            height: 460,
            width: 460
        });
    }

    get imageAlt() {
        const img = this.displayData?.image || this.displayData?.defaultImage;
        return img?.alternateText || img?.title || this.productName;
    }

    get sku() {
        const fields = this.displayData?.fields;
        if (Array.isArray(fields)) {
            const match = fields.find(
                (f) =>
                    f.name === 'StockKeepingUnit' ||
                    f.name === 'Sku' ||
                    f.name === 'SKU' ||
                    f.type === 'sku'
            );
            if (match?.value) {
                return match.value;
            }
        } else if (fields && typeof fields === 'object') {
            const skuField = fields.StockKeepingUnit;
            if (typeof skuField === 'string') {
                return skuField;
            }
            if (skuField?.value) {
                return skuField.value;
            }
        }
        return this.displayData?.stockKeepingUnit || this.displayData?.sku || '';
    }

    get negotiatedPrice() {
        return (
            this.displayData?.prices?.negotiatedPrice ||
            this.wiredPricing?.data?.unitPrice ||
            this.wiredPricing?.data?.lowestUnitPrice ||
            ''
        );
    }

    get listingPrice() {
        return (
            this.displayData?.prices?.listingPrice ||
            this.wiredPricing?.data?.listPrice ||
            ''
        );
    }

    get displayNegotiatedPrice() {
        const price = this.negotiatedPrice;
        if (!price || price === 'Price Unavailable' || price.startsWith('$')) {
            return price;
        }
        return `$${price}`;
    }

    get displayListingPrice() {
        const price = this.listingPrice;
        if (!price || price.startsWith('$')) {
            return price;
        }
        return `$${price}`;
    }

    get showListingPrice() {
        return (
            this.listingPrice &&
            this.negotiatedPrice &&
            this.listingPrice !== this.negotiatedPrice
        );
    }

    get priceLoading() {
        if (this.negotiatedPrice) {
            return false;
        }
        return (
            !!this.displayData?.prices?.isLoading ||
            !!this.wiredPricing?.loading
        );
    }

    get features() {
        return FEATURES;
    }

    get badgeLabel() {
        const hash = [...(this.productId || this.productName)].reduce(
            (sum, ch) => sum + ch.charCodeAt(0),
            0
        );
        if (hash % 4 === 3) {
            return 'Sale';
        }
        if (hash % 4 === 1) {
            return 'New';
        }
        return '';
    }

    get badgeClass() {
        return this.badgeLabel === 'Sale' ? 'badge badge--sale' : 'badge badge--new';
    }

    get isCartProcessing() {
        return !!this.cartStatus?.data?.isProcessing || !!this.cartStatus?.loading;
    }

    get isAddToCartEnabled() {
        const isLoggedIn = Boolean(this.sessionContext?.data?.isLoggedIn);
        const guestCartEnabled = Boolean(this.appContext?.data?.guestCartEnabled);
        return isLoggedIn || guestCartEnabled;
    }

    get addToCartDisabled() {
        return (
            this._adding ||
            this.isCartProcessing ||
            !this.productId ||
            this.negotiatedPrice === 'Price Unavailable'
        );
    }

    get addToCartLabel() {
        if (this._adding) {
            return 'Adding...';
        }
        if (this.isCartProcessing) {
            return 'Processing...';
        }
        return 'Add to cart';
    }

    get productUrl() {
        if (!this.navContext || !this.productId) {
            return null;
        }
        return generateUrl(this.navContext, {
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'Product2',
                recordId: this.productId,
                actionName: 'view',
                urlName: this.displayData?.urlName || undefined
            }
        });
    }

    handleProductClick(event) {
        if (this.productUrl) {
            return;
        }
        event.preventDefault();
        this.navigateToProduct();
    }

    navigateToProduct() {
        if (!this.productId || !this.navContext) {
            return;
        }
        navigate(this.navContext, {
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'Product2',
                recordId: this.productId,
                actionName: 'view',
                urlName: this.displayData?.urlName || undefined
            },
            state: {
                recordName: this.productName
            }
        });
    }

    handleAddToCart(event) {
        event.preventDefault();
        event.stopPropagation();
        if (this.addToCartDisabled) {
            return;
        }
        if (!this.isAddToCartEnabled) {
            if (this.navContext) {
                navigate(this.navContext, {
                    type: 'comm__namedPage',
                    attributes: { name: 'Login' }
                });
            }
            return;
        }

        this._adding = true;
        dispatchAction(this, createCartItemAddAction(this.productId, 1), {
            onSuccess: () => {
                trackAddProductToCart(this.productId);
                this._adding = false;
            },
            onError: () => {
                this._adding = false;
            }
        });
    }
}
