public with sharing class CaseController {
    public class Filters {
    }

    @AuraEnabled(Cacheable=true)
    public static List<Case__c> getCases(Filters filters) {
        return [
            SELECT
                Id,
                Name,
                Description__c
            FROM
                Case__c
        ];
    }
}