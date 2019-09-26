@IsTest
public class CaseListControllerTest {
    private static final String TEST_GROUP = 'Test Case Group';
    private static final String TEST_USERNAME_1 = '123@abc-test.com';
    private static final String TEST_USERNAME_2 = 'abc@123-test.com';
    private static final String TEST_USERNAME_3 = 'xyz@098-test.com';
    private static final String TEST_USERNAME_4 = 'zyx@890-test.com';
    private static final String TEST_DESCRIPTION = 'This is a super cool test case';

    @TestSetup
    public static void setupTest(){
        Database.SaveResult sr = Database.insert(new Case__c(
            Description__c = TEST_DESCRIPTION
        ));

        Id testUserId1; 
        System.runAs(new User(Id = UserInfo.getUserId())) {
            testUserId1 = createTestUser(TEST_USERNAME_1, 'Executive');
            createTestUser(TEST_USERNAME_2, 'Manager');
            createTestUser(TEST_USERNAME_3, 'Employee');
            createTestUser(TEST_USERNAME_4, 'Individual');
        }
		
        Case__share caseShr  = new Case__share(
            ParentId = sr.getId(),
            UserOrGroupId = testUserId1,
            AccessLevel = 'Read',
            RowCause = Schema.Case__Share.RowCause.Manual
        );
        insert caseShr;
    }

    @isTest
    public static void testAddShareRecordFail_BadCase() {
        Test.startTest();
        try {
            CaseListController.addShareRecord(null, UserInfo.getUserId());
            System.assert(false, 'Should not hit this');
        } catch (Exception ex) {
            System.assertEquals('System.AuraHandledException', ex.getTypeName());
        }
        Test.stopTest();
    }

    @isTest
    public static void testAddShareRecordFail_BadEntityString() {
        Test.startTest();
        try {
            CaseListController.addShareRecord(getTestCase().Id, 'NotAnId');
            System.assert(false, 'Should not hit this');
        } catch (Exception ex) {
            System.assertEquals('System.AuraHandledException', ex.getTypeName());
        }
        Test.stopTest();
    }

    @isTest
    public static void testAddShareRecordFail_BadEntity() {
        Test.startTest();
        try {
            CaseListController.addShareRecord(getTestCase().Id, getTestCase().Id);
            System.assert(false, 'Should not hit this');
        } catch (Exception ex) {
            System.assertEquals('System.AuraHandledException', ex.getTypeName());
        }
        Test.stopTest();
    }

    @isTest
    public static void testAddShareRecordForGroup() {
        User groupUser1 = getTestUser(TEST_USERNAME_3);
        User groupUser2 = getTestUser(TEST_USERNAME_4);
        User hierarchy1 = getTestUser(TEST_USERNAME_1);
        User hierarchy2 = getTestUser(TEST_USERNAME_2);
        Id testGroupId = createTestGroup(groupUser1.Id, groupUser2.Id);
        Case__c testCase = getTestCase();
        Integer shareCount = getShareRecords(testCase.Id).size();

        validateBlocked(groupUser1);
        validateBlocked(groupuser2);
        validateBlocked(hierarchy2);
        validateShared(hierarchy1);

        Test.startTest();
        CaseListController.addShareRecord(testCase.Id, testGroupId);
        Test.stopTest();

        System.assertEquals(shareCount + 1, getShareRecords(testCase.Id).size());

        validateShared(groupUser1);
        validateShared(groupUser2);
        validateShared(hierarchy2);
        validateShared(hierarchy1);
    }

    @isTest
    public static void testAddShareRecordForUser() {
        Case__c testCase = getTestCase();
        Integer shareCount = getShareRecords(testCase.Id).size();

        User u = getTestUser(TEST_USERNAME_2);
        validateBlocked(u);

        Test.startTest();
        CaseListController.addShareRecord(testCase.Id, u.Id);
        Test.stopTest();

        System.assertEquals(shareCount + 1, getShareRecords(testCase.Id).size());
        validateShared(u);
        validateShared(getTestUser(TEST_USERNAME_1));
    }

    @isTest
    public static void testAddUsersFromGroups() {
        User group1User1 = getTestUser(TEST_USERNAME_1);
        User group1User2 = getTestUser(TEST_USERNAME_2);
        User u = getTestUser(TEST_USERNAME_3);

        Id testGroup1Id = createTestGroup(group1User1.Id, group1User2.Id);
        Id testGroup2Id = createTestGroup(u.Id, testGroup1Id);

        Test.startTest();
        Set<Id> userIds = CaseListController.addUsersFromGroups(new Set<Id> { testGroup2Id }, new Set<Id>());
        System.assertEquals(3, userIds.size());
        Test.stopTest();
    }

    @isTest
    public static void testDropShareRecordForGroup() {
        User groupUser1 = getTestUser(TEST_USERNAME_3);
        User groupUser2 = getTestUser(TEST_USERNAME_4);
        User hierarchy1 = getTestUser(TEST_USERNAME_1);
        User hierarchy2 = getTestUser(TEST_USERNAME_2);
        Id testGroupId = createTestGroup(groupUser1.Id, groupUser2.Id);
        Case__c testCase = getTestCase();

        CaseListController.addShareRecord(testCase.Id, testGroupId);
        Integer shareCount = getShareRecords(testCase.Id).size();

        Test.startTest();
        CaseListController.dropShareRecord(testCase.Id, testGroupId);
        Test.stopTest();

        System.assertEquals(shareCount - 1, getShareRecords(testCase.Id).size());
        validateBlocked(groupUser1);
        validateBlocked(groupUser2);
        validateBlocked(hierarchy2);
        validateShared(hierarchy1);
    }

