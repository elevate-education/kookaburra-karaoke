@RestResource(urlMapping='/v1/CuraSync')
global with sharing class CuraSync {

    global class CuraSyncReturn {
        global Integer code;
        global String result;
        global String message;
    
        global CuraSyncReturn(Integer code, String result, String message) {
            this.code = code;
            this.result = result;
            this.message = message;
        }
    }
    
    @HttpPost
    global static CuraSyncReturn doPost(){
        RestRequest req = RestContext.request;
        RestResponse res = Restcontext.response;
        
        List<Object> syncRequest = (List<Object>)JSON.deserializeUntyped(req.requestBody.toString());

        try {
            //CuraSyncMapper.handleSync(syncRequest);
            CuraSyncMapperV2.handleSync(syncRequest);

        }
        catch(Exception e) {
            String error = e.getMessage() + ' ' + e.getStackTraceString();
            system.debug(error);
            res.statuscode = 500;
            return new CuraSyncReturn(500, 'error', error );
        }
        
        res.statuscode = 200;
        return new CuraSyncReturn(200, 'ok', 'ok');
    }
}