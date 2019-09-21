import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import { registerListener } from 'c/pubsub';
import { unregisterListener } from 'c/pubsub';

import './caseListItem.css';

import addShareRecord from '@salesforce/apex/CaseListController.addShareRecord';
import getCaseEntities from '@salesforce/apex/CaseListController.getCaseEntities';
import getCaseOwner from '@salesforce/apex/CaseListController.getCaseOwner';

/**
 * Container component that loads the Users with share records
 * for the specific case
 */
export default class CaseListItem extends LightningElement {
    @api litCase;
    
    @track addErrorMessage;
    @track addSuccessMessage;
    @track deleteErrorMessage;
    @track deleteSuccessMessage;
    @track expanded = false;
    @track queryTerm;

    @wire(getCaseEntities, { caseId: '$litCase.Id' })
    caseEntities;

    @wire(getCaseOwner, { caseId: '$litCase.Id' })
    caseOwner;

    @wire(CurrentPageReference) pageRef;

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
    pushRemoveConfirmation(event) {
        this.resetMessages();

        if (this.compareEntities(this.caseOwner.data, event.detail.entity)) {
            this.deleteErrorMessage = 'This is the case owner. Unable to delete them from the case';
            return;
        }

        registerListener('shareDropSuccess', this.deleteSuccess, this);
        registerListener('shareDropFailure', this.deleteFailure, this);

        const confirmationRequest = new CustomEvent("drop", {
            detail: {
                case: this.litCase.Id,
                entity: event.detail.entity
            }
        });

        this.dispatchEvent(confirmationRequest);
    }

    @api
    submitAddEntity() {
        this.addEntity(this.queryTerm);
    }

    addEntity(entityId) {
        this.resetMessages();

        if (!this.isValidId(entityId)) {
            this.addErrorMessage = 'Invalid entity Id: ' + entityId;
            return;
        }

        if (this.checkForDuplicateEntity(entityId)) {
            this.addErrorMessage = 'Entity already involved: ' + entityId;
            return;
        }

        const that = this;
        addShareRecord({
            recordId: this.litCase.Id,
            userOrGroupIdString: entityId
        }).then(
            function(response) {
                if(response === true) {
                    that.addSuccessMessage = 'Success! Added Entity ' + entityId;
                    refreshApex(that.caseEntities);
                } else {
                    that.addErrorMessage = 'Not shared: ' + response;
                }
            }
        ).catch(e => {
            console.error(e);
        });
    }

    checkForDuplicateEntity(entityId) {
        var shortEntityId = entityId.substring(0, 15);
        var duplicate = false;

        this.caseEntities.data.forEach(function(entity) {
            if (entity.Id.substring(0, 15) === shortEntityId) {
                duplicate = true;
            }
        });
        
        return duplicate;
    }

    compareEntities(entityId1, entityId2) {
        if (entityId1.length < 15 || entityId2.length < 15) {
            return entityId1 === entityId2;
        }

        return entityId1.substring(0, 15) === entityId2.substring(0, 15);
    }

    deleteFailure() {
        this.deleteErrorMessage = 'Unable to remove entity from case ' + this.litCase.Id;
    }

    deleteSuccess() {
        this.deleteSuccessMessage = 'Success! Entity no longer able to view case';
        refreshApex(this.caseEntities);
    }

    isValidId(idValue) {
        return idValue && (idValue.length === 15 || idValue.length === 18);
    }

    resetMessages() {
        this.addErrorMessage = null;
        this.addSuccessMessage = null;
        this.deleteErrorMessage = null;
        this.deleteSuccessMessage = null;
    }

    unregisterListeners() {
        unregisterListener('shareDropSuccess', this.deleteSuccess, this);
        unregisterListener('shareDropFailure', this.deleteFailure, this);
    }
}