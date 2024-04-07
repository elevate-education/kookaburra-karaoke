public without sharing class OpportunityUtilities {

    /**
    * @description Syncronises the Primary_Contact__c field to the OpportunityContactRole object
    * @param {List<Opportunity>} newOpps the list of new opportunities
    * @return {void}
    */
    public static void syncPrimaryContact(List<Opportunity> newOpps) {
        
        List<OpportunityContactRole> newRoles = new List<OpportunityContactRole>();
        List<OpportunityContactRole> roles = [ 
            SELECT id, contactid, isprimary, opportunityid 
            FROM OpportunityContactRole 
            WHERE opportunityid IN :newOpps];

        Map<Id, List<OpportunityContactRole>> oppIdToRoles = new Map<Id, List<OpportunityContactRole>>();

        for(Opportunity opp :newOpps) {
            List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
            for(OpportunityContactRole ocr :roles) {
                if(ocr.opportunityid == opp.Id) {
                    ocrs.add(ocr);
                }
            }
            oppIdToRoles.put(opp.Id, ocrs);
        }

        for(Opportunity opp :newOpps) {
            if(!opp.PBL_Opp__c) { //exclude cura opps from this flow              
                if(oppIdToRoles.get(opp.Id).isEmpty() && opp.Primary_Contact__c != null) { //no roles and has a primary contact, add one
                    OpportunityContactRole role = new OpportunityContactRole(
                        ContactId = opp.Primary_Contact__c,
                        OpportunityId = opp.Id,
                        Role = 'Decision Maker',
                        isPrimary = true
                    );
                    newRoles.add(role);
                }
                else {
                    Boolean primaryExists = false;
                    for(OpportunityContactRole ocr: oppIdToRoles.get(opp.Id)) { //got some roles, check them
                        if(ocr.ContactId == opp.Primary_Contact__c) { //if we find one that matches our primary contact, make it primary
                            ocr.IsPrimary = true;
                            primaryExists = true;
                            newRoles.add(ocr);
                        }
                        else { //if it doesn't match, remove primary flag
                            ocr.IsPrimary = false;
                            newRoles.add(ocr);
                        }
                    }
                    if(!primaryExists && opp.Primary_Contact__c != null) { //if we never found a primary ct, make one
                        OpportunityContactRole role = new OpportunityContactRole(
                            ContactId = opp.Primary_Contact__c,
                            OpportunityId = opp.Id,
                            Role = 'Decision Maker',
                            isPrimary = true
                        );
                        newRoles.add(role);
                    }
                }
            }
            else {
                if(oppIdToRoles.get(opp.Id).isEmpty() && opp.Primary_Contact__c != null) { //if no role and we have a primary ct, create
                    OpportunityContactRole role = new OpportunityContactRole(
                            ContactId = opp.Primary_Contact__c,
                            OpportunityId = opp.Id,
                            Role = 'Teacher',
                            isPrimary = true
                        );
                        newRoles.add(role);
                }
                if(!oppIdToRoles.get(opp.Id).isEmpty() && opp.Primary_Contact__c != null) { //if a role, update
                    List<OpportunityContactRole> existingRoles = oppIdToRoles.get(opp.Id); //will only be one
                    existingRoles[0].ContactId = opp.Primary_Contact__c;
                    newRoles.add(existingRoles[0]);
                }                
            }
        }
        if(!newRoles.isEmpty()) {
            upsert newRoles;
        }

    }

    /**
    * @description Sets the opportunity pricebook based on the billing country and state of the related account
    * @param {List<Opportunity>} newOpportunityList the list of new opportunities
    * @param {Map<Id, Opportunity> oldOpportunityMap} oldOpportunityMap the previous state of the opportunity
    * @return {void}
    */
    /*public static void setOppPricebook(List<Opportunity> newOpportunityList) {
        for (Opportunity opp : newOpportunityList) {
            if(opp.Pricebook2Id == null) { //only change if null, PB gets set pre-insert on the resign batch
            	opp.Pricebook2Id = CustomSettingUtilities.getDefaultPricebookId(opp.Business_Unit_2__c);
            }
        }
    }*/

    /**
    * @description Creates booking and booking product records upon close/win of an opp
    * @param {Map<Id, Opportunity> newOpportunityList the map of new opportunities
    * @param {Map<Id, Opportunity> oldOpportunityMap} oldOpportunityMap the previous state of the opportunity
    * @return {void}
    */
    public static void createBookingFromOpp(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunityMap, Boolean closeWin) {

        List<Id> oppsToCreateBookingsFor = new List<Id>();

        List<Booking__c> relatedBookings;
        if(closeWin) {
            relatedBookings = [SELECT Opportunity__c FROM Booking__c WHERE Opportunity__c IN :newOpps];
        }

        for (Opportunity opp : newOpps) {
            if(closeWin) {
                if (opp.StageName == 'Closed Won' && oldOpportunityMap.get(opp.Id).StageName != 'Closed Won') {
                    system.debug('zZ' +opp.Business_Unit_2__c);
                    system.debug('zZ' + CustomSettingUtilities.shouldCreateBookingOnCloseWin(opp.Business_Unit_2__c));
                    if (CustomSettingUtilities.shouldCreateBookingOnCloseWin(opp.Business_Unit_2__c)) {
                        if (relatedBookings == null || relatedBookings.size() == 0) {
                            oppsToCreateBookingsFor.add(opp.Id);
                        } else {
                            for (Booking__c book : relatedBookings) {
                                if (book.Opportunity__c != opp.Id) {
                                    oppsToCreateBookingsFor.add(opp.Id);
                                }
                            }
                        }
                    }
                }
            }
            else {
                oppsToCreateBookingsFor.add(opp.Id);
            }
        }

        if (!oppsToCreateBookingsFor.isEmpty()) {
            
            String key = String.valueOf(Math.random() * 1000000000);

            List<OpportunityLineItem> relatedOpportunityLineItems = [
                SELECT Id, Quantity, Year_Level__c, UnitPrice, Project_Course_Start_Date__c, Project_Course_End_Date__c,Opportunity.Primary_Faculty__r.Name,
                OpportunityId, Opportunity.AccountId, Opportunity.Account.Name, Manuals__c, End_Date_Time__c, Deposit__c,
                Product2Id, Product2.Family, Product2.Name, Start_Date_Time__c, X_of_Presenters__c, X_of_Students__c,
                Opportunity.CloseDate, Date_Entered__c, Source_of_Sale__c, Start_Date_Time_Display__c, Location__c, Opportunity.Business_Unit_2__c,
                End_Date_Time_Display__c, Sales_Rep__c, Opportunity.Primary_Contact__c, Opportunity.CurrencyISOCode, Product2.Product_Type__c,
                Location__r.Name, Hours__c, Active__c, Opportunity.Target_Type__c, Opportunity.RecordTypeId, School_Region_Timezone__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN :oppsToCreateBookingsFor
                AND Active__c = true
                AND Product2.ProductCode != 'MANUAL' AND Product2.Product_Type__c != 'Fee'
                ORDER BY OpportunityId, Location__c, Start_Date_Time__c
            ];

            Map<Id, Set<Booking__c>> bookingsToOpp = new Map<Id, Set<Booking__c>>();

            for(OpportunityLineItem oli :relatedOpportunityLineItems) {
                if(bookingsToOpp.get(oli.OpportunityId) == null) {
                    bookingsToOpp.put(oli.OpportunityId, new Set<Booking__c>{oliToBooking(oli, key)});
                }
                else {
                    Set<Booking__c> tempBookings = bookingsToOpp.get(oli.OpportunityId);
//                    tempBookings.add(oliToBooking(oli, key));
                    Booking__c tempBooking = oliToBooking(oli, key);
                    
                    for(Booking__c b :tempBookings) {
                        if(b.External_Id__c != tempBooking.External_ID__c) {
                            tempBookings.add(tempBooking);
                        }
                    }
                    
                    //tempBookings.add(oliToBooking(oli, key));
                    bookingsToOpp.put(oli.OpportunityId, tempBookings);
                }
            }

            List<Booking__c> bookingsToInsert = new List<Booking__c>();
            for(Set<Booking__c> bookings :bookingsToOpp.values()) {
                for(Booking__c bk :bookings) {
                    bookingsToInsert.add(bk);
                }
            }

            insert bookingsToInsert;

            List<Seminar__c> bookingProductsToInsert = new List<Seminar__c>();
            for(OpportunityLineItem oli :relatedOpportunityLineItems) {

                
                String bookingExternalId;
                String startDate = oli.Start_Date_Time__c != null ? String.valueOf(oli.Start_Date_Time__c.date()) : key;
                
                List<String> bookingExternalIdValues = new List<String>{
                    oli.OpportunityId,
                        startDate,
                        oli.Product2.Family,
                        oli.Location__c,
                        oli.Id
                        };
                            
                
                if(oli.Product2.Product_Type__c == 'Presenter Led' && (oli.Product2.Family == 'Seminar' || oli.Product2.Family == 'Elevate Online' || oli.Product2.Family == 'Ecree')) {
                    //bookingExternalId = oli.OpportunityId + String.valueOf(oli.Start_Date_Time__c.date()) + oli.Product2.Family + oli.Location__c;
                    String bookingExternalTemplate = '{0}{1}{2}{3}';
                    bookingExternalId = String.format(bookingExternalTemplate, bookingExternalIdValues);
                }
                else {
                    //bookingExternalId = oli.OpportunityId + String.valueOf(oli.Start_Date_Time__c.date()) + oli.Product2.Family + oli.Location__c + oli.Id;
                    String bookingExternalTemplate = '{0}{1}{2}{3}{4}';
                    bookingExternalId = String.format(bookingExternalTemplate, bookingExternalIdValues);
                }

                Seminar__c sem = oliToBookingProduct(oli);
                sem.Booking__r = new Booking__c(External_Id__c = bookingExternalId);
                bookingProductsToInsert.add(sem);
            }

            insert bookingProductsToInsert;

            Map<Id, Id> semOLItoBooking = new  Map<Id, Id>();
            List<Seminar__c> semRequery = [SELECT Id, Booking__c, Opportunity_Line_Item_Id__c FROM Seminar__c WHERE ID IN :bookingProductsToInsert];
            for(Seminar__c sem :semRequery) {
                semOLItoBooking.put(sem.Opportunity_Line_Item_Id__c, sem.Booking__c);
            }

            List<OpportunityLineItem> miscItemsOnly = [
                SELECT Id, Quantity, Year_Level__c, UnitPrice,
                OpportunityId, Opportunity.AccountId, Opportunity.Account.Name, Manuals__c, End_Date_Time__c, Project_Course_Start_Date__c, Project_Course_End_Date__c,
                Product2Id, Product2.Family, Product2.Name, Start_Date_Time__c, X_of_Presenters__c, X_of_Students__c, Product2.Product_Type__c, Deposit__c,Opportunity.Primary_Faculty__r.Name,
                Opportunity.CloseDate, Date_Entered__c, Source_of_Sale__c, Start_Date_Time_Display__c, Location__c, Product2.ProductCode, Opportunity.Business_Unit_2__c,
                End_Date_Time_Display__c, Sales_Rep__c, Opportunity.Primary_Contact__c, Opportunity.CurrencyISOCode, Related_OLI__c,
                Location__r.Name, Hours__c, Active__c, Opportunity.Target_Type__c, Opportunity.RecordTypeId, School_Region_Timezone__c
                FROM OpportunityLineItem
                WHERE Related_OLI__c IN :semOLItoBooking.keySet()
                AND Active__c = true
                AND Product2.ProductCode = 'MANUAL'
                AND OpportunityId IN :oppsToCreateBookingsFor
                ORDER BY OpportunityId, Location__c, Start_Date_Time__c
            ];

            List<Seminar__c> manualsToInsert = new List<Seminar__c>();

            for(OpportunityLineItem oli :miscItemsOnly) {
                Seminar__c sem = oliToBookingProduct(oli);
                sem.Booking__c = semOLItoBooking.get(oli.Related_OLI__c);
                manualsToInsert.add(sem);
            }

            insert manualsToInsert;

            List<OpportunityLineItem> fees = [
                SELECT Id, Quantity, Year_Level__c, UnitPrice,
                OpportunityId, Opportunity.AccountId, Opportunity.Account.Name, Manuals__c, End_Date_Time__c, Project_Course_Start_Date__c, Project_Course_End_Date__c,
                Product2Id, Product2.Family, Product2.Name, Start_Date_Time__c, X_of_Presenters__c, X_of_Students__c, Product2.Product_Type__c, Deposit__c,
                Opportunity.CloseDate, Date_Entered__c, Source_of_Sale__c, Start_Date_Time_Display__c, Location__c, Product2.ProductCode,Opportunity.Primary_Faculty__r.Name,
                End_Date_Time_Display__c, Sales_Rep__c, Opportunity.Primary_Contact__c, Opportunity.CurrencyISOCode, Related_OLI__c, opportunity.business_unit__c,
                Location__r.Name, Hours__c, Active__c, Opportunity.Target_Type__c, Opportunity.RecordTypeId, School_Region_Timezone__c, opportunity.business_unit_2__c
                FROM OpportunityLineItem
                WHERE Active__c = true
                AND Product2.Product_Type__c = 'Fee'
                AND OpportunityId IN :oppsToCreateBookingsFor
                ORDER BY OpportunityId, Location__c, Start_Date_Time__c
            ];

            List<Seminar__c> feesToInsert = new List<Seminar__c>();

            Id onlineBookingRt = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Online').getRecordTypeId();
            
            Formula.recalculateFormulas(bookingsToInsert);
            
            for(OpportunityLineItem oli :fees) {
                
                //create sem
                Seminar__c sem = oliToBookingProduct(oli);

                //find the correct booking
                for(Booking__c bk: bookingsToInsert) {
                    if(bk.Delivery_Type__c == 'In Person' && bk.RecordTypeId != onlineBookingRt) {
                        if(bk.Date__c == convertDateString(oli.Start_Date_Time_Display__c, oli.Opportunity.Business_Unit_2__c) && 
                           bk.Booking_Location__c == oli.Location__c && 
                           bk.Opportunity__c == oli.OpportunityId &&
                           sem.Booking__c == null) {
                            sem.Booking__c = bk.Id;
                            break;
                       }
                    }
                }
                //if found, add to list to insert
                if(sem.Booking__c != null) {
                    feesToInsert.add(sem);
                }
            }
            insert feesToInsert;
        }
    }

    private static Booking__c oliToBooking(OpportunityLineItem oli, String key) {

        Booking__c tempBooking = new Booking__c();

        String bookingExternalId;
        String startDate = oli.Start_Date_Time__c != null ? String.valueOf(oli.Start_Date_Time__c.date()) : key;
        
        List<String> bookingExternalIdValues = new List<String>{
         		oli.OpportunityId,
                startDate,
                oli.Product2.Family,
                oli.Location__c,
                oli.Id
        };
        
        if(oli.Product2.Product_Type__c == 'Presenter Led' && (oli.Product2.Family == 'Seminar' || oli.Product2.Family == 'Elevate Online' || oli.Product2.Family == 'Ecree')) {
            //bookingExternalId = oli.OpportunityId + String.valueOf(oli.Start_Date_Time__c.date()) + oli.Product2.Family + oli.Location__c;
            String bookingExternalTemplate = '{0}{1}{2}{3}';
            bookingExternalId = String.format(bookingExternalTemplate, bookingExternalIdValues);
        }
        else {
            //bookingExternalId = oli.OpportunityId + String?.valueOf(oli.Start_Date_Time__c?.date()) + oli.Product2.Family + oli.Location__c + oli.Id;
            String bookingExternalTemplate = '{0}{1}{2}{3}{4}';
            bookingExternalId = String.format(bookingExternalTemplate, bookingExternalIdValues);
        }
    
        
        tempBooking.External_Id__c = bookingExternalId;
        tempBooking.Opportunity__c = oli.OpportunityId;
        tempBooking.School__c = oli.Opportunity.AccountId;
        tempBooking.Contact_Name__c = oli.Opportunity.Primary_Contact__c;
        tempBooking.Date__c = convertDateString(oli.Start_Date_Time_Display__c, oli.Opportunity.Business_Unit_2__c);
        tempBooking.Status__c = wdci_ElevateConstants.BOOKING_STATUS_BOOKING_CONFIRMED;
        tempBooking.CurrencyISOCode = oli.Opportunity.CurrencyISOCode;
        tempBooking.Booking_Location__c = oli.Location__c;
        tempBooking.Target_Type__c = oli.Opportunity.Target_Type__c;
        tempBooking.Business_Unit__c = oli.Opportunity.Business_Unit_2__c;

        tempBooking.Project_Course_Start_Date__c = oli.Project_Course_Start_Date__c;
        tempBooking.Project_Course_End_Date__c = oli.Project_Course_End_Date__c;

        String nameDate = oli.Start_Date_Time__c?.format('dd/MMMMM/YYYY');
        String nameProduct = '';
        
        //set values per product family type
        switch on oli.Product2.Family {
            when 'Connect' {
                tempBooking.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Connect').getRecordTypeId();
                tempBooking.Product_Family__c = 'Connect';
                nameProduct = oli.Product2.Name;
            }
            when 'PBL' {
            	tempBooking.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('PBL').getRecordTypeId();
                tempBooking.Product_Family__c = 'PBL';
            	nameProduct = oli.Product2.Name;
                nameDate = oli.Opportunity.Primary_Faculty__r.Name;// != null ? Opportunity.Primary_Faculty__r.Name : '';
            }
            when 'Ecree' {
                tempBooking.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Online').getRecordTypeId();
            	tempBooking.Product_Family__c = 'Ecree';
    			
                if(oli.Product2.Product_Type__c == 'Presenter Led') {
                	nameProduct = 'Essay Writing';
            	}
            	else {
            		nameProduct = oli.Product2.Name;
            	}
            }
            when 'Elevate Online' {
                tempBooking.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Online').getRecordTypeId();
            	tempBooking.Product_Family__c = 'Study Skills';
            	nameProduct = oli.Product2.Name;
            }
            when else {
            	tempBooking.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Seminar').getRecordTypeId();
            	tempBooking.Product_Family__c = 'Study Skills';
                nameProduct = 'Study Skills';
            }
        }

        if(oli.Opportunity.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Target').getRecordTypeId()) {
            tempBooking.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Target').getRecordTypeId();
        }
        
        
        //Set display name, 130k char max
        tempBooking.Display_Name__c = oli.Opportunity.Account.Name + ' - ' + nameProduct + ' - ' + nameDate;
        
        //77 char max, 80 (minus 3 for ' - ')
		Integer nameLength = nameProduct.length() + (nameDate == null ? 0 : nameDate?.length());
        if(nameLength < 77) {
            Integer maxLength = 77 - (nameDate == null ? 0 : nameDate?.length());
            nameProduct.abbreviate(maxLength);
        }
        
        tempBooking.Name = nameProduct + (nameDate == null ? '' :  ' - ' + nameDate);
        
        System.debug('bookingExtId ' + bookingExternalId);
        System.debug(tempBooking);
        
        return tempBooking;

    }

    private static Seminar__c oliToBookingProduct(OpportunityLineItem oli) {

        Seminar__c newBookingProduct = new Seminar__c();

        newBookingProduct.Name = oli.Product2.Name;
        newBookingProduct.Cost__c = oli.UnitPrice;
        newBookingProduct.Year_Level__c = oli.Year_Level__c;
        newBookingProduct.Manuals__c = oli.Manuals__c;
        newBookingProduct.Start_Date_Time__c = oli.Start_Date_Time__c;
        newBookingProduct.End_Date_Time__c = oli.End_Date_Time__c;
        newBookingProduct.X_of_Presenters__c = oli.X_of_Presenters__c;
        newBookingProduct.X_of_Students__c = oli.X_of_Students__c;
        newBookingProduct.Product__c = oli.Product2Id;
        newBookingProduct.CurrencyISOCode = oli.Opportunity.CurrencyISOCode;
        newBookingProduct.Opportunity_Line_Item_Id__c = oli.Id;
        newBookingProduct.Quantity_Presenter_Student_Number__c = oli.Quantity;
        newBookingProduct.Source_of_Sale__c = oli.Source_of_Sale__c;
        newBookingProduct.Sales_Rep__c = oli.Sales_Rep__c;
        newBookingProduct.Status__c = 'Open';
        newBookingProduct.Date_Entered__c = oli.Date_Entered__c != null ? oli.Date_Entered__c : Date.today();
        newBookingProduct.Location__c = oli.Location__c;
        newBookingProduct.Hours__c = oli.Hours__c;
        newBookingProduct.Product_Family_2__c = oli.Product2.Family;
        newBookingProduct.Product_Type_2__c = oli.Product2.Product_Type__c;
        newBookingProduct.Deposit__c = oli.Deposit__c;
        //newBookingProduct.Project_Course_Start_Date__c = oli.Project_Course_Start_Date__c;
        //newBookingProduct.Project_Course_End_Date__c = oli.Project_Course_End_Date__c;

        return newBookingProduct;
    }

    public static void setDateEnteredOnCloseWin(Map<Id, Opportunity> newOpportunityMap, Map<Id, Opportunity> oldOpportunityMap) {

        List<Id> closedWonOppIds = new List<Id>();

        for(Opportunity opp: newOpportunityMap.values()) {
            if (opp.StageName == 'Closed Won' && oldOpportunityMap.get(opp.Id).StageName != 'Closed Won') {
                closedWonOppIds.add(opp.Id);
            }
        }

        List<OpportunityLineItem> olis = [SELECT Id, Date_Entered__c, Opportunity.CloseDate, Opportunity.Business_Unit_2__c 
                                          FROM OpportunityLineItem 
                                          WHERE OpportunityId IN :closedWonOppIds 
                                          AND Opportunity.WDCi_Imported__c = false];

        for(OpportunityLineItem oli :olis) {
            oli.Date_Entered__c = date.today();
        }

        update olis;
     }

    public static void assignCSMAndBDM(List<Opportunity> newOpportunityList){
        List<Id> accountIds = new List<Id>();
        for(Opportunity opp : newOpportunityList){
            if(opp.State_Relevant_CSM__c == null) {
                accountIds.add(opp.AccountId);
            }
        }

        Map<Id, Account> relatedAccounts = new Map<Id, Account>();
        if(!accountIds.isEmpty()) {
            relatedAccounts = new Map<Id, Account>([SELECT Id, Job_Assignment_Region__c FROM Account WHERE ID IN :accountIds]);
        }

        for(Opportunity opp :newOpportunityList) {
            Account relatedAccount = relatedAccounts.get(opp.AccountId);
            if(relatedAccount != null) {
                if(!Test.isRunningTest()) {
                    if(relatedAccount.Job_Assignment_Region__c != null) {
                        Regional_Owner_Mapping__mdt regionalOwnerMapping = CustomSettingUtilities.getRegionalSettings(relatedAccount.Job_Assignment_Region__c, opp.Business_Unit_2__c);
                        opp.State_Relevant_CSM__c = regionalOwnerMapping?.CSM_User_Id__c;
                        if(opp.Opportunity_Source__c == 'Resign' && regionalOwnerMapping?.CSM_User_Id__c != null) {
                            opp.OwnerId = regionalOwnerMapping?.CSM_User_Id__c;
                        }
                    }  
                }
                else { //populate with current running user in tests
                    opp.State_Relevant_CSM__c = UserInfo.getUserId();
                }
            }
        }
    }
    
    private static date convertDateString(String dateString, String busUnit) {
        //display will be in aus format e.g. "DD/MM/YYYY HH:MM" we have to do this as some users locale is US.
        String displayBookingDate = dateString?.split(' ')[0];
        List<String> bookingDateParts = displayBookingDate?.split('/');
        Date bookingDate;
        //usa uses mm/dd/yy
        if(busUnit == 'Elevate USA' || busUnit == 'Elevate NorCal') {
            bookingDate = bookingDateParts?.size() == 3 ? 
                Date.newInstance(
                    Integer.valueOf(bookingDateParts[2]), 
                    Integer.valueOf(bookingDateParts[0]), 
                    Integer.valueOf(bookingDateParts[1])
                ) : null;
        }
        else {
            bookingDate = bookingDateParts?.size() == 3 ? 
                Date.newInstance(
                    Integer.valueOf(bookingDateParts[2]), 
                    Integer.valueOf(bookingDateParts[1]), 
                    Integer.valueOf(bookingDateParts[0])
                ) : null;
        }
        return bookingDate;
    }
    
    public static Id cloneOpportunityWithLineItems(Id oppId, Boolean reSign) {

        SavePoint sp = Database.setSavepoint();
        
        try {
            //exclude manuals as they are created automatically
            List<OpportunityLineItem> olisForResign = [
            //OLI Fields
            SELECT Id, Quantity, Year_Level__c, UnitPrice, Project_Course_Start_Date__c, Project_Course_End_Date__c,
            Product2Id, Start_Date_Time__c, End_Date_Time__c, X_of_Presenters__c, X_of_Students__c, Manuals__c,
            Date_Entered__c, Source_of_Sale__c, Sales_Rep__c, Active__c, Location__c, Hours__c, School_Region_Timezone__c, 
            OpportunityId, Product2.ProductCode,
            //Opp Fields
            Opportunity.AccountId, Opportunity.Primary_Contact__c, Opportunity.CurrencyISOCode, Opportunity.OwnerId,
            Opportunity.Target_Type__c, Opportunity.RecordTypeId, Opportunity.Name, Opportunity.State_Relevant_CSM__c,
            Opportunity.Account.Travel_Pay__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :oppId
            AND Product2.ProductCode != 'MANUAL'];
            
            if(olisForResign == null || olisForResign.isEmpty()) {
            	throw new ResignException('There are no products on this Opportunity');
            }
			
            //get first record for opp
            Opportunity newOpp = olisForResign[0].Opportunity.clone(false, true, false, false);
            newOpp.StageName = 'New';
            newOpp.CloseDate = Date.today().addDays(30);
            if(reSign) {
                newOpp.Name = newOpp.Name + ' - RE-SIGN COPY';
                newOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Seminar_Re_Sign').getRecordTypeId();
            }
            
            insert newOpp;
            
            List<OpportunityLineItem> newOlis = new List<OpportunityLineItem>();
            List<Id> oldOLIIds = new List<Id>();

            for(OpportunityLineItem oli :olisForResign) {
                oldOLIIds.add(oli.Id);
                OpportunityLineItem newOli = oli.clone(false, true, false, false);
                newOli.OpportunityId = newOpp.Id;
                newOli.Start_Date_Time__c = wdci_DateTimeUtil.getNextYearDate(oli.Start_Date_Time__c, true);
                newOli.End_Date_Time__c = wdci_DateTimeUtil.getNextYearDate(oli.End_Date_Time__c, true);
                newOLI.Active__c = true;
                if(oli.Product2.ProductCode == 'TRAVEL') {
                    newOLI.UnitPrice = oli.Opportunity.Account.Travel_Pay__c;
                }
                newOlis.add(newOli);
            }
            
            insert newOlis;
            
            //Get any Booking Products for the clone opp, so we can mark them as resign created
            List<Seminar__c> sems = [SELECT ID FROM Seminar__c WHERE Opportunity_Line_Item_Id__c IN :oldOLIIds];
            
            for(Seminar__c sem :sems) {
                sem.Resign_Created__c = true;
            }
            
            update sems;
            
            return newOpp.Id;
            
        }
        catch (exception e) {
            database.rollback(sp);
            System.debug(e.getStackTraceString());
            throw new ResignException('An error has occured cloning this opportunity: ' + e.getMessage());
        }
        
    }
    
    
    public class ResignException extends Exception {}
    
}