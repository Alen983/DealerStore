public class OpportunityScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        
        // Step 1: Query past due Opportunities
        List<Opportunity> oppList = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE CloseDate < TODAY
            AND StageName != 'Closed Lost'
        ];

        // Step 2: Update Stage
        for(Opportunity opp : oppList) {
            opp.StageName = 'Closed Lost';
        }

        // Step 3: Save changes
        if(!oppList.isEmpty()) {
            update oppList;
        }
    }
}