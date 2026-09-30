public class AccountUpdateQueueable implements System.Queueable {
    public Id accId;
    public AccountUpdateQueueable(Id recordId)
    {
        this.accId = recordId;
    }
 
    public void execute(System.QueueableContext context) {
        //  Perform your primary logic
        Account acc = [SELECT Id, Name FROM Account WHERE Id = :accId LIMIT 1];
        acc.Description = 'Updated via Queueable1';
        update acc;
        //  CHAIN THE NEXT JOB
         System.enqueueJob(new AccountUpdateQueueable2());
 
    }
}