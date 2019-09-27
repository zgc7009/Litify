@IsTest
public class GroupEntityTest {
    private static final String TEST_USERNAME_1 = '123@abc-test.com';
    private static final String TEST_USERNAME_2 = 'abc@123-test.com';
    private static final String TEST_USERNAME_3 = 'xyz@098-test.com';

    @isTest
    public static void testInitialization() {
        Id u1 = CaseListControllerTest.createTestUser(TEST_USERNAME_1, 'Individual');
        Id u2 = CaseListControllerTest.createTestUser(TEST_USERNAME_2, 'Employee');
        Id testGroupId = CaseListControllerTest.createTestGroup(u1, u2);
        String testName = 'Some Test Group';

        GroupEntity entity;
        Test.startTest();
        entity = new GroupEntity(new Group(
            Id = testGroupId,
            Name = testName 
        ));
        Test.stopTest();

        System.assertEquals('2 users', entity.label);
        System.assertEquals(testName, entity.title);
        System.assertEquals(false, entity.isIndividual);
        System.assertEquals(2, entity.users.size());
        System.assertEquals(testGroupId, entity.sId);
    }

    @isTest
    public static void testAddUsersFromGroups() {
        Id group1User1 = CaseListControllerTest.createTestUser(TEST_USERNAME_1, 'Manager');
        Id group1User2 = CaseListControllerTest.createTestUser(TEST_USERNAME_2, 'Individual');
        Id uId = CaseListControllerTest.createTestUser(TEST_USERNAME_3, 'Employee');

        Id testGroup1Id = CaseListControllerTest.createTestGroup(group1User1, group1User2);
        Id testGroup2Id = CaseListControllerTest.createTestGroup(uId, testGroup1Id);

        Test.startTest();
        Set<Id> userIds = GroupEntity.buildUsersFromGroups(new Set<Id> { testGroup2Id }, new Set<Id>());
        System.assertEquals(3, userIds.size());
        Test.stopTest();
    }
}