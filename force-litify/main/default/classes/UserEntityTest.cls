@IsTest
public class UserEntityTest {
    @isTest
    public static void testInitialization() {
        String testUsername = '123@abc-test.com';
        String testFirstName = 'Test';
        String testLastName = 'User';

        Id userId = CaseListControllerTest.createTestUser('123@abc-test.com', 'Individual');

        UserEntity entity;
        Test.startTest();
        entity = new UserEntity(new User(
            Id = userId,
            FirstName = testFirstName,
            LastName = testLastName,
            Email = testUsername
        ));
        Test.stopTest();

        System.assertEquals(testUsername, entity.label);
        System.assertEquals(testLastName + ', ' + testFirstName, entity.title);
        System.assertEquals(true, entity.isIndividual);
        System.assertEquals(1, entity.users.size());
        System.assertEquals(userId, entity.sId);
    }
}