import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import { fireEvent } from 'c/pubsub';
import { registerListener } from 'c/pubsub';
import { unregisterListener } from 'c/pubsub';

import getCases from '@salesforce/apex/CaseListController.getCases';
import dropShareRecord from '@salesforce/apex/CaseListController.dropShareRecord';

/**
 * Container component that loads and displays a list of Case__c records as well
 * as serving as a root for action confirmation.
 */
export default class CaseList extends LightningElement {
    @track confirmationModal = false;
    @track modalKey = "confirmation-modal";
    @track contextCaseId;
    @track contextEntityId;

    @wire(CurrentPageReference) pageRef;

    @wire(getCases, {})
    cases

    connectedCallback() {
        // Register removal listeners that will handle confirmation responses
        // when request is made to remove an entity
        registerListener('cancelRemoval', this.cancelEntityRemoval, this);
        registerListener('confirmRemoval', this.confirmEntityRemoval, this);
    }

    disconnectedCallback() {
        // When disconnected from the DOM, unregister the listeners
        unregisterListener('cancelRemoval', this.cancelEntityRemoval, this);
        unregisterListener('confirmRemoval', this.confirmEntityRemoval, this);
    }

    // Will cancel the request to remove an entitiy, closing the confirmation modal
    @api
    cancelEntityRemoval() {
        this.confirmationModal = false;
    }

    // Will confirm the request to remove an entity
    @api
    confirmEntityRemoval() {
        const that = this;

        // Make the request to Apex to drop the share record
        dropShareRecord({
            caseId: this.contextCaseId,
            entityId: this.contextEntityId
        }).then(
            function(response) {
                // Pass the results down to the caseListItem component for visual reporting
                if(response === true) {
                    fireEvent(that.pageRef, 'shareDropSuccess');
                } else {
                    fireEvent(that.pageRef, 'shareDropFailure');
                }

                that.confirmationModal = !response;
            }
        ).catch(e => {
            // Log the exception and pass the failure down to the caseListItem component for visual reporting
            console.error(e);
            fireEvent(that.pageRef, 'shareDropFailure');
        });
    }

    @api
    promptEntityRemoval(event) {
        // Store the Case and Entity that the request to remove is happening for
        this.contextCaseId = event.detail.case;
        this.contextEntityId = event.detail.entity;
        // Display the modal for confirmation
        this.confirmationModal = true;
    }
}