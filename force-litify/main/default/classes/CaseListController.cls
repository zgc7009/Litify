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
            throw new AuraHandledException('Unable to share for: ' + entityId);
        }
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
    public static List<AEntity> getCaseEntities(Id caseId) {
        List<Case__share> shareRecords = getShareRecords(caseId);

        if (shareRecords.isEmpty()) {
            return new List<AEntity>();
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
     * Get the User records and required display fields given a set of Ids
     * @param userIds Set of User Ids to pull records for
     * @return List of User records associated with the Ids
     */
    public static List<User> getUsersFromIds(Set<Id> userIds) {
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
     * Get the parent Groups that has share records explicitly
     * associated with them that will act as the root for the Entity
     * along with required display fields on the records.
     * @param groupIds Set of Grouop Ids to pull records for
     * @return List of Groups associated with the Group Ids
     */
    private static List<Group> getParentGroups(Set<Id> groupIds) {
        return [
            SELECT
                Id,
                Name
            FROM
                Group
            WHERE
                Id IN :groupIds
        ];
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
    private static List<AEntity> getUsersFromShareRecords(List<Case__share> shareRecords) {
        Set<Id> userIds = new Set<Id>();
        Set<Id> groupIds = new Set<Id>();
        for (Case__share shareRecord : shareRecords) {
            if (isUser(shareRecord.UserOrGroupId)) {
                userIds.add(shareRecord.UserOrGroupId);
            } else if (isGroup(shareRecord.UserOrGroupId)) {
                groupIds.add(shareRecord.UserOrGroupId);
            } else {
                throw new AuraHandledException('Inavlid UserOrGroupId on share record: ' + shareRecord);
            }
        }

        List<User> users = getUsersFromIds(userIds);
        List<UserEntity> userEntities = new List<UserEntity>();
        for (User u : users) {
            userEntities.add(new UserEntity(u));
        }

        List<Group> groups = getParentGroups(groupIds);
        List<GroupEntity> groupEntities = new List<GroupEntity>();
        for (Group g : groups) {
            groupEntities.add(new GroupEntity(g));
        }

        List<AEntity> allEntities = new List<AEntity>();
        allEntities.addAll(userEntities);
        allEntities.addAll(groupEntities);
        return allEntities;
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