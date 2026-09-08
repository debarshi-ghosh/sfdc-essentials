/**
 * @description Test only handler used by TriggerFactoryHandlerTest to exercise the dynamic
 * instantiation and dispatch performed by TriggerHandlerExecution. It has to live in its own
 * top level class so Type.forName can resolve it from the framework.
 */
@IsTest
public with sharing class TriggerFactoryHandlerMock extends TriggerFactoryHandler {
    public static TriggerOperation lastOperation;
    public static Integer instantiations = 0;
    public static String lastName;

    /**
     * When true the handler re-enters the framework for Account, which exercises the recursion
     * depth guard in TriggerHandlerExecution.
     */
    public static Boolean recurseOnBeforeInsert = false;

    /**
     * @description Resets the recorded state between assertions.
     */
    public static void reset() {
        lastOperation = null;
        instantiations = 0;
        lastName = null;
        recurseOnBeforeInsert = false;
    }

    /**
     * @description Default constructor required by Type.newInstance.
     */
    public TriggerFactoryHandlerMock() {
        instantiations++;
    }

    protected override void onBeforeInsert(TriggerContext context) {
        record(TriggerOperation.BEFORE_INSERT);
        if (recurseOnBeforeInsert) {
            TriggerHandlerExecution.getInstance().getHandler(Account.class).execute(TriggerOperation.BEFORE_INSERT);
        }
    }

    protected override void onBeforeUpdate(TriggerContext context) {
        record(TriggerOperation.BEFORE_UPDATE);
    }

    protected override void onBeforeDelete(TriggerContext context) {
        record(TriggerOperation.BEFORE_DELETE);
    }

    protected override void onAfterInsert(TriggerContext context) {
        record(TriggerOperation.AFTER_INSERT);
    }

    protected override void onAfterUpdate(TriggerContext context) {
        record(TriggerOperation.AFTER_UPDATE);
    }

    protected override void onAfterDelete(TriggerContext context) {
        record(TriggerOperation.AFTER_DELETE);
    }

    protected override void onAfterUnDelete(TriggerContext context) {
        record(TriggerOperation.AFTER_UNDELETE);
    }

    private void record(TriggerOperation operation) {
        lastOperation = operation;
        lastName = this.getName();
    }
}
