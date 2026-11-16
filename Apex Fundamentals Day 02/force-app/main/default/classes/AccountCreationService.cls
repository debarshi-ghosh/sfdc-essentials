public with sharing class AccountCreationService {
    public static List<Account> createAccounts(List<String> names) {
        List<Account> accountsToInsert = new List<Account>();

        if (names == null || names.isEmpty()) {
            return accountsToInsert;
        }

        for (String name : names) {
            if (String.isBlank(name)) {
                continue;
            }
            accountsToInsert.add(new Account(Name = name.trim()));
        }

        if (!accountsToInsert.isEmpty()) {
            insert accountsToInsert;
        }
        return accountsToInsert;
    }
}
