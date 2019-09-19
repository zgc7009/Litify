public with sharing class CaseListController {
    public class Filters {
    }

    @AuraEnabled(Cacheable=false)
    public static Boolean dropShareRecord(Id caseId, Id entityId) {
        List<Case__share> shareRecord = [
            SELECT
                Id
            FROM
                Case__share
            WHERE
                ParentId = :caseId
            AND
                UserOrGroupId = :entityId
        ];

        if (shareRecord.isEmpty()) {
            throw new XInvalidParameterException('Invalid parameters: ' + caseId + ' || ' + entityId);
        }

        delete shareRecord[0];

        return true;
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
    public static List<User> getCaseEntities(Id caseId) {
        List<Case__share> shareRecords = [
            SELECT
                Id,
                UserOrGroupId
            FROM
                Case__share
            WHERE
                ParentId = :caseId
        ];

        /* 
        TODO add back
            AND
                UserOrGroupId != :UserInfo.getUserId()
        to remove the current user from the query
        */

        if (shareRecords.isEmpty()) {
            return new List<User>();
        }

        return getUsersFromShareRecords(shareRecords);
    }

    private static List<User> getUsersFromShareRecords(List<Case__share> shareRecords) {
        Set<Id> userIds = new Set<Id>();
        Set<Id> groupIds = new Set<Id>();
        for (Case__share shareRecord : shareRecords) {
            if (shareRecord.UserOrGroupId.getSObjectType() == User.getSObjectType()) {
                userIds.add(shareRecord.UserOrGroupId);
            } else {
                groupIds.add(shareRecord.UserOrGroupId);
            }
        }
        
        if (!groupIds.isEmpty()) {
            addUsersFromGroups(groupIds, userIds);
        }

        return [
            SELECT
                FirstName,
                LastName,
                Email
            FROM
                User
            WHERE
                Id IN :userIds
        ];
    }

    private static void addUsersFromGroups(Set<Id> groupIds, Set<Id> userIds) {
        List<GroupMember> groupMembers = [
            SELECT
                UserOrGroupId
            FROM
                GroupMember
            WHERE
                Id IN :groupIds
        ];

        Set<Id> childGroupIds = new Set<Id>();
        for (GroupMember gm : groupMembers) {
            if (gm.UserOrGroupId.getSObjectType() == User.getSObjectType()) {
                userIds.add(gm.UserOrGroupId);
            } else {
                groupIds.add(gm.UserOrGroupId);
            }
        }

        if (!groupIds.isEmpty()) {
            return;
        }

        addUsersFromGroups(childGroupIds, userIds);
    }

    public class XInvalidParameterException extends Exception{}
}