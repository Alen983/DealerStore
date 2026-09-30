public class LeadDuplicateHandler {

    public static void checkDuplicateEmails(List<Lead> newLeads) {

        Set<String> emailSet = new Set<String>();

        for (Lead ld : newLeads) {
            if (ld.Email != null) {
                emailSet.add(ld.Email);
            }
        }

        List<Lead> existingLeads = [
            SELECT Id, Email
            FROM Lead
            WHERE Email IN :emailSet
        ];

        Set<String> existingEmails = new Set<String>();

        for (Lead ld : existingLeads) {
            existingEmails.add(ld.Email);
        }

        for (Lead ld : newLeads) {
            if (existingEmails.contains(ld.Email)) {
                ld.addError('A Lead with this email already exists.');
            }
        }
    }
}