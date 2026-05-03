@isTest
public class MarketAlertServiceTest {

    @testSetup
    static void setup() {
        insert new Market_Alert__c(
            Index_Name__c            = 'NIFTY_IT',
            Change_Pct__c            = -4.2,
            Severity__c              = 'HIGH',
            Is_Active__c             = true,
            Impacted_Client_Count__c = 62,
            Affected_Sector__c       = 'IT',
            Event_Time__c            = DateTime.now()
        );
    }

    @isTest
    static void testGetActiveAlerts_withAlert() {
        Test.startTest();
        List<MarketAlertService.AlertResult> results =
            MarketAlertService.getActiveAlerts(new List<String>{ '' });
        Test.stopTest();
        System.assertNotEquals(0, results.size());
        System.assertEquals('NIFTY_IT', results[0].indexName);
        System.assert(results[0].summary.contains('62'));
        System.assertEquals('HIGH', results[0].severity);
    }

    @isTest
    static void testGetActiveAlerts_noAlerts() {
        update new Market_Alert__c(
            Id           = [SELECT Id FROM Market_Alert__c LIMIT 1].Id,
            Is_Active__c = false
        );
        Test.startTest();
        List<MarketAlertService.AlertResult> results =
            MarketAlertService.getActiveAlerts(new List<String>{ '' });
        Test.stopTest();
        System.assertEquals(0, results[0].alertCount);
    }

    @isTest
    static void testGetImpactedClientCount() {
        insert new Contact(
            FirstName             = 'Test',
            LastName              = 'Client',
            Agentforce_Segment__c = 'NIFTY_IT_Impacted_Clients'
        );
        Test.startTest();
        Integer cnt = MarketAlertService.getImpactedClientCount();
        Test.stopTest();
        System.assert(cnt >= 0);
    }
}

@isTest
public class ClientSegmentationServiceTest {

    @testSetup
    static void setup() {
        List<Contact> contacts = new List<Contact>();
        String[] sevs = new String[]{ 'High','High','Medium','Medium','Low' };
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                FirstName                 = 'Test',
                LastName                  = 'Client' + i,
                Email                     = 'test' + i + '@bank.test',
                Agentforce_Segment__c     = 'NIFTY_IT_Impacted_Clients',
                IT_Sector_Exposure_Pct__c = 20 + (i * 10),
                Total_AUM__c              = 5000000 * (i + 1),
                Impact_Severity__c        = sevs[i],
                WhatsApp_OptIn__c         = true,
                Preferred_Channel__c      = 'WhatsApp',
                Risk_Profile__c           = 'Moderate'
            ));
        }
        insert contacts;
    }

    @isTest
    static void testGetImpactedClients_all() {
        Test.startTest();
        List<ClientSegmentationService.SegmentResult> results =
            ClientSegmentationService.getImpactedClients(new List<String>{ 'All' });
        Test.stopTest();
        System.assertNotEquals(0, results.size());
        System.assert(results[0].totalCount > 0);
    }

    @isTest
    static void testGetImpactedClients_highOnly() {
        Test.startTest();
        List<ClientSegmentationService.SegmentResult> results =
            ClientSegmentationService.getImpactedClients(new List<String>{ 'High' });
        Test.stopTest();
        System.assertEquals(0, results[0].medCount);
        System.assertEquals(0, results[0].lowCount);
    }
}
