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
 * Container component that manages all Users with share records for the specific case
 */
export default class CaseListItem extends LightningElement {
    @api litCase;
    @api litCaseId;
    
    // Visual Reporting variables
    @track addErrorMessage;
    @track addSuccessMessage;
    @track deleteErrorMessage;
    @track deleteSuccessMessage;

    // Dynamic UI variables
    @track expanded = false;
    @track queryTerm;

    @wire(getCaseEntities, { caseId: '$litCaseId' })
    caseEntities;

    @wire(getCaseOwner, { caseId: '$litCaseId' })
    caseOwner;

    @wire(CurrentPageReference) pageRef;

    // Handle key up events from the User Id input field
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

    // Push the request to remove up from the caseListEntity component to the parent caseList component
    // for confirmation
    @api
    pushRemoveConfirmation(event) {
        // Clear visual reporting
        this.resetMessages();

        // Ensure the removal request is not for the record owner
        if (this.compareEntities(this.caseOwner.data, event.detail.entity)) {
            this.deleteErrorMessage = 'This is the case owner. Unable to delete them from the case';
            return;
        }

        // Register listeners that will handle the delete confirmation response
        registerListener('shareDropSuccess', this.deleteSuccess, this);
        registerListener('shareDropFailure', this.deleteFailure, this);

        // Build the request details
        const confirmationRequest = new CustomEvent("drop", {
            detail: {
                case: this.litCase.Id,
                entity: event.detail.entity
            }
        });

        // Pass the request up to the parent caseList component
        this.dispatchEvent(confirmationRequest);
    }

    @api
    submitAddEntity() {
        this.addEntity(this.queryTerm);
    }

    // Add a share record for the User or Group passed to the Case in context
    addEntity(entityId) {
        // Clear visual reporting
        this.resetMessages();

        // Quick front-end validation to minimize bad back end calls
        if (!this.isValidId(entityId)) {
            this.addErrorMessage = 'Invalid entity Id: ' + entityId;
            return;
        }

        // Avoid duplication to minimize back end calls
        if (this.checkForDuplicateEntity(entityId)) {
            this.addErrorMessage = 'Entity already involved: ' + entityId;
            return;
        }

        const that = this;

        // Make the request to Apex to add the share record
        addShareRecord({
            caseId: this.litCase.Id,
            entityIdString: entityId
        }).then(
            function(response) {
                // Visual reporting of the results
                if(response === true) {
                    that.addSuccessMessage = 'Success! Added Entity ' + entityId;
                    refreshApex(that.caseEntities);
                } else {
                    that.addErrorMessage = 'Not shared: ' + response;
                }
            }
        ).catch(e => {
            // Log the exception and present an error in visual reporting
            console.error(e);
        });
    }

    // Check to see if the Entity already has a share record for the Case in context
    checkForDuplicateEntity(entityId) {
        var shortEntityId = entityId.substring(0, 15);
        var duplicate = false;

        this.caseEntities.data.forEach(function(entity) {
            if (entity.sId.substring(0, 15) === shortEntityId) {
                duplicate = true;
            }
        });
        
        return duplicate;
    }

    // Check to see if two Entities are the same based on Id
    compareEntities(entityId1, entityId2) {
        if (entityId1.length < 15 || entityId2.length < 15) {
            return entityId1 === entityId2;
        }

        return entityId1.substring(0, 15) === entityId2.substring(0, 15);
    }

    // Present visual reporting when there is an error deleting a share record
    deleteFailure() {
        this.deleteErrorMessage = 'Unable to remove entity from case ' + this.litCase.Id;
    }

    // Present visual reporting when a share record is successfully deleted
    deleteSuccess() {
        this.deleteSuccessMessage = 'Success! Entity no longer able to view case';
        refreshApex(this.caseEntities);
    }

    // Quick front-end check to see if it is even possible for a string to be an Id
    isValidId(idValue) {
        return idValue && (idValue.length === 15 || idValue.length === 18); // idValue.match(/^([a-zA-Z0-9]{15}|[a-zA-Z0-9]{18})$/);
    }

    // Reset visual reporting
    resetMessages() {
        this.addErrorMessage = null;
        this.addSuccessMessage = null;
        this.deleteErrorMessage = null;
        this.deleteSuccessMessage = null;
    }

    // Unregister listeners that are waiting for drop results
    unregisterListeners() {
        unregisterListener('shareDropSuccess', this.deleteSuccess, this);
        unregisterListener('shareDropFailure', this.deleteFailure, this);
    }
}