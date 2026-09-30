public class AccountUpdateBatch implements Database.Batchable<sObject> {
    // 1. Start: Collect the records to be processed
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Name FROM Account');
    }
 
    // 2. Execute: Process each batch of records 
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account acc : scope) {
            acc.Description = 'updated';
        }
        update scope;
    }
 
    // 3. Finish: Run post-processing logic (like sending an email)
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch processing completed.');
    }
} //Database.executeBatch(new AccountUpdateBatch());