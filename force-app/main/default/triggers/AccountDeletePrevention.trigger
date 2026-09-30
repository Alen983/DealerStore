trigger AccountDeletePrevention on Account (before delete) {
    for (Account acc : Trigger.old) {
        // Check if the Industry is 'Technology'
        if (acc.Industry == 'Technology') {
            // Prevent deletion and show a message
            acc.addError('Accounts in the Technology industry cannot be deleted.');
        }
    }
}