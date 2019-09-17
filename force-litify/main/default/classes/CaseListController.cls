public with sharing class CaseListController {
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

    @AuraEnabled(Cacheable=true)
    public static List<Case__share> getCaseEntities(Id caseId) {
        return [
            SELECT
                Id,
                UserOrGroupId
            FROM
                Case__share
            WHERE
                ParentId = :caseId
            AND
                UserOrGroupId != :UserInfo.getUserId()
        ];
    }
}