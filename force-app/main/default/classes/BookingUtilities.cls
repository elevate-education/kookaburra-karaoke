public class BookingUtilities {
    
    //NO QUERIES
    //
    public static void setProductFamily(List<Booking__c> bookings) {
        
        Id semRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Seminar').getRecordTypeId();
        
        for(booking__c bk :bookings) {
            if(bk.Delivery_Type__c == 'Online Platform' && bk.RecordTypeId == semRTId) {
                bk.Product_Family__c = 'Elevate Online';
            }
            if(bk.Delivery_Type__c == 'In Person' && bk.RecordTypeId == semRTId) {
                bk.Product_Family__c = 'Study Skills';
            }
        }
    }
    
    public static void setCancellationDate(List<Booking__c> bookings, Map<Id, Booking__c> oldBookings) {
        for(Booking__c bk :bookings) {
            if(bk.Status__c == 'Cancelled' && oldBookings.get(bk.Id).Status__c != 'Cancelled') {
                bk.Cancellation_Date__c = Date.today();
            }
        }
    }
    
    /**
* @description Updates the Earliest_Start_Date_Region_Time__c field to display the correct region time based on the Earlier_Start_Date__c rollup and the school's timezone
* @param {List<Booking__c>} newBookingList The list of new Booking__c records
* @return {void}
*/
    public static void convertBookingDateTime(List<Booking__c> newBookingList){
        for(Booking__c booking : newBookingList){
            if(booking.Earlier_Start_Date__c != null){
                booking.Earliest_Start_Date_Region_Time__c = wdci_DateTimeUtil.convertToTimezone(booking.Earlier_Start_Date__c, 'dd/MM/yyyy h:mm a', booking.School_Region_Timezone__c);
            }
        }
    }
    
    /**
* @description Enqueues the job to remove any bookings that do not have related seminars
* @param {List<Booking__c>} newBookingList The list of new Booking__c records
* @return {void}
*/
    public static void cancelBookingsWithNoSeminars(List<Booking__c> newBookings, Map<Id, Booking__c> oldBookingValues) { //no queries
        for(Booking__c bk :newBookings) {
            if(bk.Number_Of_Products__c == 0 && oldBookingValues.get(bk.Id).Number_Of_Products__c != 0 && bk.Status__c != 'Cancelled') {
                bk.Booking_Location__c = null;
                bk.Status__c = 'Cancelled';
                bk.Cancellation_Comments__c = 'Booking cancelled automatically as all booking products have been moved to other bookings';
                bk.Cancellation_Reason__c = 'Rescheduled';
            }
        }
    }
    
    /**
* @description Encrypts the booking ID using WDCI utility
* @param {List<Booking__c>} newBookingList The list of new Booking__c records
* @param {Map<Id, Booking__c>} newBookingList The map of new Booking__c records
* @return {void}
*/
    //TODO:Refactor This
    public static void encryptedBookingId(List<Booking__c> newBookingList, Map<Id, Booking__c> newBookingMap){ //no queries
        List<Booking__c> updateBooking = new List<Booking__c>();
        for(Booking__c b: newBookingList){
            Booking__c tempB = new Booking__c();
            tempB.Id = b.Id;
            tempB.Encrypted_Id__c = EncodingUtil.urlEncode(wdcilib.EncryptionUtil.encryptString(String.valueOf(b.Id)), 'UTF-8');
            
            updateBooking.add(tempB);
            
        }
        
        Database.SaveResult [] srList = Database.update(updateBooking, false);
        integer counter = 0;
        for (Database.SaveResult sr : srList) {
            if(!sr.isSuccess()) {
                Booking__c errorBooking = newBookingMap.get(updateBooking.get(counter).Id);
                errorBooking.addError(sr.getErrors()[0].getMessage());
            }
            
            counter++;
        }
        
    }
    
    /**
* @description Sets the CSM and BDM using the Region custom metadata
* @param {List<Booking__c>} newBookingList The list of new Booking__c records
* @return {void}
*/
    public static void assignCSMAndBDM(List<Booking__c> newBookingList) {
        if(!Test.isRunningTest()) { //Sigh, custom metadata in test issues.
            List<Id> accountIds = new List<Id>();
            for(Booking__c booking : newBookingList){
                if(booking.Opportunity_BDM__c == null || booking.State_Relevant_CSM__c == null) {
                    accountIds.add(booking.School__c);
                }
            }
            
            Map<Id, Account> relatedAccounts = new Map<Id, Account>();
            if(!accountIds.isEmpty()) {
                relatedAccounts = new Map<Id, Account>([SELECT Id, Job_Assignment_Region__c, Territory__c FROM Account WHERE ID IN :accountIds]);
                
                for(Booking__c b :newBookingList) {
                        Account relatedAccount = relatedAccounts.get(b.School__c);
                        Regional_Owner_Mapping__mdt regionalOwnerMapping = CustomSettingUtilities.getRegionalSettings(relatedAccount?.Job_Assignment_Region__c, relatedAccount?.Territory__c);
                        if(regionalOwnerMapping != null) {
                            b.Opportunity_BDM__c = b.Opportunity_Owner_Id__c;
                            b.State_Relevant_CSM__c = regionalOwnerMapping.CSM_User_Id__c;
                            b.OwnerId = regionalOwnerMapping.CSM_User_Id__c;
                        }
                    
                }
            }
        }
    }
    
    
    /**
* @description Marks all related booking products as cancelled and copies the cancellation reason and comments to them
* @param {List<Booking__c>} newBookingList The list of new Booking__c records
* @return {void}
*/
    
    public static void cancelRelatedRecords(List<Booking__c> bookings, Map<Id, Booking__c> oldBookings) { //query 1 seminar
        
        Set<Id> bookingIdsToCancel = new Set<Id>();
        Set<Id> bookingIdsToPending = new Set<Id>();
        List<Seminar__c> bpToUpdate = new List<Seminar__c>();
        
        for(Booking__c bk :bookings) {
            if(bk.Status__c == 'Cancelled' && oldBookings.get(bk.Id).Status__c != 'Cancelled') {
                bookingIdsToCancel.add(bk.Id);
            }
            if(bk.Status__c == 'Pending' && oldBookings.get(bk.Id).Status__c != 'Pending') {
                bookingIdsToPending.add(bk.Id);
            }
        }
        
        if(!bookingIdsToPending.isEmpty()) {
            List<Seminar__c> relatedBookingProducts = [
                SELECT ID, Status__c, Booking__r.Cancellation_Reason__c, Booking__r.Cancellation_Comments__c 
                FROM Seminar__c 
                WHERE Booking__c IN :bookingIdsToPending];
            for(Seminar__c bp :relatedBookingProducts) {
                bp.Status__c = 'Pending';
                bpToUpdate.add(bp);
            }
        }
        
        if(!bookingIdsToCancel.isEmpty()) {
            List<Seminar__c> relatedBookingProducts = [
                SELECT ID, Status__c, Booking__r.Cancellation_Reason__c, Booking__r.Cancellation_Comments__c 
                FROM Seminar__c 
                WHERE Booking__c IN :bookingIdsToCancel];
            
            for(Seminar__c bp :relatedBookingProducts) {
                bp.Status__c = 'Cancelled';
                bp.Cancellation_Date__c = Date.today();
                if(bp.Booking__r.Cancellation_Reason__c != null) {
                    bp.Cancellation_Reason__c = bp.Booking__r.Cancellation_Reason__c;
                }
                if(bp.Booking__r.Cancellation_Comments__c != null) {
                    bp.Cancellation_Comments__c = bp.Booking__r.Cancellation_Comments__c;
                }
                bpToUpdate.add(bp);
            }
        }
        
        update bpToUpdate;
    }
    
    public static void handleLocationChange(List<Booking__c> bookings, Map<Id, Booking__c> oldBookings) { //query 1 booking, query 2 seminar
        
        Id connectRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Connect').getRecordTypeId();
        Id pblRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('PBL').getRecordTypeId();
        Id trainingRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Internal_Training').getRecordTypeId();

        List<Id> oppIds = new List<Id>();
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>();
        
        for(Booking__c bk :bookings) {
            if(bk.RecordTypeId != connectRTId && bk.RecordTypeId != pblRTId) {
                if (bk.Booking_Location__c != oldBookings.get(bk.Id).Booking_Location__c) {
                    oppIds.add(bk.Opportunity__c);
                    bookingMap.put(bk.Id, bk);
                }
            }
        }
        
        if(!oppIds.isEmpty()) {
            
            List<sked__Job__c> relatedJobs = [SELECT Id, Booking__c, sked__Location__c, sked__Job_Status__c FROM sked__Job__c WHERE Booking__c IN :bookingMap.keySet()];
            
            for(sked__Job__c job :relatedJobs) {
                if(job.sked__Job_Status__c == 'Ready') {
                    bookings[0].AddError('You cannot change the Location when related Job(s) are \'Ready\'. Roll the Job Status(es) back to \'Pending Dispatch\'.');
                    break;
                }
                else {
                    if(bookingMap.get(job.Booking__c) != null) {
                        job.sked__Location__c = bookingMap.get(job.Booking__c).Booking_Location__c;
                    }
                }
            }
            
            update relatedJobs;
            
            try {
                Map<Id, List<Booking__c>> bookingsByOpp = new Map<Id, List<Booking__c>>();
                List<Booking__c> allBookingsForOpps = [SELECT Id, Date__c, Opportunity__c,
                                                       Booking_Location__r.Name, Booking_Location__c
                                                       FROM Booking__c
                                                       WHERE Opportunity__c IN :oppIds AND Status__c != 'Cancelled'
                                                       AND RecordTypeId != :connectRTId
                                                       AND RecordTypeId != :pblRTId
                                                       AND RecordTypeId != :trainingRTId];
                
                //group by opp
                for(Booking__c bk :allBookingsForOpps) {
                    
                    if (bookingsByOpp.get(bk.Opportunity__c) == null) {
                        bookingsByOpp.put(bk.Opportunity__c, new List<Booking__c>{bk});
                    }
                    else {
                        List<Booking__c> tempList = bookingsByOpp.get(bk.Opportunity__c);
                        tempList.add(bk);
                        bookingsByOpp.put(bk.Opportunity__c, tempList);
                    }
                }
                
                Map<Id, Id> mapOrigToNewBooking = new Map<Id, Id>();
                
                for(Booking__c bk :bookings) {
                    if(bk.Booking_Location__c != oldBookings.get(bk.Id).Booking_Location__c) {                        
                        if(bookingsByOpp != null && !bookingsByOpp.isEmpty()) {
                            for(Booking__c existingBooking : bookingsByOpp?.get(bk?.Opportunity__c)) {
                                if(existingBooking.Booking_Location__c == bk.Booking_Location__c &&
                                   existingBooking.Date__c == bk.Date__c &&
                                   existingBooking.Id != bk.Id ) {
                                       mapOrigToNewBooking.put(bk.Id, existingBooking.Id);
                                   }
                            }
                        }
                    }
                }
                
                List<Seminar__c> semsToMove = [SELECT Id, Booking__c FROM Seminar__c WHERE Booking__c IN :mapOrigToNewBooking.keySet()];
                
                for(Seminar__c sem: semsToMove) {
                    Id newBookingId = mapOrigToNewBooking.get(sem.Booking__c);
                    sem.Booking__c = newBookingId;
                    sem.Location__c = bookingMap.get(sem.Booking__c)?.Booking_Location__c;
                }
                
                update semsToMove;
                
            }
            catch (DmlException e) {
                System.debug(e);
                System.debug(e.getStackTraceString());
                bookings[0].addError(e.getDmlMessage(0));
            }
            catch (Exception e) {
                System.debug(e);
                System.debug(e.getStackTraceString());
                bookings[0].addError(e.getMessage());
                
            }
        }
    }
    
    public static void cancelSkedJobsForOnline(List<Booking__c> bookings, Map<Id, Booking__c> oldBookings) {
        List<Id> onlineBookings = new List<Id>();
        for(Booking__c bk : bookings) {
            if(bk.Delivery_Type__c == 'Online Platform' && oldBookings.get(bk.Id).Delivery_Type__c != 'Online Platform' ) {
                onlineBookings.add(bk.Id);
            }
        }
        List<sked__Job__c> jobsToCancel = [SELECT Id, Booking__c FROM sked__job__c WHERE Booking__c IN :onlineBookings];
        for(sked__Job__c job: jobsToCancel) {
            job.sked__Job_Status__c = 'Cancelled';
        }
        
        update jobsToCancel;
    }
    
    public static void setRecordType(List<Booking__c> bookings, Map<Id, Booking__c> oldBookings) {
         
        List<Id> locationIds = new List<Id>();
        //List<Id> actIds = new List<Id>();

        Id semRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Seminar').getRecordTypeId();
        Id onlineRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Online').getRecordTypeId();
        Id connectRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Connect').getRecordTypeId();
        Id pblRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('PBL').getRecordTypeId();
        Id targetRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Target').getRecordTypeId();
        Id trainingRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Internal_Training').getRecordTypeId();

        for(Booking__c bk :bookings) {
            if(bk.RecordTypeId != connectRTId && bk.RecordTypeId != pblRTId && bk.RecordTypeId != targetRTId && bk.RecordTypeId != trainingRTId) { //don't change if connect/pbl, this is set on insert
                if(oldBookings == null) { //doing an insert
                    if(bk.Booking_Location__c != null) {
                        locationIds.add(bk.Booking_Location__c);
                    }                
                }
                else {
                    if (bk.Booking_Location__c != oldBookings.get(bk.Id).Booking_Location__c) {
                        if(bk.Booking_Location__c != null) {
                            locationIds.add(bk.Booking_Location__c);
                        }
                        else {
                            bk.RecordTypeId = semRTId;
                        }
                        
                    }
                }
            }
            if(bk.RecordTypeId  == trainingRTId) {
                //actIds.add(bk.School__c);
                bk.Product_Family__c = 'Internal Training';
            }
        }
        
        if(!locationIds.isEmpty()) {
            
            Map<Id, sked__Location__c> relatedLocations = new Map<Id, sked__Location__c>([SELECT Id, Name FROM sked__Location__c WHERE ID IN :locationIds]);
            
            for(Booking__c bk :bookings) {
                if(bk.Booking_Location__c == null || relatedLocations.get(bk.Booking_Location__c).Name != 'ONLINE') {
                    bk.RecordTypeId = semRTId;
                }
                else {
                    bk.RecordTypeId = onlineRTId;
                }
            }
        }
        
        /*if(!actIds.isEmpty()) { 
        	Map<Id, Account> relatedActs = new Map<Id, Account>([SELECT Id, Territory__c FROM Account WHERE Id IN :actIds]);
            
            for(Booking__c bk :bookings) { 
                if(bk.RecordTypeId  == trainingRTId) { 
                    Account a = relatedActs.get(bk.School__c);
                    bk.Business_Unit__c = a?.Territory__c;
                }
            }
        }*/

    }
    
    public static void checkIfBookingMovedFromOnline(List<Booking__c> newBookingList, Map<Id, Booking__c> oldBookingMap) {
        
        Id connectRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Connect').getRecordTypeId();
        Id pblRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('PBL').getRecordTypeId();
        
        List<Id> bookingsNeedingJobs = new List<Id>();
        for(Booking__c bk :newBookingList) {
            if(bk.RecordTypeId != connectRTId && bk.RecordTypeId != pblRTId) {
                if(bk.Delivery_Type__c != 'Online Platform' && bk.Delivery_Type__c != oldBookingMap.get(bk.Id).Delivery_Type__c) {
                    bookingsNeedingJobs.add(bk.Id);
                }
            }
        }
        
        if(!bookingsNeedingJobs.isEmpty()) {
            List<sked__Job__c> jobsToUpsert = new List<sked__Job__c>();
            
            List<sked__Job__c> jobsToUpdate = [SELECT Id, sked__Job_Status__c, Booking__c, Seminar__c from sked__Job__c WHERE Booking__c IN :bookingsNeedingJobs];
            
            Map<Id, sked__Job__c> semToJobsMap = new Map<Id, sked__Job__c>();
            for(sked__Job__c job :jobsToUpdate) {
                semToJobsMap.put(job.Seminar__c, job);
            }
            
            List<Seminar__c> relatedSems = [ SELECT ID,
                                            Start_Date_Time__c,
                                            End_Date_Time__c,
                                            Product_Family__c,
                                            School_Address__c,
                                            X_of_Presenters__c,
                                            X_of_Students__c,
                                            Year_Level__c,
                                            Name,
                                            Start_Date_Time_Display__c,
                                            Booking__c,
                                            Booking__r.School__c,
                                            Booking__r.School__r.Name,
                                            Location__c,
                                            Booking__r.Contact_Name__c,
                                            Booking__r.Opportunity__c,
                                            Booking__r.Opportunity__r.CurrencyISOCode,
                                            Booking__r.Opportunity__r.Location__r.sked__Region__c,
                                            Booking__r.Opportunity__r.Location__c,
                                            Booking__r.School__r.Job_Assignment_Region__c,
                                            Booking__r.Delivery_Type__c,
                                            Product__r.Job_Required__c
                                            FROM Seminar__c WHERE Booking__c IN :bookingsNeedingJobs];
            
            for(Seminar__c sem :relatedSems) {
                if(semToJobsMap.get(sem.Id) != null && sem.Booking__r.Delivery_Type__c != 'Online') {
                    sked__Job__c job = semToJobsMap.get(sem.Id);
                    job.sked__Job_Status__c = 'Pending Allocation';
                    jobsToUpsert.add(job);
                }
                else {
                    if (sem.Product__r.Job_Required__c) {
                        sked__Job__c tempJob = BookingProductUtilities.seminarToJob(sem);
                        jobsToUpsert.add(tempJob);
                    }
                }
            }
            
            upsert jobsToUpsert;
        }
    }
    
    public static void syncLocationToBookingProduct(List<Booking__c> newList, Map<Id, Booking__c> oldMap) {
        
        Map<Id, Booking__c> bookingsWithLocChange = new Map<Id, Booking__c>();
        
        for(Booking__c bk : newList) {
            if(oldMap == null || (bk.Booking_Location__c != oldMap.get(bk.Id).Booking_Location__c)) {
                bookingsWithLocChange.put(bk.Id, bk);
            }
        }
        
        if(!bookingsWithLocChange.isEmpty()) {
            List<Seminar__c> relatedSems = [SELECT Id, Booking__c, Location__c FROM Seminar__c WHERE Booking__c IN :bookingsWithLocChange.keySet() ];
            
            for(Seminar__c sem :relatedSems) {
                sem.Location__c = bookingsWithLocChange.get(sem.Booking__c).Booking_Location__c;
            }
            
            update relatedSems;
        }
        
        
    }
    
    public static void setProgram(List<Booking__c> newList, Map<Id, Booking__c> oldMap) {
        
        List<Id> toAddProgram = new List<Id>();
		Set<Id> programIds = new Set<Id>();
        Id trainingRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Internal_Training').getRecordTypeId();
        Id curaRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Cura').getRecordTypeId();

        if(oldMap != null) {
            for(Booking__c b :newList) {
                //if date has changed, may need new program
                if(oldMap.get(b.Id).Date__c != b.Date__c && (b.RecordTypeId != trainingRTId || b.RecordTypeId != curaRTId) ) {
                    //toAddProgram.add(b.Id);
                    programIds.add(b.Program__c);
                }     
                
            }
        }

        for(Booking__c b :newList) { 
            if(b.Program__c == null && b.RecordTypeId != trainingRTId && b.RecordTypeId != curaRTId)  {
                toAddProgram.add(b.Id);
            }
        }
        
        if(!programIds.isEmpty()) {
            List<Booking__c> bookings = [SELECT Id, School__c, Contact_Name__c, Product_Family__c, Date__c,
                                         School_Year__c, Product_Line__c, Primary_Contact_Full_Name__c, Program__c
                                         FROM Booking__c 
                                         WHERE Program__c IN :programIds];
            
            Map<Id, Date> earliestDate = new Map<Id, Date>();
            Map<Id, Date> latestDate = new Map<Id, Date>();

            for(Booking__c b :bookings) {
                Date earliest = earliestDate.get(b.Program__c);
                Date latest = latestDate.get(b.Program__c);
                
                if(earliest == null || b.Date__c <  earliest) {
                    earliestDate.put(b.Program__c, b.Date__c);
                }
                 if(latest == null || b.Date__c >  latest) {
                    latestDate.put(b.Program__c, b.Date__c);
                }
            }
            List<Program__c> prgs = new List<Program__c>();

            for(Id p :programIds) {
                Program__c prg = new Program__c(
                	Id = p
                );
                if(earliestDate.get(p) != null) {
                    prg.Program_Start_Date__c = earliestDate.get(p);
                }
                 if(latestDate.get(p) != null) {
                    prg.Program_End_Date__c = latestDate.get(p);
                }
                prgs.add(prg);
            }
            
            update prgs;
        }
        
        
        if(!toAddProgram.isEmpty()) {
            	Set<String> cancelledStatus = new Set<String>{'Cancelled','Pending'};

             List<Booking__c> bookings = [SELECT Id, School__c, Contact_Name__c, Product_Family__c, Date__c,
                                         School_Year__c, Product_Line__c, Primary_Contact_Full_Name__c, Business_Unit__c
                                         FROM Booking__c 
                                         WHERE ID IN :toAddProgram AND Status__c NOT IN :cancelledStatus];
            
            Map<Id, Program__c> programs = ProgramUtilities.getOrCreateProgram(bookings);
            
            Map<Id, Program__c> programToUpdate = new Map<Id, Program__c>(); //to dedupe on ID
            for(Booking__c b :bookings) {
                Program__c relatedPrg = programs.get(b.Id);
                b.Program__c = relatedPrg.Id;
                if (relatedPrg.Program_Start_Date__c == null || relatedPrg.Program_Start_Date__c > b.Date__c) {
                    relatedPrg.Program_Start_Date__c = b.Date__c;
                }
                if (relatedPrg.Program_End_Date__c == null || relatedPrg.Program_End_Date__c < b.Date__c) {
                    relatedPrg.Program_End_Date__c = b.Date__c;
                }
                programToUpdate.put(relatedPrg.Id, relatedPrg);
            }
            update programToUpdate.values();
            update bookings;
        }
    }
    
    public static String genBookingName(String bookingType, String prodName, String acctName, DateTime bookingDate) {
                
        switch on bookingType {
            when 'Connect' {
           		return (prodName + ' - ' + bookingDate?.format('dd/MMMMM/YYYY')).abbreviate(255);
            }
            when 'Study Skills' {
           		return (acctName + ' - Study Skills - ' + bookingDate?.format('dd/MMMMM/YYYY')).abbreviate(255);
            }
            when else {
           		return (acctName + ' - Not Found - ' + bookingDate?.format('dd/MMMMM/YYYY')).abbreviate(255);
            }
    	}
    }
}