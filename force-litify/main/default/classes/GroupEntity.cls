public class GroupEntity extends AEntity {
    private List<User> groupUsers;

    public GroupEntity(SObject obj) {
        super(obj);
    }

    public virtual override String getLabel(SObject obj) {
        return this.groupUsers == null ? 'Loading...' : this.groupUsers.size() + ' users';
    }

    public virtual override String getTitle(SObject obj) {
        return cast(obj).Name;
    }

    /**
     * More complex with groups than users, will build the User
     * chain from the parent Group and return the full list of Users
     * associated with the Group record
     * @param obj The Group entity record to get Users for
     * @return The full list of associated Users
     */
    public virtual override List<User> getUsers(SObject obj) {
        Set<Id> initialGroupSet = new Set<Id> { cast(obj).Id };
        Set<Id> userIds = buildUsersFromGroups(initialGroupSet, null);
        this.groupUsers = CaseListController.getUsersFromIds(userIds);
        return this.groupUsers;
    }

    public virtual override Boolean isIndividual() {
        return false;
    }

    /**
     * A recursive method that will break down group records and ensure we have
     * a proper set of User Ids to work with instead of a combination of both
     * User and Group. It works both to build a new set of User Ids and to append
     * to an exisint set of User Ids base on needs. Only exposing a Group and not 
     * the Users in it could potentially mask a large subset of unknown Users with 
     * access to a record.
     * @param groupIds A set of Group Ids to be recursed through to expose User records
     * @param userIds A set of User Ids that will be appended to during recursion
     * @return Final set of all User Ids in the Group
     */
    @TestVisible
    private static Set<Id> buildUsersFromGroups(Set<Id> groupIds, Set<Id> userIds) {
        if (userIds == null) {
            userIds = new Set<Id>();
        }

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

        return buildUsersFromGroups(childGroupIds, userIds);
    }

    private Group cast(SObject g) {
        return (Group) g;
    }
}