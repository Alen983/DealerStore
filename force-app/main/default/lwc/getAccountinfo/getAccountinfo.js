import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
 
export default class GetAccountInfo extends LightningElement {
 
    @api recordId;
 
    @wire(getRecord, {
        recordId: '$recordId',
        fields: ['Account.Name', 'Account.Phone']
    })
    account;
}