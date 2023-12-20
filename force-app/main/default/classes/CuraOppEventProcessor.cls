global class CuraOppEventProcessor implements ICuraEventProcessor {
    
    global class CuraOppEventProcessorException extends Exception {
    }
    
    global void processEvents(CuraMappingsV2.CuraEventFieldMap mapping, List<Object> incomingEvents, Id apexLogId) {
        
        Map<String, Apex_Log_Entry__c> ales = new Map<String, Apex_Log_Entry__c>();
        
        try {
            //List<SObject> records = new List<SObject>();
            Map<String, SObject> idToRecordMap = new Map<String, SObject>();
            
            //map to sObjects
            for(Object i :incomingEvents) {
                
                Map<String, Object> event = (Map<String, Object>)i;
                Map<String, Object> logData = new Map<String, Object>();
                Apex_Log_Entry__c ale = new Apex_Log_Entry__c(Apex_Log__c = apexLogId);
                
                logdata.put('eventData', event);
                
                try{
                    sObject record = CuraMappingUtils.mapCuraEvent(mapping, event);
                    System.debug('mapped record' + record);
                    idToRecordMap.put((String)record.get(mapping.externalIDFieldName) , record);
                }
                catch (Exception e) {
                    logData.put('error', e.getMessage());
                    logData.put('stackTrace', e.getStackTraceString());
                }
                ale.message__c = JSON.serialize(logData);
                
                if(ale != null) {
                    ales.put((String)event.get('cura_user_id'), ale);
                } 
            }
            
            // find existing leads
            
            LeadStatus convertStatus = [SELECT Id, ApiName, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
            
            
            Map<String, Lead> existingLeads = new Map<String, Lead>();
            for(Lead l: [SELECT Id, cura_UserID__c, Account__c FROM Lead WHERE cura_UserID__c IN :idToRecordMap.keySet() AND Status != :convertStatus.ApiName]) {
                existingLeads.put(l.cura_UserID__c, l);
            }
            
            List<Database.LeadConvert> convertedLeads = new List<Database.LeadConvert>();
            
            //convert leads > opp,act,ct
            List<Opportunity> unconverted = new List<Opportunity>();
            for(String curaId :idToRecordMap.keySet()) {
                //get log event
                Apex_Log_Entry__c ale = ales.get(curaId);
                
                if(existingLeads.get(curaId) != null) {
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setConvertedStatus(convertStatus.ApiName);
                    lc.setLeadId(existingLeads.get(curaId).Id);
                    lc.setAccountId(existingLeads.get(curaId).Account__c);
                    convertedLeads.add(lc);
                }
                else {
                    //log if we can't find a matching lead
                    Map<String, Object> logData = new Map<String, Object>();
                    if(ale != null) {
                   		logData = (Map<String, Object>) JSON.deserializeUntyped(ale.message__c);
                        logData.put('error', 'no lead found for this event');
                    	ale.message__c = JSON.serialize(logData);
                    }
                    else {
                		ale = new Apex_Log_Entry__c(Apex_Log__c = apexLogId);
                        logData.put('error', 'no lead found for this event');
                    	ale.message__c = JSON.serialize(logData);
                    }
                    
                    Opportunity ucv = (Opportunity)idToRecordMap.get(curaId);
                    ucv.Name = 'Cura - No Lead Found';
                    ucv.CloseDate = Date.today()+30;
                    ucv.StageName = 'New';
					                    
                    unconverted.add(ucv);
                }
                if(ale != null) {
                    ales.put(curaId, ale);
                }
            }
            
           
            Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(mapping.sObjectName).getDescribe().fields.getMap();
            
            Map<String, Opportunity> existingOpps = new Map<String, Opportunity>();
            for(Opportunity o : [SELECT Id, Cura_User_Id__c, Name FROM Opportunity WHERE Cura_User_Id__c IN :idToRecordMap.keySet()]) {
                existingOpps.put(o.Cura_User_Id__c, o);
            }

            for(Opportunity o :unconverted) {
                if(existingOpps.get(o.Cura_User_ID__c) != null && existingOpps.get(o.Cura_User_ID__c).Name != null) {
                    o.Name = existingOpps.get(o.Cura_User_ID__c).Name;
                    o.Id = existingOpps.get(o.Cura_User_ID__c).Id;
                }
            }
            
            List<Database.UpsertResult> ucvResult = Database.upsert(unconverted, fields.get(mapping.externalIDFieldName));  
            
            for(Database.UpsertResult res :ucvResult) {
                if(!res.isSuccess()) {
                    throw new CuraOppEventProcessorException('Some failed to process');
                }

            }
          
            
            //convert leads
            List<Database.LeadConvertResult> result = Database.convertLead(convertedLeads);
            
            List<Id> oppIds = new List<Id>();
            Map<Id, Id> leadToOppId = new Map<Id, Id>();
            for(Database.LeadConvertResult lcr :result) {
                oppIds.add(lcr.getOpportunityId());
                leadToOppId.put(lcr.getLeadId(), lcr.getOpportunityId());
            }
            
            Map<String, Id> curaUsrIdToOppId = new Map<String, Id>();
            
            for(Lead l :existingLeads.values()) {
                if(leadToOppId.get(l.Id) != null) {
                    curaUsrIdToOppId.put(l.cura_UserID__c, leadToOppId.get(l.Id));
                }
            }
            
            List<Opportunity> toUpdate = new List<Opportunity>();
            
            for(String curaUsrId :curaUsrIdToOppId.keySet()) {
                Opportunity mergeOpp = (Opportunity)idToRecordMap.get(curaUsrId);
                system.debug('mo' + mergeOpp);
               	system.debug(curaUsrIdToOppId.get(curaUsrId));
                mergeOpp.Id = curaUsrIdToOppId.get(curaUsrId);
                toUpdate.add(mergeOpp);
            }
            
            update toUpdate;

            Database.insert(ales.values());
            
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
            Database.insert(ales.values());
            throw e;
        }
        
    }
    
    
}