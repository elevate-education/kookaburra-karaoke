@IsTest
private class CuraSyncTest {
    @isTest static void itShouldDoPost() {
        
        Account a = new Account(Name = 'test', Territory__c = 'Elevate Australia');
        insert a;
        
        String body = '[{"event_name": "PREVIEW_TEACHER_CREATED",'+
            '"first_name": "Sophie",'+
            '"last_name": "Wheeler2",'+
            '"cura_user_id": "69420",'+
            '"email": "me@sophi.ee",'+
            '"salesforce_school_id": "'+a.Id+ '",'+
            '"cura_school_id": "abcd",'+
            '"start_time": "2011-10-05T14:48:00.000Z",'+
            '"end_time": "2011-10-05T14:48:00.000Z",'+
            '"created_at": "2011-10-05T14:48:00.000Z"}]';
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/v1/CuraSync';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = response;
        
        CuraSync.CuraSyncReturn result = CuraSync.doPost();
        
    }
    
    @isTest static void itShouldDoPostOppNoLead() {
        
        Insert new Opportunity(cura_UserID__c = '69420', StageName = 'New', Name = 'Test', CloseDate = Date.today());
        
        String body = '[{"event_name": "TRIAL_TEACHER_CREATED",'+
            '"cura_user_id": "69420",'+
            '"start_time": "2011-10-05T14:48:00.000Z",'+
            '"end_time": "2011-10-05T14:48:00.000Z",'+
            '"created_at": "2011-10-05T14:48:00.000Z"}]';
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/v1/CuraSync';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = response;
        
        CuraSync.CuraSyncReturn result = CuraSync.doPost();
        
        
        
    }
    
    @isTest static void itShouldDoPostOppNoRecords() {
        
        String body = '[{"event_name": "TRIAL_TEACHER_CREATED",'+
            '"cura_user_id": "69420",'+
            '"start_time": "2011-10-05T14:48:00.000Z",'+
            '"end_time": "2011-10-05T14:48:00.000Z",'+
            '"created_at": "2011-10-05T14:48:00.000Z"}]';
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/v1/CuraSync';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = response;
        
        CuraSync.CuraSyncReturn result = CuraSync.doPost();
        
        
        
    }
    
    @isTest static void itShouldDoPostInvalid() {
        
        String body = '[{}]';
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/v1/CuraSync';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = response;
        
        CuraSync.CuraSyncReturn result = CuraSync.doPost();
        
        
        
    }
    
    @isTest static void itShouldDoPostOpp() {
        
        Insert new Lead(cura_UserID__c = '69420', LastName = 'Wheeler', Status = 'New');
        
        String body = '[{"event_name": "TRIAL_TEACHER_CREATED",'+
            '"cura_user_id": "69420",'+
            '"start_time": "2011-10-05T14:48:00.000Z",'+
            '"end_time": "2011-10-05T14:48:00.000Z",'+
            '"created_at": "2011-10-05T14:48:00.000Z"}]';
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/v1/CuraSync';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = response;
        
        CuraSync.CuraSyncReturn result = CuraSync.doPost();
        
        
        
    }
    
    @isTest static void itShouldTestEmptyClasses() { 
        CuraSyncMapper.test();
        CuraSyncMappings.test();
    }
    
    @isTest static void itShouldDoPostBooking() {
        
        Account a = new Account(Name = 'test', Territory__c = 'Elevate Australia');
        insert a;
        
        String body = '[{"event_name": "BOOKING_TEACHER_CREATED",'+
            '"cura_subscription_id": "abcd",'+
            '"cura_user_id": "abcd",'+
            '"salesforce_school_id": "'+a.Id+ '",'+
            '"start_time": "2011-10-05T14:48:00.000Z",'+
            '"end_time": "2011-10-05T14:48:00.000Z",'+
            '"created_at": "2011-10-05T14:48:00.000Z"}]';
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/v1/CuraSync';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = response;
        
        CuraSync.CuraSyncReturn result = CuraSync.doPost();
       
    }
    @isTest static void itShouldDoPostUpdateBooking() {
        Account a = new Account(Name = 'test', Territory__c = 'Elevate Australia');
        insert a;
        
        Contact c = new Contact(LastName = 'test');
        insert c;
        
        Id curaRTId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName().get('Cura').getRecordTypeId();

        Booking__c b = new Booking__c(Name = 'test', cura_subscription_id__c = 'abcd', RecordTypeId =curaRTId);
        insert b;
               
        String body = '[{"event_name": "BOOKING_STUDENT_WORK_SUBMITTED",'+
            '"cura_subscription_id": "abcd",'+
            '"cura_user_id": "abcd",'+
            '"quantity": 69,'+
            '"created_at": "2011-10-05T14:48:00.000Z"}]';
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/v1/CuraSync';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = response;
        
        CuraSync.CuraSyncReturn result = CuraSync.doPost();
    }
    @isTest static void itShouldDoPostBookingWithOpp() {
             
        Account a = new Account(Name = 'test', Territory__c = 'Elevate Australia');
        insert a;
        
        Opportunity o = new Opportunity(Name = 'test', Cura_User_Id__c = 'abcd', StageName = 'New', CloseDate = Date.today());
        insert o;
        
        String body = '[{"event_name": "BOOKING_TEACHER_CREATED",'+
            '"cura_subscription_id": "abcd",'+
            '"cura_user_id": "abcd",'+
            '"salesforce_school_id": "'+a.Id+ '",'+
            '"start_time": "2011-10-05T14:48:00.000Z",'+
            '"end_time": "2011-10-05T14:48:00.000Z",'+
            '"created_at": "2011-10-05T14:48:00.000Z"}]';
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/v1/CuraSync';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = response;
        
        CuraSync.CuraSyncReturn result = CuraSync.doPost();
       
    }
    @isTest static void itShouldDoPostFailedBooking() {
        
        Account a = new Account(Name = 'test', Territory__c = 'Elevate Australia');
        insert a;
        
        String body = '[{"event_name": "BOOKING_TEACHER_CREATED",'+
            '"cura_subscription_id": "abcd",'+
            '"cura_user_id": "abcd",'+
            '"salesforce_school_id": "'+a.Id+ '",'+
            '"start_time": "notadate",'+
            '"end_time": "2011-10-05T14:48:00.000Z",'+
            '"created_at": "2011-10-05T14:48:00.000Z"}]';
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/v1/CuraSync';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = response;
        
        CuraSync.CuraSyncReturn result = CuraSync.doPost();
       
    }
}