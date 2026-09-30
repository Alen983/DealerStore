public with sharing class LeadCaptureController {

    @AuraEnabled
    public static void createLead(
        String firstName,
        String lastName,
        String company,
        String email,
        Integer employees
    ) {

        Lead ld = new Lead();

        ld.FirstName = firstName;
        ld.LastName = lastName;
        ld.Company = company;
        ld.Email = email;
        ld.NumberOfEmployees = employees;

        insert ld;
    }
}