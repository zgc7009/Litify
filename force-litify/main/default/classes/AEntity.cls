 public abstract class AEntity {
    @AuraEnabled public Id sId;
    @AuraEnabled public String label;
    @AuraEnabled public String title;
    @AuraEnabled public Boolean isIndividual;
    @AuraEnabled public List<User> users;

    public AEntity(SObject obj) {
        this.sId = obj.Id;
        this.users = getUsers(obj);
        this.label = getLabel(obj);
        this.title = getTitle(obj);
        this.isIndividual = isIndividual();
    }

    public abstract String getLabel(SObject obj);
    public abstract String getTitle(SObject obj);
    public abstract List<User> getUsers(SObject obj);
    public abstract Boolean isIndividual();
}