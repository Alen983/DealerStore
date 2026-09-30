import { LightningElement } from 'lwc';
import hello from '@salesforce/apex/TestController.hello';

export default class TestApex extends LightningElement {

    message = 'Loading...';

    connectedCallback() {

        hello()
            .then(result => {
                console.log('SUCCESS', result);
                this.message = result;
            })
            .catch(error => {
                console.error('ERROR', JSON.stringify(error));
                this.message = 'ERROR';
            });

    }
}