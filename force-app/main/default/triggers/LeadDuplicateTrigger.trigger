trigger LeadDuplicateTrigger on Lead (before insert) {

    LeadDuplicateHandler.checkDuplicateEmails(Trigger.new);

}