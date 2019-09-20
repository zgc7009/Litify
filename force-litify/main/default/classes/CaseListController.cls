public with sharing class CaseListController {
    public class Filters {
    }

    @AuraEnabled(Cacheable=false)
    public static Boolean addShareRecord(Id recordId, String userOrGroupIdString) {
        Id userOrGroupId = Id.valueOf(userOrGroupIdString);
        if (userOrGroupId.getSObjectType() != User.getSObjectType() &&
                userOrGroupId.getSObjectType() != Group.getSObjectType()) {
            throw new AuraHandledException('Inavlid share Id: ' + userOrGroupId);
        }

        Case__share caseShr  = new Case__share();
        caseShr.ParentId = recordId;
        caseShr.UserOrGroupId = userOrGroupId;
        caseShr.AccessLevel = 'Read';
        caseShr.RowCause = Schema.Case__Share.RowCause.Manual;
        Database.SaveResult sr = executeInsert(caseShr);

        if(sr.isSuccess()){
            return true;
        }
        else {
            Database.Error err = sr.getErrors()[0];
            
            // Check if the error is related to trival access level.
            // Access level must be more permissive than the object's default.
            // These sharing records are not required and thus an insert exception is acceptable. 
            if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                    err.getMessage().contains('AccessLevel')){
                return true;
            }
            else{
                return false;
            }
        }
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
            throw new AuraHandledException('Invalid parameters: ' + caseId + ' || ' + entityId);
        }

        executeDelete(shareRecord[0]);

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

    private static void executeDelete(SObject record) {
        try {
            delete record;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static Database.SaveResult executeInsert(SObject record) {
        try {
            return Database.insert(record, false);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}