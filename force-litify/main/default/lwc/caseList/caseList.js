import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

/** getCases() method in CaseController Apex class */
import getCases from '@salesforce/apex/CaseController.getCases';

/**
 * Container component that loads and displays a list of Case__c records.
 */
export default class CaseList extends LightningElement {
    /** JSON.stringified version of filters to pass to apex */
    // Currently unused
    @track filters = {};

    @wire(CurrentPageReference) pageRef;

    /**
     * Load the list of available Cases.
     */
    @wire(getCases, { filters: '$filters' })
    cases;
}
    
