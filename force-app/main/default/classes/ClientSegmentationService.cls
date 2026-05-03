public with sharing class ClientSegmentationService {

    @InvocableMethod(
        label       = 'Get Impacted Clients'
        description = 'Returns list of clients impacted by market alert, filtered by severity'
    )
    public static List<SegmentResult> getImpactedClients(List<String> severityFilter) {
        List<SegmentResult> results = new List<SegmentResult>();
        String sev = (severityFilter == null || severityFilter.isEmpty())
                     ? 'All' : severityFilter[0];
        Id currentUserId = UserInfo.getUserId();

        String soql = 'SELECT Id, FirstName, LastName, Email, MobilePhone,'
                    + ' Preferred_Channel__c, IT_Sector_Exposure_Pct__c,'
                    + ' Total_AUM__c, Risk_Profile__c, Impact_Severity__c,'
                    + ' WhatsApp_OptIn__c, Last_Advisory_Sent__c'
                    + ' FROM Contact'
                    + ' WHERE Agentforce_Segment__c = \'NIFTY_IT_Impacted_Clients\''
                    + ' AND OwnerId = :currentUserId';

        if (!sev.equalsIgnoreCase('All')) {
            soql += ' AND Impact_Severity__c = \''
                  + String.escapeSingleQuotes(sev) + '\'';
        }
        soql += ' ORDER BY Total_AUM__c DESC LIMIT 500';

        List<Contact> clients = Database.query(soql);

        SegmentResult r = new SegmentResult();
        r.totalCount = clients.size();
        r.highCount = 0; r.medCount = 0; r.lowCount = 0;
        r.clientJSON = JSON.serialize(clients);

        for (Contact c : clients) {
            if      (c.Impact_Severity__c == 'High')   r.highCount++;
            else if (c.Impact_Severity__c == 'Medium') r.medCount++;
            else                                        r.lowCount++;
        }
        r.summary = 'Total impacted: ' + r.totalCount
                  + ' (High: ' + r.highCount
                  + ', Medium: ' + r.medCount
                  + ', Low: ' + r.lowCount + ')';
        results.add(r);
        return results;
    }

    @AuraEnabled(cacheable=false)
    public static List<Contact> getImpactedClientsForLWC(String severity) {
        Id currentUserId = UserInfo.getUserId();
        String soql = 'SELECT Id, FirstName, LastName, MobilePhone, Email,'
                    + ' Preferred_Channel__c, Total_AUM__c,'
                    + ' IT_Sector_Exposure_Pct__c, Impact_Severity__c'
                    + ' FROM Contact'
                    + ' WHERE Agentforce_Segment__c = \'NIFTY_IT_Impacted_Clients\''
                    + ' AND OwnerId = :currentUserId';
        if (String.isNotBlank(severity) && !severity.equalsIgnoreCase('All')) {
            soql += ' AND Impact_Severity__c = \'' + String.escapeSingleQuotes(severity) + '\'';
        }
        soql += ' ORDER BY Total_AUM__c DESC LIMIT 200';
        return Database.query(soql);
    }

    public class SegmentResult {
        @InvocableVariable public Integer totalCount;
        @InvocableVariable public Integer highCount;
        @InvocableVariable public Integer medCount;
        @InvocableVariable public Integer lowCount;
        @InvocableVariable public String  summary;
        @InvocableVariable public String  clientJSON;
    }
}
