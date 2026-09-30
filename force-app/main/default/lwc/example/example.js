import { LightningElement } from 'lwc';
 
export default class SimpleForm extends LightningElement {
    name = '';
    email = '';
 
    handleNameChange(event) {
        this.name = event.target.value;
    }
 
    handleEmailChange(event) {
        this.email = event.target.value;
    }
 
    handleSubmit() {
        alert(`Name: ${this.name}, Email: ${this.email}`);
    }
}