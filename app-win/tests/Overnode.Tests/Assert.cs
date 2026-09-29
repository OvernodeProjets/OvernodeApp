using System;

namespace Overnode.Tests;

public static class Assert
{
    public static void IsTrue(bool condition, string? message = null)
    {
        if (!condition) throw new Exception(message ?? "Assertion failed: expected true, got false.");
    }

    public static void IsFalse(bool condition, string? message = null)
    {
        if (condition) throw new Exception(message ?? "Assertion failed: expected false, got true.");
    }

    public static void IsNotNull(object? obj, string? message = null)
    {
        if (obj == null) throw new Exception(message ?? "Assertion failed: object is null.");
    }

    public static void IsNull(object? obj, string? message = null)
    {
        if (obj != null) throw new Exception(message ?? "Assertion failed: object is not null.");
    }

    public static void AreEqual<T>(T expected, T actual, string? message = null)
    {
        if (!EqualityComparer<T>.Default.Equals(expected, actual))
        {
            throw new Exception(message ?? $"Assertion failed: expected '{expected}', got '{actual}'.");
        }
    }
}
