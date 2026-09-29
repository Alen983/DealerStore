import { LightningElement } from 'lwc';
import getProcurementBenefits from '@salesforce/apex/ProcurementBenefitsController.getProcurementBenefits';

const TIERS = [
    {
        key: 'basic',
        name: 'Basic',
        threshold: 2500,
        discount: 5,
        cssClass: 'mpb-tier mpb-tier--basic'
    },
    {
        key: 'premium',
        name: 'Premium',
        threshold: 5000,
        discount: 10,
        cssClass: 'mpb-tier mpb-tier--premium'
    },
    {
        key: 'elite',
        name: 'Elite',
        threshold: 10000,
        discount: 15,
        cssClass: 'mpb-tier mpb-tier--elite'
    }
];

export default class ProcurementBenefits extends LightningElement {
    totalSavings = 0;
    totalSpend = 0;
    highestOrderAmount = 0;
    currentTier = 'No Tier Achieved';
    isLoading = true;
    hasError = false;

    currencyFormatter = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    });

    async connectedCallback() {
        try {
            const result = await getProcurementBenefits();
            this.totalSavings = result.totalSavings ?? 0;
            this.totalSpend = result.totalSpend ?? 0;
            this.highestOrderAmount = result.highestOrderAmount ?? 0;
            this.currentTier = result.currentTier ?? 'No Tier Achieved';
        } catch (error) {
            this.hasError = true;
            console.error(error);
        } finally {
            this.isLoading = false;
        }
    }

    get formattedSavings() {
        return this.currencyFormatter.format(this.totalSavings);
    }

    get formattedTotalSpend() {
        return this.currencyFormatter.format(this.totalSpend);
    }

    get currentTierDiscount() {
        const tier = TIERS.find((t) => t.name === this.currentTier);
        return tier ? tier.discount : null;
    }

    get currentTierLabel() {
        if (this.currentTierDiscount) {
            return `${this.currentTier} · ${this.currentTierDiscount}% OFF`;
        }
        return this.currentTier;
    }

    get nextTier() {
        const currentIndex = TIERS.findIndex((t) => t.name === this.currentTier);
        if (currentIndex >= 0 && currentIndex < TIERS.length - 1) {
            return TIERS[currentIndex + 1];
        }
        if (this.currentTier === 'No Tier Achieved') {
            return TIERS[0];
        }
        return null;
    }

    get tierHint() {
        if (this.currentTier === 'Elite') {
            return `You're at Elite — ${this.formattedTotalSpend} total procurement spend unlocks 15% OFF on eligible orders.`;
        }

        const next = this.nextTier;
        if (next) {
            const remaining = next.threshold - this.totalSpend;
            if (remaining > 0) {
                return `Spend ${this.currencyFormatter.format(remaining)} more to reach ${next.name} (${next.discount}% OFF).`;
            }
        }

        return `Reach ${this.currencyFormatter.format(TIERS[0].threshold)} in total spend to unlock wholesale discounts.`;
    }

    get tierCards() {
        const currentIndex = TIERS.findIndex((t) => t.name === this.currentTier);

        return TIERS.map((tier, index) => {
            let cardClass = tier.cssClass;
            if (index === currentIndex) {
                cardClass += ' mpb-tier--current';
            } else if (currentIndex >= 0 && index < currentIndex) {
                cardClass += ' mpb-tier--achieved';
            }

            return {
                ...tier,
                cardClass,
                thresholdLabel: `$${tier.threshold.toLocaleString('en-US')}+ total spend`,
                discountLabel: `${tier.discount}% OFF`,
                isCurrent: index === currentIndex
            };
        });
    }

    get showEmptyState() {
        return !this.isLoading && !this.hasError && this.totalSpend === 0;
    }

    get shopUrl() {
        return '/';
    }

    get programUrl() {
        return '/bulk-procurement-program';
    }
}
