trigger AccountTrigger on Account (before insert, before update) {
    List<String> keywords = new List<String>{'Technology', 'Tech', 'Technologies'};
    for (Account acc : Trigger.new) {
        // Check if it's a new record OR if the Name has actually changed
        Boolean isNameChanged = Trigger.isInsert || (acc.Name != Trigger.oldMap.get(acc.Id).Name);
 
        if (isNameChanged && acc.Name != null) {
       for (String key : keywords) {
                if (acc.Name.contains(key)) {
                    acc.Industry = 'Technology'; 
                 }
            }
        }
    }
}