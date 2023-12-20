global class CuraMappingsV2 {
    
    global class FieldInfo {
        global string fieldName;
        global string dataType;
        global Object hardCodeValue;
        
        global FieldInfo(String fieldName, String dataType, Object hardCodeValue) {
            this.fieldName = fieldName;
            this.dataType = dataType;
            this.hardCodeValue = hardCodeValue;
        }
        global FieldInfo(String fieldName, String dataType) {
            this.fieldName = fieldName;
            this.dataType = dataType;
        }
    }
    
    global class CuraEventFieldMap {
        global String sObjectName;
        // external ID field used to upsert with
        global String externalIDFieldName;
        // map of CuraFieldName => SFFieldName
        global Map<String, FieldInfo> fieldMap;
        // map of CuraFieldName => SFFieldName
        global List<FieldInfo> hardcodeValues;
        //class to process the event
        global String eventProcessorClass;
        
        global CuraEventFieldMap(String sObjectName, 
                                 String externalIDFieldName, 
                                 Map<String, FieldInfo> fieldMap, 
                                 List<FieldInfo> hardcodeValues,
                                 String eventProcessorClass) {
                                     this.sObjectName = sObjectName;
                                     this.externalIDFieldName = externalIDFieldName;
                                     this.fieldMap = fieldMap;
                                     this.hardcodeValues = hardcodeValues;
                                     this.eventProcessorClass = eventProcessorClass;
                                 }
        
    }
    
    global static Map<String, CuraEventFieldMap> allMappings = new Map<String, CuraEventFieldMap>{
        'PREVIEW_TEACHER_CREATED' => new CuraEventFieldMap(
            'Lead', 
            'cura_UserID__c',
            new Map<String, FieldInfo>{
                'first_name' => new FieldInfo('FirstName', 'String'),
                    'last_name' => new FieldInfo('LastName', 'String'),
                    'email' => new FieldInfo('Email', 'String'),
                    'cura_user_id' => new FieldInfo('cura_UserID__c', 'String'),
                    'salesforce_school_id' => new FieldInfo('Account__c', 'String'),
                    'cura_school_id' =>  new FieldInfo('cura_School_ID__c', 'String'),
                    'start_time' => new FieldInfo('cura_Start_Time__c', 'DateTime'),
                    'end_time' => new FieldInfo('cura_End_Time__c', 'DateTime')
                    },
            new List<FieldInfo>{new FieldInfo('Status', 'String', 'MQL')},
            'GenericCuraEventProcessor'
        ),
            'PREVIEW_TEACHER_LOGIN' => new CuraEventFieldMap(
                'Lead', 
                'cura_UserID__c',
                new Map<String, FieldInfo>{
                    'cura_user_id' => new FieldInfo('cura_UserID__c', 'String')//'cura_UserID__c'
                        },
                new List<FieldInfo>{new FieldInfo('cura_Logged_In__c', 'Boolean', true)},
                'GenericCuraEventProcessor'
            ),
            'PREVIEW_TEACHER_FAVOURITE' => new CuraEventFieldMap(
                'Lead', 
                'cura_UserID__c',
                new Map<String, FieldInfo>{
                    'cura_user_id' => new FieldInfo('cura_UserID__c', 'String')//'cura_UserID__c'
                        },
                new List<FieldInfo>{
                    new FieldInfo('cura_Favourited__c', 'Boolean', true)
                        },
                'GenericCuraEventProcessor'
            ),
            //OPPORTUNITY
            'TRIAL_TEACHER_CREATED' => new CuraEventFieldMap(
                'Opportunity', 
                'cura_UserID__c',
                new Map<String, FieldInfo>{
                    'cura_user_id' => new FieldInfo('cura_UserID__c', 'String'),
                        'start_time' => new FieldInfo('cura_Start_Time__c', 'DateTime'),
                        'end_time' => new FieldInfo('cura_End_Time__c', 'DateTime')
                        },
                null,
                'CuraOppEventProcessor'
            ),
            'TRIAL_TEACHER_LOGIN' => new CuraEventFieldMap(
                'Opportunity', 
                'cura_User_ID__c',
                new Map<String, FieldInfo>{
                    'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String'),
                        'created_at' => new FieldInfo('cura_Logged_In_Time__c', 'DateTime')
                        },
                null,
                'GenericCuraEventProcessor'
            ),
            'TRIAL_TEACHER_EXPLORE' => new CuraEventFieldMap(
                'Opportunity', 
                'cura_User_ID__c',
                new Map<String, FieldInfo>{
                    'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String'),
                        'created_at' => new FieldInfo('cura_Logged_In_Time__c', 'DateTime')
                        },
                new List<FieldInfo>{
                    new FieldInfo('cura_Teacher_Explored__c', 'Boolean', true)
                        },
                'GenericCuraEventProcessor'
            ),
            'TRIAL_TEACHER_CREATE_CLASSROOM' => new CuraEventFieldMap(
                'Opportunity', 
                'cura_User_ID__c',
                new Map<String, FieldInfo>{
                    'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String')
                        },
                new List<FieldInfo>{
                    new FieldInfo('StageName', 'String', 'Classroom Created'),
                        new FieldInfo('cura_Classroom_Created__c', 'Boolean', true)
                        },
                'GenericCuraEventProcessor'
            ),
            'TRIAL_TEACHER_USE_CLASSROOM' => new CuraEventFieldMap(
                'Opportunity', 
                'cura_User_ID__c',
                new Map<String, FieldInfo>{
                    'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String')//'cura_UserID__c'
                        },
                new List<FieldInfo>{
                    new FieldInfo('cura_Classroom_Used__c', 'Boolean', true)
                        },
                'GenericCuraEventProcessor'
            ),
            'TRIAL_TEACHER_ADD_STUDENT' => new CuraEventFieldMap(
                'Opportunity', 
                'cura_User_ID__c',
                new Map<String, FieldInfo>{
                    'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String'),
                        'quantity' => new FieldInfo('cura_Students_Added__c', 'Number')
                        },
                new List<FieldInfo>{
                },
                'GenericCuraEventProcessor'
            ),
            'TRIAL_TEACHER_OPT_OUT' => new CuraEventFieldMap(
                'Opportunity', 
                'cura_User_ID__c',
                new Map<String, FieldInfo>{
                    'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String'),
                        'created_at' => new FieldInfo('cura_End_Time__c', 'DateTime')
                        },
                new List<FieldInfo>{
                    new FieldInfo('cura_Trial_Cancelled__c', 'Boolean', true),
                        new FieldInfo('StageName', 'String', 'Closed Lost'),
                        new FieldInfo('Lost_Reason_Details__c', 'String', 'Trial Opt Out')  
                        },
                'GenericCuraEventProcessor'
            ),
            //BOOKINGS
            'BOOKING_TEACHER_CREATED' => new CuraEventFieldMap(
                'Booking__c', 
                'cura_subscription_id__c',
                new Map<String, FieldInfo>{
                    'cura_subscription_id' => new FieldInfo('cura_subscription_id__c', 'String'),
                        'salesforce_school_id' => new FieldInfo('school__c', 'String'),
                        'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String'),
                        'start_time' => new FieldInfo('cura_Start_Time__c', 'DateTime'),
                        'end_time' => new FieldInfo('cura_End_Time__c', 'DateTime')
                        },
                new List<FieldInfo>{
                        new FieldInfo('RecordTypeId', 'RecordType', 'Cura'),
                        new FieldInfo('Business_Unit__c', 'String', 'Cura'),
                        new FieldInfo('Status__c', 'String', 'New Booking'),
                        new FieldInfo('Name', 'String', 'Cura Booking')
                        },
                'CuraBookingEventProcessor'
            ),
            'BOOKING_TEACHER_EXPLORED' => new CuraEventFieldMap(
                'Booking__c',
                'cura_subscription_id__c',
                new Map<String, FieldInfo>{
                    'cura_subscription_id' => new FieldInfo('cura_subscription_id__c', 'String'),
                        'cura_user_id' => new FieldInfo('cura_user_id__c', 'String'),
                        'created_at' => new FieldInfo('cura_End_Time__c', 'DateTime')
                        },
                new List<FieldInfo>{new FieldInfo('cura_Teacher_Explored__c', 'Boolean', true)},
                'GenericCuraEventProcessor'
            ),
            'BOOKING_TEACHER_LOGIN' => new CuraEventFieldMap(
                'Booking__c',
                'cura_subscription_id__c',
                new Map<String, FieldInfo>{
                    'cura_subscription_id' => new FieldInfo('cura_subscription_id__c', 'String'),
                        'created_at' => new FieldInfo('cura_Logged_In_Time__c', 'DateTime')
                        },
                null,
                'GenericCuraEventProcessor'
            ),
            'BOOKING_TEACHER_SUBJECT' => new CuraEventFieldMap(
                'Booking__c',
                'cura_subscription_id__c',
                new Map<String, FieldInfo>{
                    'cura_subscription_id' => new FieldInfo('cura_subscription_id__c', 'String'),
                        'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String'),
                        'subject' => new FieldInfo('cura_Teacher_Subject__c', 'String'),
                        'created_at' => new FieldInfo('cura_End_Time__c', 'DateTime')
                        },
                null,
                'GenericCuraEventProcessor'
            ),
            'BOOKING_TEACHER_CREATE_CLASSROOM' => new CuraEventFieldMap(
                'Booking__c',
                'cura_subscription_id__c',
                new Map<String, FieldInfo>{
                    'cura_subscription_id' => new FieldInfo('cura_subscription_id__c', 'String'),
                        'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String'),
                        'created_at' => new FieldInfo('cura_End_Time__c', 'DateTime')
                        },
                new List<FieldInfo>{new FieldInfo('cura_Classroom_Created__c', 'Boolean', true)},
                'GenericCuraEventProcessor'
            ),
            'BOOKING_TEACHER_USE_CLASSROOM' => new CuraEventFieldMap(
                'Booking__c',
                'cura_subscription_id__c',
                new Map<String, FieldInfo>{
                    'cura_subscription_id' => new FieldInfo('cura_subscription_id__c', 'String'),
                        'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String'),
                        'created_at' => new FieldInfo('cura_End_Time__c', 'DateTime')
                        },
                new List<FieldInfo>{new FieldInfo('cura_Teacher_Use_Classroom__c', 'Boolean', true)},
                'GenericCuraEventProcessor'
            ),
            'BOOKING_TEACHER_ADD_STUDENT' => new CuraEventFieldMap(
                'Booking__c',
                'cura_subscription_id__c',
                new Map<String, FieldInfo>{
                    'cura_subscription_id' => new FieldInfo('cura_subscription_id__c', 'String'),
                        'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String'),
                        'created_at' => new FieldInfo('cura_End_Time__c', 'DateTime'),
                        'quantity' => new FieldInfo('cura_Students_added__c', 'Number')
                        },
                null,
                'GenericCuraEventProcessor'
            ),
            'BOOKING_STUDENT_WORK_SUBMITTED' => new CuraEventFieldMap(
                'Booking__c',
                'cura_subscription_id__c',
                new Map<String, FieldInfo>{
                    'cura_subscription_id' => new FieldInfo('cura_subscription_id__c', 'String'),
                        'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String'),
                        'created_at' => new FieldInfo('cura_End_Time__c', 'DateTime'),
                        'quantity' => new FieldInfo('cura_Students_added__c', 'Number')
                        },
                null,
                'GenericCuraEventProcessor'
            ),
            'BOOKING_CANCELLED' => new CuraEventFieldMap(
                'Booking__c',
                'cura_subscription_id__c',
                new Map<String, FieldInfo>{
                    'cura_subscription_id' => new FieldInfo('cura_subscription_id__c', 'String'),
                        'cura_user_id' => new FieldInfo('cura_User_ID__c', 'String'),
                        'created_at' => new FieldInfo('cura_End_Time__c', 'DateTime')
                        },
                new List<FieldInfo>{
                    new FieldInfo('cura_Booking_Cancelled__c', 'Boolean', true),
                        new FieldInfo('Stage__c', 'String', 'Cancelled')
                        },
                'GenericCuraEventProcessor'
            )};
                }