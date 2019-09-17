import { LightningElement, api, track, wire } from 'lwc';

/** getCases() method in CaseController Apex class */
import getCaseEntities from '@salesforce/apex/CaseListController.getCaseEntities';

/**
 * Container component that loads the Users with share records
 * for the specific case
 */
export default class CaseListItem extends LightningElement {
    @api litCase;

    @track expanded = false;

    @wire(getCaseEntities, { caseId: '$litCase.Id' })
    caseEntities;

    @api
    toggleExpansion() {
        this.expanded = !this.expanded;
    }
}
    
