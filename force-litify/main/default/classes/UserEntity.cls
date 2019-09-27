public class UserEntity extends AEntity {

    public UserEntity(SObject obj) {
        super(obj);
    }

    public virtual override String getLabel(SObject obj) {
        return cast(obj).email;
    }

    public virtual override String getTitle(SObject obj) {
        return cast(obj).lastName + ', ' + cast(obj).firstName;
    }

    public virtual override List<User> getUsers(SObject obj) {
        return new List<User> { cast(obj) };
    }

    public virtual override Boolean isIndividual() {
        return true;
    }

    private User cast(SObject u) {
        return (User) u;
    }
}