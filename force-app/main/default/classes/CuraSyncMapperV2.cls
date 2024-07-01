public with sharing class CuraSyncMapperV2 {

    public static void handleSync(List<Object> input) {

        //sort the incoming events into their event types

        Map<String, List<Object>> sortedInput = new Map<String, List<Object>>();
        for(Object o :input) {
            Map<String, Object> obj = (Map<String, Object>)o;
            String eventName = (String)obj.get('event_name');
            List<Object> sorted = sortedInput.get(eventName) != null ? sortedInput.get(eventName) : new List<Object>();
            sorted.add(o);
            sortedInput.put(eventName, sorted);
        }  

        //process each event type
        for(String k: sortedInput.keySet()) {
            CuraMappingsV2.CuraEventFieldMap mapping = CuraMappingsV2.allMappings.get(k);
            ICuraEventProcessor mapper = (ICuraEventProcessor)Type.forName(mapping.eventProcessorClass).newInstance();

            Map<String, String> logData = new Map<String, String>{
                'mapperClass' => mapping.eventProcessorClass,
                'sObjectName' => mapping.sObjectName,
                'eventName' => k
            };

            Apex_Log__c newLog = new Apex_Log__c(
                Log_Data__c = JSON.serialize(logData)
            );
            insert newLog;

            mapper.processEvents(mapping, sortedInput.get(k), newLog.Id);
        }
    }  
}