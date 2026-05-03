// preCallBrief.js
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord }         from 'lightning/uiRecordApi';
import getGoals              from '@salesforce/apex/PreCallBriefService.getGoalsForContact';
import generateTalkingPoints from '@salesforce/apex/PreCallBriefService.generateAITalkingPoints';

const FIELDS = [
    'Contact.FirstName',
    'Contact.LastName',
    'Contact.Total_AUM__c',
    'Contact.IT_Sector_Exposure_Pct__c',
    'Contact.Risk_Profile__c',
    'Contact.Impact_Severity__c',
    'Contact.Last_Advisory_Sent__c',
    'Contact.Preferred_Channel__c',
];

export default class PreCallBrief extends LightningElement {

    @api recordId;

    @track contact         = {};
    @track goals           = [];
    @track aiTalkingPoints = '';
    @track isLoading       = true;

    // ── WIRE ───────────────────────────────────────────────────────────────

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredContact({ data, error }) {
        if (data) {
            const f = data.fields;
            this.contact = {
                FirstName:                 f.FirstName.value,
                LastName:                  f.LastName.value,
                Total_AUM__c:              f.Total_AUM__c.value,
                IT_Sector_Exposure_Pct__c: f.IT_Sector_Exposure_Pct__c.value,
                Risk_Profile__c:           f.Risk_Profile__c.value,
                Impact_Severity__c:        f.Impact_Severity__c.value,
                Last_Advisory_Sent__c:     f.Last_Advisory_Sent__c.value,
                Preferred_Channel__c:      f.Preferred_Channel__c.value,
            };
            this.loadAdditionalData();
        } else if (error) {
            console.error('preCallBrief wiredContact error:', error);
            this.isLoading = false;
        }
    }

    // ── DATA LOADING ───────────────────────────────────────────────────────

    async loadAdditionalData() {
        try {
            const [goalsData, talkingPts] = await Promise.all([
                getGoals({ contactId: this.recordId }),
                generateTalkingPoints({ contactId: this.recordId }),
            ]);
            this.goals           = goalsData  || [];
            this.aiTalkingPoints = talkingPts || 'Unable to generate talking points.';
        } catch (err) {
            console.error('preCallBrief loadAdditionalData error:', err);
            this.aiTalkingPoints = '• Review client portfolio allocation\n• Discuss IT sector impact\n• Align on financial goals';
        } finally {
            this.isLoading = false;
        }
    }

    // ── GETTERS ────────────────────────────────────────────────────────────

    get exposureStyle() {
        const pct = this.contact.IT_Sector_Exposure_Pct__c || 0;
        const color = pct >= 40 ? '#DC2626' : pct >= 20 ? '#D97706' : '#16A34A';
        return `color:${color};font-weight:700`;
    }

    get impactStyle() {
        const sev   = this.contact.Impact_Severity__c || '';
        const color = sev === 'High' ? '#DC2626' : sev === 'Medium' ? '#D97706' : '#16A34A';
        return `color:${color};font-weight:700`;
    }

    get hasGoals() {
        return this.goals && this.goals.length > 0;
    }
}
