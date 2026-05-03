// marketAlertBanner.js
// Part 7 — Market Alert Banner LWC controller
// Wires to MarketAlertService Apex. Auto-refreshes every 5 minutes.
import { LightningElement, wire, track } from 'lwc';
import { refreshApex }                   from '@salesforce/apex';
import { NavigationMixin }               from 'lightning/navigation';
import { ShowToastEvent }                from 'lightning/platformShowToastEvent';
import getActiveAlertsForLWC             from '@salesforce/apex/MarketAlertService.getActiveAlertsForLWC';
import getImpactedClientCount            from '@salesforce/apex/MarketAlertService.getImpactedClientCount';

export default class MarketAlertBanner extends NavigationMixin(LightningElement) {

    // ── STATE ──────────────────────────────────────────────────────────────

    @track alert         = null;
    @track impactedCount = 0;
    @track hasAlert      = false;
    @track hasError      = false;

    _wiredAlerts;           // store for refreshApex
    _refreshTimer;

    // ── WIRE ───────────────────────────────────────────────────────────────

    @wire(getActiveAlertsForLWC)
    wiredAlertHandler(result) {
        this._wiredAlerts = result;
        const { data, error } = result;

        if (data) {
            this.hasError = false;
            if (data.length > 0) {
                this.alert    = data[0];
                this.hasAlert = true;
            } else {
                this.alert    = null;
                this.hasAlert = false;
            }
        } else if (error) {
            this.hasError = true;
            console.error('marketAlertBanner — getActiveAlertsForLWC error:', error);
        }
    }

    @wire(getImpactedClientCount)
    wiredCount({ data }) {
        if (data !== undefined) this.impactedCount = data;
    }

    // ── LIFECYCLE ──────────────────────────────────────────────────────────

    connectedCallback() {
        // Refresh every 5 minutes
        this._refreshTimer = setInterval(() => {
            refreshApex(this._wiredAlerts);
        }, 300_000);
    }

    disconnectedCallback() {
        clearInterval(this._refreshTimer);
    }

    // ── GETTERS ────────────────────────────────────────────────────────────

    get formattedTime() {
        if (!this.alert?.Event_Time__c) return '';
        try {
            return new Date(this.alert.Event_Time__c)
                .toLocaleTimeString('en-IN', {
                    hour:   '2-digit',
                    minute: '2-digit',
                    timeZone: 'Asia/Kolkata'
                });
        } catch {
            return '';
        }
    }

    // ── HANDLERS ───────────────────────────────────────────────────────────

    handleViewClients() {
        this[NavigationMixin.Navigate]({
            type:       'standard__navItemPage',
            attributes: { apiName: 'Impacted_Clients' }
        });
    }

    handleOpenAgent() {
        // Navigate to Agentforce chat panel
        // In FSC the Agentforce icon is in the utility bar — fire a custom event
        // that the parent app page can listen to in order to open the panel
        const event = new CustomEvent('openagent', {
            detail: {
                defaultMessage: `Who is impacted by today's ${this.alert?.Index_Name__c} alert?`
            },
            bubbles:  true,
            composed: true
        });
        this.dispatchEvent(event);

        // Also show a toast so Vikram knows what to do
        this.dispatchEvent(new ShowToastEvent({
            title:   'Agentforce',
            message: 'Open the Agentforce panel from the utility bar and ask: "Who is impacted today?"',
            variant: 'info',
            mode:    'dismissable'
        }));
    }
}
