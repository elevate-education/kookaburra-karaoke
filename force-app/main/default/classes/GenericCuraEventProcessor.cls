global class GenericCuraEventProcessor implements ICuraEventProcessor {


    global class GenericCuraEventProcessorException extends Exception {
    }

    global void processEvents(CuraMappingsV2.CuraEventFieldMap mapping, List<Object> incomingEvents, Id apexLogId) {

        List<SObject> records = new List<SObject>();
        List<Apex_Log_Entry__c> ales = new List<Apex_Log_Entry__c>();

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