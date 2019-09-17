import { LightningElement, api, track } from 'lwc';

/**
 * Container component that loads the Users with share records
 * for the specific case
 */
export default class CaseListItem extends LightningElement {
    @track holder = 'Add associated here';
    @api litCase;
}
    
