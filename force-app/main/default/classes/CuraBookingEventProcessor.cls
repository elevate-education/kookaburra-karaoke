global class CuraBookingEventProcessor implements ICuraEventProcessor {
    
    global class CuraBookingEventProcessorException extends Exception {
    }
    
    global void processEvents(CuraMappingsV2.CuraEventFieldMap mapping, List<Object> incomingEvents, Id apexLogId) {
        
        Map<String, Apex_Log_Entry__c> ales = new Map<String, Apex_Log_Entry__c>();
        
        try {
            List<SObject> records = new List<SObject>();
            List<String> userIds = new List<String>();
            
            //map to sObjects
            for(Object i :incomingEvents) {
                System.debug(i);
                
                Map<String, Object> event = (Map<String, Object>)i;
                Map<String, Object> logData = new Map<String, Object>();
                Apex_Log_Entry__c ale = new Apex_Log_Entry__c(Apex_Log__c = apexLogId);
                
                logdata.put('eventData', event);
                System.debug(event);

                try{
                    System.debug(mapping);
                    sObject record = CuraMappingUtils.mapCuraEvent(mapping, event);
 
                    DateTime startDate = (DateTime)record.get('cura_Start_Time__c');
                    
                    //set Date
                    record.put('Date__c', startDate.date());
                                       
                    //set name to calc'd value
                    record.put('name', 'Cura Subscription - ' + String.valueof(startDate.year()));
                    
                    system.debug(record);
                    records.add(record);
                    userIds.add((String) record.get('cura_user_id__c'));
                }
                catch (Exception e) {
                    logData.put('error', e.getMessage());
                    logData.put('stackTrace', e.getStackTraceString());
                    System.debug(logData);
                    ale.message__c = JSON.serialize(logData);
                    System.debug(ales.values());
                    Database.upsert(ales.values());
                    throw e;
                }
                ale.message__c = JSON.serialize(logData);
                
                if(ale != null) {
                    ales.put((String)event.get('cura_user_id'), ale);
                } 
            }
            Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(mapping.sObjectName).getDescribe().fields.getMap();
            List<Database.UpsertResult> result = Database.upsert(records, fields.get(mapping.externalIDFieldName));  
            System.debug(records);
			System.debug(result);
            insert ales.values();
            
            //find existing opp to update
            Map<String, Opportunity> userToOppMap = new Map<String, Opportunity>();
            try {
                List<Opportunity> opps = [SELECT Id, StageName, Cura_User_Id__c, Primary_Contact__c
                                          FROM Opportunity 
                                          WHERE Cura_User_Id__c IN :userIds AND StageName != 'Closed/Won'];
                
                for(Opportunity o :opps) {
                    o.StageName = 'Closed/Won';
                    userToOppMap.put(o.Cura_User_Id__c, o);
                }
                update opps;
                for(SObject bk : records) {
                    if(userToOppMap.get((String)bk.get('cura_user_id__c')) != null) {
                        
                        system.debug(userToOppMap.get((String)bk.get('cura_user_id__c')));
                        
                    	bk.put('Opportunity__c', userToOppMap.get((String)bk.get('cura_user_id__c')).Id );
                    	bk.put('Contact_Name__c', userToOppMap.get((String)bk.get('cura_user_id__c')).Primary_Contact__c );
                    }
                    system.debug(bk);
                }
                update records;
            }
            catch(Exception e) {
            Apex_Log_Entry__c ale = new Apex_Log_Entry__c(Apex_Log__c = apexLogId);
            Map<String, Object> logData = new Map<String, Object>{
                'error' => e.getMessage(),
                    'stackTrace' => e.getStackTraceString()
                    };
                        ale.message__c = JSON.serialize(logData);
            ales.put('', ale);
            System.debug(ales.values());
            Database.upsert(ales.values());
            throw e;
        }
         
            
        }
        catch(Exception e) {
            Apex_Log_Entry__c ale = new Apex_Log_Entry__c(Apex_Log__c = apexLogId);
            Map<String, Object> logData = new Map<String, Object>{
                'error' => e.getMessage(),
                    'stackTrace' => e.getStackTraceString()
                    };
                        ale.message__c = JSON.serialize(logData);
            ales.put('', ale);
            System.debug(ales.values());
            Database.upsert(ales.values());
            throw e;
        }    
    }
}