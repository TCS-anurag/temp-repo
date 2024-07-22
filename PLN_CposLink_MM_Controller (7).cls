/**
* Mix & Match CPOS link controller class 
*/
public with sharing class PLN_CposLink_MM_Controller {
    /**
* Mix & Match wrapper class 
*/
    public class MMDataSet implements Comparable{
        @AuraEnabled
        public Id mmID{get;set;}
        @AuraEnabled
        public Id mmDetailID{get;set;}
        @AuraEnabled
        public String productJan{get;set;}
        @AuraEnabled
        public String DPT{get;set;}
        @AuraEnabled
        public String mmCode{get;set;}
        @AuraEnabled
        public Decimal mmIndex{get;set;}
        @AuraEnabled
        public string lastUpdateDate{get;set;}
        @AuraEnabled
        public string applicationStartDate{get;set;}
        @AuraEnabled
        public Decimal mmQuantity1{get;set;}
        @AuraEnabled
        public Decimal mmPrice1{get;set;}
        @AuraEnabled
        public Decimal mmQuantity2{get;set;}
        @AuraEnabled
        public Decimal mmPrice2{get;set;}
        @AuraEnabled
        public String productName{get;set;}
        @AuraEnabled
        public String registrationNumber{get;set;}
        @AuraEnabled
        public String name{get;set;}
        @AuraEnabled
        public String mmdetailname{get;set;}

        public Integer compareTo(Object compareTo) {
            MMDataSet compareMMDataSet = (MMDataSet)compareTo;
            if (this.DPT != compareMMDataSet.DPT) {
                return this.DPT.compareTo(compareMMDataSet.DPT);
            } else if (this.mmCode != compareMMDataSet.mmCode) {
                return this.mmCode.compareTo(compareMMDataSet.mmCode);
            } else if (this.productJan != compareMMDataSet.productJan) {
                return this.productJan.compareTo(compareMMDataSet.productJan);
            } else {
                return this.applicationStartDate.compareTo(compareMMDataSet.applicationStartDate);
            }
        }
    }

/**
* Method to call link process
* @param processIds of type List
* @return List<String>
*/  
    @AuraEnabled
    public static List<String> cposMMLink(List<Id> processIds){
       List<String> errorList = new List<String> ();
       //try{
            String result = PLN_CposLink_MM_Ctl.linkMMCposInfo(processIds);
            errorList = PLN_CposLink_MM_Ctl.validationErrors;
            return errorList;
    }
/**
* Method to get M&M data from DB
* @param dpt of type String
* @param startDate1 of type String
* @param startDate2 of type String
* @param lastModifiedDate1 of type String
* @param lastModifiedDate2 of type String
* @return List<MMDataSet>
*/     
    @AuraEnabled(cacheable=true)
    public static List<MMDataSet> getMMData(String dpt, String startDate1, String startDate2, String lastModifiedDate1, String lastModifiedDate2){
        try{
            Set<Id> mmDetailIdSet = new Set<Id>();
            Set<Id> mmIdSet = new Set<Id>();          
            Map<Id,MMDataSet> mixToWrapperMap = new Map<Id,MMDataSet>();
            Map<Id,MMDataSet> mixToWrapperMapInter = new Map<Id,MMDataSet>();
            Map<Id,PLN_MM_ProductMaster__c> mmPMIMap = new Map<Id,PLN_MM_ProductMaster__c>();
            //Block     :Dynamic Query Creation Start
            List<String> wheres = new List<String>();
            List<String> wheresDPT = new List<String>();
            
            If(!String.isBlank(dpt)){
                wheresDPT.add( 'ProductMaster_Integration__r.ProductClassificationCode3__c LIKE' + '\'%' + String.escapeSingleQuotes(dpt) + '%\'');
            }
            If(!String.isBlank(startDate1)){
                wheres.add('StartDate__c >= ' +  startDate1  );
            }
            If(!String.isBlank(startDate2)){
                wheres.add('StartDate__c <= ' +  startDate2 );
            }
            If(!String.isBlank(lastModifiedDate1)){
                wheres.add('LastModifiedDate  >= ' +  lastModifiedDate1  );
            }
            If(!String.isBlank(lastModifiedDate2)){
                wheres.add('LastModifiedDate  <= ' +  lastModifiedDate2 );
            }            
            //Creating the MixMatch_Detail List dynamically            
            List<String> querymmDetail = new List<String>();
           //Adding inner query of Target stores as per TS2-5104  //For TS2-7975 added MixMatch_r.deleteflag
			//querymmDetail.add('SELECT Id,Name,MixMatch__r.Name, StartDate__c,LastModifiedDate,MM_Num1__c,MM_Price1__c,MM_Num2__c,MM_Price2__c,MixMatch__c,MixMatch__r.MMCode__c,RegistrationNumber__c,NumberOfTargetStores__c,SetSale_UnConfirmedFlag__c,Index__c, (Select id from TargetStores__r) FROM PLN_MixMatch_Detail__c WHERE MMCode__c <> null AND SetSale_UnConfirmedFlag__c=false AND ((((EndDate__c >= TODAY ) OR (Delete_flag__c = TRUE AND EndDate__c < TODAY) ) AND Linkflag__c = False) OR (MixMatch__r.Delete_flag__c = TRUE AND MixMatch__r.IsDeletionLinked_MM__c = false AND EndDate__c >= TODAY)) ');//original query before TS2-9695         
            querymmDetail.add('SELECT Id,Name,MixMatch__r.Name, StartDate__c,LastModifiedDate,MM_Num1__c,MM_Price1__c,MM_Num2__c,MM_Price2__c,MixMatch__c,MixMatch__r.MMCode__c,RegistrationNumber__c,NumberOfTargetStores__c,SetSale_UnConfirmedFlag__c,Index__c, (Select id from TargetStores__r LIMIT 1) FROM PLN_MixMatch_Detail__c WHERE MMCode__c <> null AND SetSale_UnConfirmedFlag__c=false AND ((EndDate__c >= TODAY AND Linkflag__c = False AND MixMatch__r.Delete_flag__c = False) OR (MixMatch__r.Delete_flag__c = TRUE AND MixMatch__r.IsDeletionLinked_MM__c = false AND EndDate__c >= TODAY AND  Linkflag__c = False)) ');// Changing this query for TS2-9695  // For TS2-11292  //For TS2-12001     	            
            if(wheres.size() > 0){
                querymmDetail.add('AND ' + String.join(wheres, ' AND ') );
            }
           // querymmDetail.add(' ORDER BY  MixMatch__r.MMCode__c,StartDate__c');
            querymmDetail.add(' LIMIT 1000');
            String soql = String.join(querymmDetail, ' ');
            List<PLN_MixMatch_Detail__c> newMMDetailList = Database.query(soql);
            //For TS2-7975 and TS2-8811
            List<String> querymmDetail1 = new List<String>();
            //querymmDetail1.add('SELECT Id,Name,MixMatch__r.Name,StartDate__c,LastModifiedDate,MM_Num1__c,MM_Price1__c,MM_Num2__c,MM_Price2__c,MixMatch__c,MixMatch__r.MMCode__c, RegistrationNumber__c,NumberOfTargetStores__c,SetSale_UnConfirmedFlag__c,Index__c, (Select id from TargetStores__r) FROM PLN_MixMatch_Detail__c WHERE MMCode__c <> null AND SetSale_UnConfirmedFlag__c=false AND  (MixMatch__r.Delete_flag__c = TRUE AND MixMatch__r.IsDeletionLinked_MM__c = false AND EndDate__c < TODAY) '); //original query before TS2-9695            
            querymmDetail1.add('SELECT Id,Name,MixMatch__r.Name,StartDate__c,LastModifiedDate,MM_Num1__c,MM_Price1__c,MM_Num2__c,MM_Price2__c,MixMatch__c,MixMatch__r.MMCode__c, RegistrationNumber__c,NumberOfTargetStores__c,SetSale_UnConfirmedFlag__c,Index__c, (Select id from TargetStores__r LIMIT 1) FROM PLN_MixMatch_Detail__c WHERE MMCode__c <> null AND SetSale_UnConfirmedFlag__c=false AND  ( MixMatch__r.IsDeletionLinked_MM__c = false AND EndDate__c < TODAY  AND Linkflag__c = False) ');// updated Query for TS2-9695 // For TS2-11292   //For TS2-12001   
            if(wheres.size() > 0){
                querymmDetail1.add('AND ' + String.join(wheres, ' AND ') );
            }
            querymmDetail1.add('ORDER BY EndDate__c DESC');
            querymmDetail1.add(' LIMIT 1000'); //For TS2-11292
            String soql1 = String.join(querymmDetail1, ' ');
            List<PLN_MixMatch_Detail__c> latestMMdetail = Database.query(soql1);
            Map<String,PLN_MixMatch_Detail__c> mapOfmmCodeMMdetail = new Map<String,PLN_MixMatch_Detail__c>();
            for(PLN_MixMatch_Detail__c mmDetail : latestMMdetail){
                if(!mapOfmmCodeMMdetail.containsKey(mmDetail.MixMatch__c)){
                   mapOfmmCodeMMdetail.put(mmDetail.MixMatch__c, mmDetail);  
                }                 
            }
            
            for(PLN_MixMatch_Detail__c mmDetail: newMMDetailList){
                if(mapOfmmCodeMMdetail.containsKey(mmDetail.MixMatch__c)){
                    mapOfmmCodeMMdetail.remove(mmDetail.MixMatch__c);
                }
            } 
            if(!mapOfmmCodeMMdetail.values().isEmpty()){
                newMMDetailList.addall(mapOfmmCodeMMdetail.values());
            } 
            //End for Detail 
            for(PLN_MixMatch_Detail__c mmDetail : newMMDetailList) {
                if(mmDetail.TargetStores__r.size()!=0){ //Added this check as part of TS2-5104
                    MMDataSet mmData = new MMDataSet();
                    mmIdSet.add(mmDetail.MixMatch__c);
                    mmDetailIdSet.add(mmDetail.Id);            
                    //Creation of Wrapper object data
                    mmData.mmID = mmDetail.MixMatch__c;            
                    mmData.mmDetailID = mmDetail.Id;            
                    mmData.mmCode = mmDetail.MixMatch__r.MMCode__c;
                    mmData.mmIndex = mmDetail.Index__c;
                    mmData.lastUpdateDate = mmDetail.LastModifiedDate.format('yyyy/MM/dd HH:mm:ss');
                    mmData.applicationStartDate = string.valueof(mmDetail.StartDate__c).replaceAll('-','/');
                    mmData.mmQuantity1 = mmDetail.MM_Num1__c;
                    mmData.mmPrice1 = mmDetail.MM_Price1__c;
                    mmData.mmQuantity2 = mmDetail.MM_Num2__c;
                    mmData.mmPrice2 = mmDetail.MM_Price2__c;
                    mmData.registrationNumber = string.valueof(mmDetail.RegistrationNumber__c);
                    mmData.name = mmDetail.Name;
                    mmData.mmdetailname = mmDetail.MixMatch__r.Name;
                    mixToWrapperMap.put(mmDetail.Id,mmData);
                }
            }
            //Creating PLN_MM_ProductMaster__c List dynamically
            List<String> querymmPMI = new List<String>();
            querymmPMI.add('SELECT Id,MixMatch__c, MixMatch__r.MMCode__c,ProductName__c,ProductMaster_Integration__r.ProductClassificationCode3__c,ProductMaster_Integration__r.RepresentativeJanCode__c FROM PLN_MM_ProductMaster__c WHERE MixMatch__c IN :mmIdSet ');
            if(wheresDPT.size() > 0){
                querymmPMI.add('AND ' + String.join(wheresDPT, ' AND ') );
            }
            querymmPMI.add(' ORDER BY ProductMaster_Integration__r.ProductClassificationCode3__c,ProductMaster_Integration__r.RepresentativeJanCode__c');
            soql = String.join(querymmPMI, ' ');
            List<PLN_MM_ProductMaster__c> mmPMIList = Database.query(soql);
            For(PLN_MM_ProductMaster__c mmPMI : mmPMIList){
                mmPMIMap.put(mmPMI.MixMatch__c,mmPMI);
            }
            //End for PLN_MM_ProductMaster__c 
            For(MMDataSet mmData : mixToWrapperMap.values()){
                If(mmPMIMap.containsKey(mmData.mmID)){
                    mmData.productJan = mmPMIMap.get(mmData.mmID).ProductMaster_Integration__r.RepresentativeJanCode__c;
                    mmData.DPT = mmPMIMap.get(mmData.mmID).ProductMaster_Integration__r.ProductClassificationCode3__c;
                    mmData.productName = mmPMIMap.get(mmData.mmID).ProductName__c;
                    mixToWrapperMapInter.put(mmData.mmDetailID,mmData );               
                }
            }

            List<MMDataSet> dataList = new List<MMDataSet>(mixToWrapperMapInter.values());
            dataList.sort();
            return dataList;
            //return mixToWrapperMapInter.values();
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }  

/**
* Method to get LinkHistory from DB
* @return List<LinkHistoryCoulumns >
*/  
    @AuraEnabled(cacheable=true)
    public static  List<LinkHistoryCoulumns > getsLinkHistory() {
        
        List<LinkHistoryCoulumns> LinkHistoryCoulumnsFeildsList = new List<LinkHistoryCoulumns>();
        for(PLN_LinkHistory__c LinkHistory_OBJ:[SELECT Id, Name,CreatedBy.name,PLN_PlanningPreparationId__r.name,mmCodes__c, funcCd__c, processType__c, Enddatetime__c, Spendtime__c,LastModifiedDate , Result__c FROM PLN_LinkHistory__c where funcCd__c in ('CK010A0111_B01_UPDATE','CK010A0112_B01_UPDATE','CK010A0113_B01_UPDATE','CK010A0114_B01_UPDATE','CK010A0114_B01_DELETE','CK010A0119_B01_CHECKTEKIYOKIKAN') order by name DESC NULLS LAST]){
            
            LinkHistoryCoulumnsFeildsList.add(new LinkHistoryCoulumns(LinkHistory_OBJ) );
        }
        return LinkHistoryCoulumnsFeildsList;
    }
    
    //Wrapper class for PLN Link History    
    public class LinkHistoryCoulumns{
        
        @AuraEnabled
        public PLN_LinkHistory__c LinkHistoryObj;
        @AuraEnabled
        public string LinkHistory_Name;
        @AuraEnabled
        public string LinkHistory_Id;
        @AuraEnabled
        public string LinkHistory_URL;
        @AuraEnabled
        public string LinkHistory_PlanningPreparation_Name;
        @AuraEnabled
        public string LinkHistory_mmCode;
        @AuraEnabled
        public string LinkHistory_funcCd;
        @AuraEnabled
        public string LinkHistory_processType;
        @AuraEnabled
        public string LinkHistory_Result;
        @AuraEnabled
        public Decimal LinkHistory_Spendtime;
        @AuraEnabled
        public Datetime LinkHistory_Enddatetime;
        @AuraEnabled
        public string LinkHistory_CreatedBy_name;
        @AuraEnabled
        public string LinkHistory_LastModifiedDate;
        
        public LinkHistoryCoulumns(PLN_LinkHistory__c LinkHistoryObj){
            
            this.LinkHistoryObj = LinkHistoryObj;
            this.LinkHistory_Name=LinkHistoryObj.Name;
            this.LinkHistory_Id = LinkHistoryObj.id;
            this.LinkHistory_URL= URL.getSalesforceBaseUrl().toExternalForm()+ '/' + LinkHistory_Id;
            this.LinkHistory_PlanningPreparation_Name=LinkHistoryObj.PLN_PlanningPreparationId__r.name;
            this.LinkHistory_mmCode=LinkHistoryObj.mmCodes__c;
            this.LinkHistory_funcCd=LinkHistoryObj.funcCd__c;
            this.LinkHistory_processType=LinkHistoryObj.processType__c;
            this.LinkHistory_Result=LinkHistoryObj.Result__c;
            this.LinkHistory_Spendtime=LinkHistoryObj.Spendtime__c;
            this.LinkHistory_Enddatetime=LinkHistoryObj.Enddatetime__c;
            this.LinkHistory_CreatedBy_name=LinkHistoryObj.CreatedBy.name;
            this.LinkHistory_LastModifiedDate = LinkHistoryObj.LastModifiedDate.format('yyyy/MM/dd HH:mm:ss');
        }
    }
    
    /** TS2-8702
    *Method to return boolean for custom metadata
    */
    @AuraEnabled(cacheable=true)
    public static Boolean getSystemSetting(){  
            String profileId = UserInfo.getProfileId();
            Profile profile = [SELECT Id, Name FROM Profile WHERE Id =: profileId LIMIT 1].get(0); 

        If(FeatureManagement.checkPermission('PLN_SbuInput') || FeatureManagement.checkPermission('PLN_MarketingInput')){
            List<PLN_SystemSetting__mdt> mdtNew = [select id,publish_setting__c from PLN_SystemSetting__mdt limit 1];
            If(mdtNew.size()>0 && mdtNew[0].publish_setting__c=='Public'){
                return true;
            }else If(mdtNew.size()>0 && mdtNew[0].publish_setting__c=='Private'){
                return false;
            } 
        }else if(profile.Name == 'システム開発者' || profile.Name == 'システム管理者' || profile.Name == 'System Administrator'){
            return true;
        }
        
        return false;
    }
    
      /**
     * Return custom setting info 
     */
    @AuraEnabled(cacheable=true) 
    public static PLN_CommonSetting__c getCustomSettings(){
        return PLN_CommonSetting__c.getOrgDefaults();
    }
}