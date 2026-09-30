public class CreateCaseController {
 
    public Case newCase { get; set; }
 
    public CreateCaseController() {
        newCase = new Case();
    }
 
    public PageReference saveCase() {
        insert newCase;
        ApexPages.addMessage(
            new ApexPages.Message(ApexPages.Severity.CONFIRM,'Case Created Successfully!')
        );
        newCase = new Case(); // reset form
        return null;
    }
}