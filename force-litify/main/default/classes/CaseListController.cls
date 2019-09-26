public with sharing class CaseListController {
    /**
     * Add a share record that will allow the User or Group with the corresponding 
     * entity Id to access the Case record. Through role hierarchy, anyone will also be
     * able to access Case records that are shared with subordinates.
     * @param caseId Id of the Case to share
     * @param entityIdString Id of the User or Group to share the Case with
     * @return true if successful in adding the share record, false otherewise
     */
    @AuraEnabled(Cacheable=false)
    public static Boolean addShareRecord(Id caseId, String entityIdString) {
        if (caseId == null || caseId.getSobjectType() != Case__c.getSObjectType()) {
            throw new AuraHandledException('Invalid share case Id: ' + caseId);
        }

        Id entityId;
        try {
            entityId = Id.valueOf(entityIdString);
        } catch (Exception ex) {
            throw new AuraHandledException('Invalid share entity Id: ' + entityId);
        }

        if (!isUser(entityId) && !isGroup(entityId)) {
            throw new AuraHandledException('Inavlid share Id: ' + entityId);
        }
        
        Case__share caseShare = new Case__share(
            ParentId = caseId,
            UserOrGroupId = entityId,
            AccessLevel = 'Read',
            RowCause = Schema.Case__Share.RowCause.Manual
        );

        Database.SaveResult sr = executeInsert(caseShare);

        if (sr.isSuccess()) {
            return true;
        } else {
            Database.Error err = sr.getErrors()[0];
            
            // Check if the error is related to trival access level.
            // Access level must be more permissive than the object's default.
            // These sharing records are not required and thus an insert exception is acceptable. 
            if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                    err.getMessage().contains('AccessLevel')){
                return true;
            }
            
            throwDatabaseErrors(sr.getErrors());
        }

        return true;
    }

    /**
     * Drop the share record that allows a User or Group to access a given 
     * Case record. Because of the way role hierarchy works in Salesforce,
     * this also has the potential to remove sharing access for roles higher
     * in the hierarchy if they don't have another share record granting
     * them access.
     * @param caseId Id of the Case to remove sharing access to
     * @param entityId Id of the User or Group to remove access from
     * @return true of successful in dropping the share record, false otherwise
     */
    @AuraEnabled(Cacheable=false)
    public static Boolean dropShareRecord(Id caseId, Id entityId) {
        List<Case__share> shareRecords = [
            SELECT
                Id
            FROM
                Case__share
            WHERE
                ParentId = :caseId
            AND
                UserOrGroupId = :entityId
        ];

        if (shareRecords.isEmpty()) {
            throw new AuraHandledException('Invalid parameters: ' + caseId + ' || ' + entityId);
        }

        executeDelete(shareRecords);

        return true;
    }

    /**
     * Get all Case records available through record ownership or share records.
     * @return List of Case__c records available for the User in context
     */
    @AuraEnabled(Cacheable=true)
    public static List<Case__c> getCases() {
        return [
            SELECT
                Id,
                Name,
                Description__c
            FROM
                Case__c
        ];
    }

    /**
     * Get Users with explicit access to a particular case. The accesss
     * can come from record ownership or a share record. It does not include
     * Users that are granted access implicitly through role hierarchys.
     * @param caseId Id of the Case to get Users with record access for
     * @return List of Users with explicit access to the Case record
     */
    @AuraEnabled(Cacheable=true)
    public static List<User> getCaseEntities(Id caseId) {
        List<Case__share> shareRecords = getShareRecords(caseId);

        if (shareRecords.isEmpty()) {
            return new List<User>();
        }

        return getUsersFromShareRecords(shareRecords);
    }

    /**
     * Get the record owner of a particular Case. This is important to keep us from
     * potentially removing access for a user that owns the record.
     * @param caseId Id of the Case to get the owner for
     * @return Id of the owner for the record
     */
    @AuraEnabled(Cacheable=true)
    public static Id getCaseOwner(Id caseId) {
        return [
            SELECT
                OwnerId
            FROM
                Case__c
            WHERE
                Id = :caseId
        ].OwnerId;
    }

    /**
     * A recursive method that will break down group records and ensure we have
     * a proper set of User Ids to work with instead of a combination of both
     * User and Group. Only exposing a Group and not the Users in it could 
     * potentially mask a large subset of unknown Users with access to a record.
     * @param groupIds A set of Group Ids to be recursed through to expose User records
     * @param userIds A set of User Ids that will be appended to
     * @return Final set of all User Ids in the Groups
     */
    @TestVisible
    private static Set<Id> addUsersFromGroups(Set<Id> groupIds, Set<Id> userIds) {
        List<GroupMember> groupMembers = [
            SELECT
                UserOrGroupId
            FROM
                GroupMember
            WHERE
                GroupId IN :groupIds
        ];

        Set<Id> childGroupIds = new Set<Id>();
        for (GroupMember gm : groupMembers) {
            if (gm.UserOrGroupId.getSObjectType() == User.getSObjectType()) {
                userIds.add(gm.UserOrGroupId);
            } else {
                childGroupIds.add(gm.UserOrGroupId);
            }
        }

        if (childGroupIds.isEmpty()) {
            return userIds;
        }

        return addUsersFromGroups(childGroupIds, userIds);
    }

    /**
     * Execute delete DML with error handling
     * @param records SObject records to delete
     */
    private static void executeDelete(List<SObject> records) {
        try {
            delete records;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * Execute insert DML with error handling
     * @param record SObject record to insert
     */
    private static Database.SaveResult executeInsert(SObject record) {
        try {
            return Database.insert(record, false);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * Get all share records associated with a particular Case.
     * @param caseId Id of the case to get share records for
     * @return List of share records for the Case
     */
    private static List<Case__share> getShareRecords(Id caseId) {
        return [
            SELECT
                Id,
                UserOrGroupId
            FROM
                Case__share
            WHERE
                ParentId = :caseId
        ];
    }

    /**
     * Get the Users associated with share records.
     * @param shareRecords Share records to pull Users for
     * @return List of Users associated with the given share records
     */
    @TestVisible
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
            userIds = addUsersFromGroups(groupIds, userIds);
        }

        return [
            SELECT
                Id,
                FirstName,
                LastName,
                Email
            FROM
                User
            WHERE
                Id IN :userIds
        ];
    }

    private static Boolean isGroup(Id entityId) {
        return entityId.getSObjectType() == Group.getSObjectType();
    }

    private static Boolean isUser(Id entityId) {
        return entityId.getSObjectType() == User.getSObjectType();
    }

    /**
     * Print a prettier version of DML errors to make debugging easier.
     * @param errors List of errors returned from the DML call
     */
    private static void throwDatabaseErrors(List<Database.Error> errors) {
        String errorString = '';

        for (Database.Error error : errors) {
            errorString += error.getMessage() + '\n';
        }

        throw new AuraHandledException(errorString);
    }
}