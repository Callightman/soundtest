public enum ConnectionLogic {
    public static func makeReport(from snapshot: RouteSnapshot) -> CapabilityReport {
        CapabilityProbe().evaluate(snapshot)
    }
}
