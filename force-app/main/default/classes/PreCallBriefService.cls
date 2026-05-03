public with sharing class PreCallBriefService {

    @AuraEnabled(cacheable=true)
    public static List<FinancialGoal__c> getGoalsForContact(Id contactId) {
        return [
            SELECT Id, Name, TargetDate__c, TargetValue__c, GoalType__c, Status__c
            FROM   FinancialGoal__c
            WHERE  Contact__c = :contactId
            ORDER BY TargetDate__c ASC
            LIMIT  10
        ];
    }

    @AuraEnabled
    public static String generateAITalkingPoints(Id contactId) {
        Contact c = [
            SELECT FirstName, LastName, Total_AUM__c,
                   IT_Sector_Exposure_Pct__c, Risk_Profile__c,
                   Impact_Severity__c, Last_Advisory_Sent__c,
                   Preferred_Channel__c
            FROM   Contact
            WHERE  Id = :contactId
        ];

        String marketContext = '';
        List<Market_Alert__c> alerts = [
            SELECT Index_Name__c, Change_Pct__c, Severity__c
            FROM   Market_Alert__c
            WHERE  Is_Active__c = TRUE
            ORDER BY Event_Time__c DESC
            LIMIT  1
        ];
        if (!alerts.isEmpty()) {
            marketContext = alerts[0].Index_Name__c
                          + ' ' + alerts[0].Change_Pct__c
                          + '% (' + alerts[0].Severity__c + ')';
        }

        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput input =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            input.promptTemplateDeveloperName = 'PreCall_Talking_Points';
            input.additionalContext = new ConnectApi.EinsteinLlmContext();

            Map<String, ConnectApi.WrappedValue> vals = new Map<String, ConnectApi.WrappedValue>();

            ConnectApi.WrappedValue contactWv = new ConnectApi.WrappedValue();
            contactWv.value = c;
            vals.put('Contact', contactWv);

            ConnectApi.WrappedValue marketWv = new ConnectApi.WrappedValue();
            marketWv.value = marketContext;
            vals.put('MarketContext', marketWv);

            input.additionalContext.values = vals;

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(input);

            return result.generations[0].text;

        } catch (Exception e) {
            return buildFallbackTalkingPoints(c, marketContext);
        }
    }

    private static String buildFallbackTalkingPoints(Contact c, String market) {
        String pts = '';
        if (String.isNotBlank(market)) {
            pts += '• Market update: ' + market + '\n';
        }
        if (c.IT_Sector_Exposure_Pct__c != null && c.IT_Sector_Exposure_Pct__c >= 20) {
            pts += '• IT exposure at ' + c.IT_Sector_Exposure_Pct__c + '% — discuss rebalancing\n';
        }
        if (c.Risk_Profile__c == 'Conservative' && c.Impact_Severity__c == 'High') {
            pts += '• Conservative client with High impact — prioritise reassurance\n';
        }
        pts += '• Review portfolio alignment with financial goals\n';
        pts += '• Offer formal review call within next 5 business days';
        return pts;
    }

    @InvocableMethod(
        label       = 'Get Pre-Call Brief'
        description = 'Returns AI talking points and goals summary for a contact'
    )
    public static List<BriefResult> getPreCallBrief(List<Id> contactIds) {
        List<BriefResult> results = new List<BriefResult>();
        if (contactIds.isEmpty()) return results;

        BriefResult r = new BriefResult();
        r.talkingPoints = generateAITalkingPoints(contactIds[0]);

        List<FinancialGoal__c> goals = getGoalsForContact(contactIds[0]);
        List<String> goalSummaries = new List<String>();
        for (FinancialGoal__c g : goals) {
            goalSummaries.add(g.Name + ' (Target: ' + g.TargetDate__c + ')');
        }
        r.goalsSummary = String.join(goalSummaries, ' | ');

        results.add(r);
        return results;
    }

    public class BriefResult {
        @InvocableVariable(label='AI Talking Points') public String talkingPoints;
        @InvocableVariable(label='Goals Summary')     public String goalsSummary;
    }
}
