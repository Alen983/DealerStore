import { LightningElement, api } from 'lwc';

export default class LeadIntelligencePanel extends LightningElement {

    @api recordId;
    @api score = 35;
    @api category = 'HOT';

    get recommendation() {
        if (this.category === 'HOT') {
            return '🔥 Immediate follow-up recommended.';
        }

        if (this.category === 'Warm') {
            return '⚡ Follow up within 24 hours.';
        }

        return '❄️ Low priority lead.';
    }

    get badgeClass() {
        return this.category === 'HOT'
            ? 'hot'
            : this.category === 'Warm'
            ? 'warm'
            : 'cold';
    }
}