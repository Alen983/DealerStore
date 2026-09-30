import { LightningElement } from 'lwc';
import createLead from '@salesforce/apex/LeadCaptureController.createLead';

export default class LeadCaptureForm extends LightningElement {

    firstName = '';
    lastName = '';
    company = '';
    email = '';
    employees = '';

    handleFirstName(event) {
        this.firstName = event.target.value;
    }

    handleLastName(event) {
        this.lastName = event.target.value;
    }

    handleCompany(event) {
        this.company = event.target.value;
    }

    handleEmail(event) {
        this.email = event.target.value;
    }

    handleEmployees(event) {
        this.employees = event.target.value;
    }

    submitLead() {

        createLead({
            firstName: this.firstName,
            lastName: this.lastName,
            company: this.company,
            email: this.email,
            employees: this.employees
        })
        .then(() => {
            alert('🎉 Lead Created Successfully!');
        })
        .catch(error => {
            console.error(error);
        });
    }
}