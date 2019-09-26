// hello.test.js
import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

import CaseListItem from 'c/caseListItem';

/*
import getCaseEntities from 'c/caseListItem';
const getCaseEntitiesAdapter = registerLdsTestWireAdapter(getCaseEntities);
*/

import getCaseEntities from '@salesforce/apex/CaseListController.getCaseEntities';
const getCaseEntitiesAdapter = registerApexTestWireAdapter(getCaseEntities);

import getCaseOwner from '@salesforce/apex/CaseListController.getCaseOwner';
const getCaseOwnerAdapter = registerApexTestWireAdapter(getCaseOwner);

import { CurrentPageReference } from 'lightning/navigation';
const pageRefAdapter = registerLdsTestWireAdapter(CurrentPageReference);

const mockCaseEntities = require('./data/getCaseEntitiesAdapter.json');

const mockCaseOwner = {
    Id: 'testUser1'
};

describe('c-case-list-item', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('should initialize', () => {
        const element = initializeElement();
        expect(element.litCaseId).toBe('testId');
        expect(element.litCase).toBeTruthy();

        const content = element.shadowRoot.querySelector('lightning-card');
        expect(content).toBeTruthy();
        expect(content.title).toEqual('Your Cases');
        expect(content.textContent).toContain('Test Case');
    });

    it('should get case entities and show view button', () => {
        const element = initializeElement();
        const content = element.shadowRoot.querySelector('lightning-card');

        expect(mockCaseEntities).toBeDefined();
        getCaseEntitiesAdapter.emit(mockCaseEntities);

        // Resolve a promise to wait for a rerender of the new content.
        return Promise.resolve().then(() => {
            var footers = content.querySelectorAll('footer');
            expect(footers.length).toEqual(1);
            const closedButton = footers[0].querySelector('lightning-button');
            expect(closedButton.label).toContain('View All Involved');
        });
    });

    function initializeElement() {
        var litCase = {
            Id: 'testId',
            Name: 'Test Case',
            Description: 'Some test description that is arbitrary'
        };

        // Create element
        const element = createElement('c-case-list-item', {
            is: CaseListItem
        });
        element.key = litCase.Id;
        element.litCase = litCase;
        element.litCaseId = litCase.Id;
        element.expanded = true;
        document.body.appendChild(element);

        expect(element.key).toBeDefined();
        expect(element.litCase).toBeDefined();
        expect(element.litCaseId).toBeDefined();

        return element;
    }
});