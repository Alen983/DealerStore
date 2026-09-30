import { LightningElement, api } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
 
export default class CreateContactForAccount extends LightningElement {
 
    @api recordId;
 
    handleCreate() {
 
        const fields = {
            LastName: 'Test Contact',
            AccountId: this.recordId
        };
 
        createRecord({
            apiName: 'Contact',
            fields
        });
    }
}