    @isTest
    public static void testDropShareRecordForUser() {
        Case__c testCase = getTestCase();
        Integer shareCount = getShareRecords(testCase.Id).size();

        User u = getTestUser(TEST_USERNAME_1);
        validateShared(u);

        Test.startTest();
        CaseListController.dropShareRecord(testCase.Id, u.Id);
        Test.stopTest();

        System.assertEquals(shareCount - 1, getShareRecords(testCase.Id).size());
        validateBLocked(u);
    }

    @isTest
    public static void testGetCases() {
        User u = getTestUser(TEST_USERNAME_1);
        Test.startTest();
        System.runAs(u) {
            List<Case__c> cases = CaseListController.getCases();
            System.assertEquals(1, cases.size());
        }
        Test.stopTest();
    }

    @isTest
    public static void testGetCaseEntities() {
        Case__c testCase = getTestCase();
        List<User> entities;

        Test.startTest();
        entities = CaseListController.getCaseEntities(testCase.Id);
        Test.stopTest();

        System.assertEquals(2, entities.size());

        Set<Id> entityIds = new Set<Id>();
        for (User entity : entities) {
            entityIds.add(entity.Id);
        }

        User u = getTestUser(TEST_USERNAME_1);

        System.assert(entityIds.contains(UserInfo.getUserId()));
        System.assert(entityIds.contains(u.Id));

        validateShared(new User(Id = UserInfo.getUserId()));
        validateShared(u);
    }

    @isTest
    public static void testGetCaseEntitiesWithGroup() {
        Case__c testCase = getTestCase();
        Integer preShareCount = CaseListController.getCaseEntities(testCase.Id).size();

        User groupUser1 = getTestUser(TEST_USERNAME_3);
        User groupUser2 = getTestUser(TEST_USERNAME_4);
        User hierarchy1 = getTestUser(TEST_USERNAME_1);
        User hierarchy2 = getTestUser(TEST_USERNAME_2);
        Id testGroupId = createTestGroup(groupUser1.Id, groupUser2.Id);

        Test.startTest();
        CaseListController.addShareRecord(testCase.Id, testGroupId);
        Integer postShareCount = CaseListController.getCaseEntities(testCase.Id).size();
        System.assertEquals(preShareCount + 2, postShareCount);
        Test.stopTest();

        validateShared(groupUser1);
        validateShared(groupUser2);
        validateShared(hierarchy2);
        validateShared(hierarchy1);
    }

    @isTest
    public static void testGetCaseOwner() {
        Test.startTest();
        Id caseOwner = CaseListController.getCaseOwner(getTestCase().Id);
        System.assertEquals(UserInfo.getUserId(), caseOwner);
        Test.stopTest();
    }

    private static Id createTestGroup(Id groupUserId1, Id groupUserId2) {
        Id testGroupId;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Group g = new Group(
                Name = TEST_GROUP
            );
            Database.SaveResult sr = Database.insert(g);
            testGroupId = sr.getId();

            GroupMember gm1 = new GroupMember (
                GroupId = testGroupId,
                UserOrGroupId = groupUserId1
            );
            insert gm1;

            GroupMember gm2 = new GroupMember (
                GroupId = testGroupId,
                UserOrGroupId = groupUserId2
            );
            insert gm2;
        }

        return testGroupId;
    }

    private static Id createTestUser(String username, String roleName) {
        User standardUser = new User(
			Alias = 'testuser',
			Email = username,
			EmailEncodingKey = 'UTF-8',
			FirstName = 'Test',
			LastName = 'User',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
			TimeZoneSidKey = 'America/New_York',
			UserName = username,
            UserRoleId = [SELECT Id FROM UserRole WHERE Name = :roleName].Id
		);
		Database.SaveResult sr = Database.insert(standardUser);

        if (!sr.isSuccess()) {
            System.assert(false, sr.getErrors()[0].getMessage());
        }

        return sr.getId();
    }

    private static List<Case__share> getShareRecords(Id caseId) {
        return [
            SELECT
                Id
            FROM
                Case__share
            WHERE
                ParentId = :caseId
        ];
    }

    private static Case__c getTestCase() {
        List<Case__c> cases = [
            SELECT
                Id
            FROM
                Case__c
            ORDER BY
                CreatedDate
            DESC
            LIMIT 1
        ];

        if (!cases.isEmpty()) {
            return cases[0];
        }
        
        return null;
    }

    private static Group getTestGroup() {
        return [
            SELECT 
                Id
            FROM
                Group
            WHERE
                Name = :TEST_GROUP
        ];
    }

    private static User getTestUser(String username) {
        return [
            SELECT
                Id
            FROM
                User
            WHERE
                Email = :username
            AND
                UserName = :username
        ][0];
    }

    private static void validateBlocked(User u) {
        System.runAs(u) {
            System.assertEquals(null, getTestCase());
        }
    }

    private static void validateShared(User u) {
        System.runAs(u) {
            System.assertNotEquals(null, getTestCase());
        }
    }
}