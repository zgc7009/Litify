import { LightningElement, api, track, wire } from 'lwc';

import './caseListItem.css';

import { refreshApex } from '@salesforce/apex';

import addShareRecord from '@salesforce/apex/CaseListController.addShareRecord';
import getCaseEntities from '@salesforce/apex/CaseListController.getCaseEntities';

/**
 * Container component that loads the Users with share records
 * for the specific case
 */
export default class CaseListItem extends LightningElement {
    @api litCase;
    
    @track errorMessage;
    @track expanded = false;
    @track queryTerm;

    @wire(getCaseEntities, { caseId: '$litCase.Id' })
    caseEntities;

    @api
    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            this.submitAddEntity();
        } else {
            this.queryTerm = evt.target.value;
        }
    }

    @api
    toggleExpansion() {
        this.expanded = !this.expanded;
    }

    @api
    propogateRemoveConfirmation(detail) {
        const confirmationRequest = new CustomEvent("drop", {
            detail: {
                case: this.litCase.Id,
                entity: detail.entityId
            }
        });

        this.dispatchEvent(confirmationRequest);
    }

    @api
    submitAddEntity() {
        this.addEntity(this.queryTerm);
    }

    addEntity(entityId) {
        if (!this.isValidId(entityId)) {
            this.errorMessage = 'Invalid entity Id: ' + entityId;
            return;
        }

        const that = this;
        addShareRecord({
            recordId: this.litCase.Id,
            userOrGroupIdString: entityId
        }).then(
            function(response) {
                if(response === true) {
                    refreshApex(that.caseEntities);
                } else {
                    this.errorMessage = 'Not shared: ' + response;
                }
            }
        ).catch(e => {
            console.error(e);
        });
    }

    isValidId(idValue) {
        return idValue && (idValue.length === 15 || idValue.length === 18);
    }
}