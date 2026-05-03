public with sharing class MarketAlertService {

    @InvocableMethod(
        label       = 'Get Active Market Alerts'
        description = 'Retrieves active NSE/BSE market alerts from the last 2 hours'
    )
    public static List<AlertResult> getActiveAlerts(List<String> inputs) {
        List<AlertResult> results = new List<AlertResult>();

        List<Market_Alert__c> alerts = [
            SELECT  Id,
                    Index_Name__c,
                    Change_Pct__c,
                    Severity__c,
                    Affected_Sector__c,
                    Event_Time__c,
                    Impacted_Client_Count__c
            FROM    Market_Alert__c
            WHERE   Is_Active__c = TRUE
              AND   Event_Time__c >= :DateTime.now().addHours(-2)
            ORDER BY Event_Time__c DESC
            LIMIT   5
        ];

        AlertResult r = new AlertResult();
        if (alerts.isEmpty()) {
            r.summary    = 'No active market alerts in the last 2 hours.';
            r.alertCount = 0;
        } else {
            Market_Alert__c latest = alerts[0];
            r.summary = latest.Index_Name__c
                      + ' moved ' + latest.Change_Pct__c
                      + '% at '
                      + latest.Event_Time__c.format('HH:mm', 'Asia/Kolkata')
                      + ' IST. Severity: ' + latest.Severity__c
                      + '. Impacted clients: '
                      + (Integer) latest.Impacted_Client_Count__c;
            r.alertCount     = alerts.size();
            r.severity       = latest.Severity__c;
            r.indexName      = latest.Index_Name__c;
            r.changePct      = latest.Change_Pct__c;
            r.affectedSector = latest.Affected_Sector__c;
            r.impactedCount  = (Integer) latest.Impacted_Client_Count__c;
        }
        results.add(r);
        return results;
    }

    @AuraEnabled(cacheable=false)
    public static Integer getImpactedClientCount() {
        return [
            SELECT COUNT()
            FROM   Contact
            WHERE  Agentforce_Segment__c = 'NIFTY_IT_Impacted_Clients'
              AND  OwnerId = :UserInfo.getUserId()
        ];
    }

    @AuraEnabled(cacheable=false)
    public static List<Market_Alert__c> getActiveAlertsForLWC() {
        return [
            SELECT  Id,
                    Index_Name__c,
                    Change_Pct__c,
                    Severity__c,
                    Event_Time__c,
                    Impacted_Client_Count__c
            FROM    Market_Alert__c
            WHERE   Is_Active__c = TRUE
              AND   Event_Time__c >= :DateTime.now().addHours(-2)
            ORDER BY Event_Time__c DESC
            LIMIT   1
        ];
    }

    public class AlertResult {
        @InvocableVariable(label='Summary' required=true)
        public String  summary;
        @InvocableVariable(label='Alert Count')
        public Integer alertCount;
        @InvocableVariable(label='Severity')
        public String  severity;
        @InvocableVariable(label='Index Name')
        public String  indexName;
        @InvocableVariable(label='Change Percent')
        public Decimal changePct;
        @InvocableVariable(label='Affected Sector')
        public String  affectedSector;
        @InvocableVariable(label='Impacted Client Count')
        public Integer impactedCount;
    }
}
