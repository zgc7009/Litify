import { LightningElement, track, wire, api } from 'lwc';
import { registerListener } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';

/** TODO add this whenever we get to the point we are refreshing the page */
//import { refreshApex } from '@salesforce/apex';
//Use example: refreshApex(wiredProperty)

/** getCases() method in CaseController Apex class */
import getCases from '@salesforce/apex/CaseListController.getCases';
import dropShareRecord from '@salesforce/apex/CaseListController.dropShareRecord';


/**
 * Container component that loads and displays a list of Case__c records.
 */
export default class CaseList extends LightningElement {
    /** JSON.stringified version of filters to pass to apex */
    // Currently unused
    @track filters = {};
    @track confirmationModal = false;
    @track modalKey = "confirmation-modal";
    @track contextCaseId;
    @track contextEntityId;

    @wire(CurrentPageReference) pageRef;

    /**
     * Load the list of available Cases.
     */
    @wire(getCases, { filters: '$filters' })
    cases;

    connectedCallback() {
        registerListener('cancelRemoval', this.cancelEntityRemoval, this);
        registerListener('confirmRemoval', this.confirmEntityRemoval, this);
    }

    @api
    cancelEntityRemoval() {
        this.confirmationModal = false;
    }

    @api
    confirmEntityRemoval() {
        dropShareRecord(this.contextCaseId, this.contextEntityId).then(
            function(response) {
                this.confirmationModal = !response;
            }
        );
    }

    @api
    promptEntityRemoval(detail) {
        this.contextCaseId = detail.case;
        this.contextEntityId = detail.entity;
        this.confirmationModal = true;
    }
}