global class GenericCuraEventProcessor implements ICuraEventProcessor {


    global class GenericCuraEventProcessorException extends Exception {
    }

    global void processEvents(CuraMappingsV2.CuraEventFieldMap mapping, List<Object> incomingEvents, Id apexLogId) {

        List<SObject> records = new List<SObject>();
        List<Apex_Log_Entry__c> ales = new List<Apex_Log_Entry__c>();
        
        //get existing records, for addition type
        //Set<String> externalIds = new Set<String>();/
        //Set<String> queryFields = new Set<String>();

        /*for(Object i :incomingEvents) { 
            CuraMappingUtils.ExistingFieldsQuery result = CuraMappingUtils.getIdForExisting(mapping, (Map<String, Object>)i);
            externalIds.add(result.recordExternalId);
            queryFields.addAll(result.queryFields);
        }
        
        Map<String, SObject> existingRecords = new Map<String, SObject>();
        if(!externalIds?.isEmpty() && !queryFields?.isEmpty()) {
            
            String query = 'SELECT ID, ' + mapping.externalIDFieldName + ', ' + String.join(new List<String>(queryFields),',').substringBeforeLast(',');
            query += ' FROM ' + mapping.sObjectName + ' WHERE ' + mapping.externalIDFieldName;
            query += ' IN (' + String.join(new List<String>(externalIds),',').substringBeforeLast(',') + ')';            
            List<SObject> existing = Database.query(query);
            for(SObject r :existing) {
                existingRecords.put(
                	(String) r.get(mapping.externalIDFieldName),
                    r
                );
            }   
        }*/
        for(Object i :incomingEvents) {

            Map<String, Object> logData = new Map<String, Object>();
            Apex_Log_Entry__c ale = new Apex_Log_Entry__c(Apex_Log__c = apexLogId);
            try {
                logdata.put('eventData', i);
                sObject record = CuraMappingUtils.mapCuraEvent(mapping, (Map<String, Object>)i);//, existingRecords);
                records.add(record);
            }
            catch(Exception e) {
                logData.put('error', e.getMessage());
                logData.put('stackTrace', e.getStackTraceString());
            }

            ale.message__c = JSON.serialize(logData);
            ales.add(ale);
        }
        
        try {
            Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(mapping.sObjectName).getDescribe().fields.getMap();
            List<Database.UpsertResult> result = Database.upsert(records, fields.get(mapping.externalIDFieldName));   
            insert ales;
        }
        catch(Exception e) {
            Apex_Log_Entry__c ale = new Apex_Log_Entry__c(Apex_Log__c = apexLogId);
            Map<String, Object> logData = new Map<String, Object>{
                'error' => e.getMessage(),
                'stackTrace' => e.getStackTraceString()
            };
            ale.message__c = JSON.serialize(logData);
            ales.add(ale);
            insert ales;
            throw e;
        }
    }

}