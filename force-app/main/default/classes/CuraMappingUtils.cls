public class CuraMappingUtils {
    
    public class ExistingFieldsQuery {
		public String recordExternalId;
        public Set<String> queryFields;
    }

    public static Object getTypedValue(Object value, CuraMappingsV2.FieldInfo info, String sObjectType) {
        if(info.dataType == 'String') {
            return String.valueOf(value);
        }
        else if(info.dataType == 'Number') {
            return Decimal.valueOf(String.valueOf(value));
        }
        else if(info.dataType == 'Boolean') {
            return Boolean.valueOf(value);
        }
        else if(info.dataType == 'DateTime') {
            return JSON.deserialize(JSON.serialize(value), Datetime.class);
        }
        else if(info.dataType == 'DateTimeToDate') {
            DateTime temp = (DateTime)JSON.deserialize(JSON.serialize(value), Datetime.class);
            return temp.date();
        }
        else if(info.dataType == 'RecordType') {
            DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(sObjectType).getDescribe();
            Map<String,Schema.RecordTypeInfo> rtMapByName = objDescribe.getRecordTypeInfosByDeveloperName();
            Schema.RecordTypeInfo rtByName =  rtMapByName.get(String.valueOf(value));
            return rtByName.getRecordTypeId();
        }
        else {
            return value;
        }
    }
    
    /*public static Object getCalculatedValue(sObject existing, Object value, CuraMappingsV2.FieldInfo info, String sObjectType) {
        if(info.dataType == 'Addition') {
            if(existing != null) {
                Decimal currentValue = (Decimal) existing.get(info.fieldName);
                return currentValue + Decimal.valueOf(String.valueOf(value));           
            }
            else { //if no existing, return the value we have
                return Decimal.valueOf(String.valueOf(value));
            }
        }
        else {
            return value;
        }
    }*/
    

    public static SObject mapCuraEvent(CuraMappingsV2.CuraEventFieldMap mapping, Map <String, Object> input){ //Map<String, sObject> existingRecords) {
        
        sObject sObj = Schema.getGlobalDescribe().get(mapping.sObjectName).newSObject();

        Map<String, SObjectField> fieldMap = sObj.getSobjectType().getDescribe().fields.getMap();

        // map dynamic fields
        for(String k :input.keySet()) {
            if(mapping.fieldMap.get(k) != null) {
                sObj.put(
                    mapping.fieldMap.get(k).fieldName,
                    getTypedValue(input.get(k), mapping.fieldMap.get(k), mapping.sObjectName)
                );
            }
        }
        
        //map calculated fields
        /*if(existingRecords != null) {
            sObject existing = existingRecords.get((String)sObj.get(mapping.externalIDFieldName));
            for(String k :input.keySet()) {
                
                if(mapping.fieldMap.get(k) != null) {
                    sObj.put(
                        mapping.fieldMap.get(k).fieldName,
                        getCalculatedValue(existing, input.get(k), mapping.fieldMap.get(k), mapping.sObjectName)
                    );
                }
            }
        }*/
        
        //map hardcoded values
        if(mapping.hardcodeValues != null) {
            for(CuraMappingsV2.FieldInfo hc :mapping.hardcodeValues) {
                sObj.put(
                    hc.fieldName, 
                    getTypedValue(hc.hardCodeValue, hc, mapping.sObjectName)
                );
            }
        }
        System.debug(sObj);
        return sObj;
        
    }
    
    /*public static ExistingFieldsQuery getIdForExisting(CuraMappingsV2.CuraEventFieldMap mapping, Map <String, Object> input) {
       
        String extId;
        ExistingFieldsQuery result = new ExistingFieldsQuery();
        result.queryFields = new Set<String>();
        
        for(String k :input.keySet()) {
            if(k == mapping.externalIDFieldName) {
                result.recordExternalId = (String) getTypedValue(input.get(k), mapping.fieldMap.get(k), mapping.sObjectName);
            }
            if(mapping.fieldMap?.get(k)?.dataType == 'Addition') { // Additional query types go here
                result.queryFields.add(mapping.fieldMap.get(k).fieldName);
            }            
        }
         
        return result;
        
    }*/
}