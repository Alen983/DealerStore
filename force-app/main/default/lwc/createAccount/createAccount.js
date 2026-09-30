import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createAccount from '@salesforce/apex/AccountController.createAccount';
 
export default class CreateAccount extends LightningElement {
    accountName = '';
    phone = '';
    website = '';
 
    handleNameChange(event) {
        this.accountName = event.target.value;
    }
 
    handlePhoneChange(event) {
        this.phone = event.target.value;
    }
 
    handleWebsiteChange(event) {
        this.website = event.target.value;
    }
 
    handleCreate() {
        createAccount({
            name: this.accountName,
            phone: this.phone,
            website: this.website
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Account created successfully',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }
}