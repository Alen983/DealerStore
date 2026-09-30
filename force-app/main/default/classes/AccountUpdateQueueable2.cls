public class AccountUpdateQueueable2 implements System.Queueable {
    public void execute(System.QueueableContext context) {
        System.debug('Second job is running now!');
 
    }
}