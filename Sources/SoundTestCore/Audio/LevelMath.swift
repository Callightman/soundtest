import Foundation

public enum LevelMath {
    /// Linear amplitude (0...1) for a given dBFS value.
    public static func amplitude(dbFS: Double) -> Double {
        pow(10.0, dbFS / 20.0)
    }

    /// LFE channel level convention used by the test tones: 10 dB below the reference.
    public static func lfeDBFS(referenceDBFS: Double) -> Double {
        referenceDBFS - 10.0
    }
}
